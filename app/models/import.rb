class Import < ActiveRecord::Base

  FREQUENCY_UNITS = [:hour, :day, :week, :month] # :second, :minute

  has_many :boats, inverse_of: :import, dependent: :nullify
  belongs_to :user, inverse_of: :imports

  serialize :param, Hash

  validates_presence_of :user_id, :import_type
  validates_numericality_of :threads, greater_than: 0, less_than: 10, allow_blank: true
  validates_inclusion_of :import_type, in: Rightboat::Imports::Base.source_types, allow_blank: true
  validates_uniqueness_of :import_type, scope: :user_id

  # scheduling options
  validates_presence_of :frequency_quantity, :frequency_unit, if: :active
  validates_inclusion_of :frequency_unit, within: FREQUENCY_UNITS.map(&:to_s), allow_blank: true, if: :active
  validates_presence_of :tz, if: lambda {|r| r.active? && !r.at.blank? }
  validates_inclusion_of :tz, within: TZInfo::Timezone.all_identifiers, allow_blank: true, if: :active
  validates_numericality_of :frequency_quantity, greater_than: 0, allow_blank: true, if: :active
  validate do
    # at value should be understandable by clockwork
    # valid examples:
    #   01:30, 1:30, **:30, 9:**, 12:00, 18:00, Monday 16:20
    if self.active? && !self.at.blank?
      begin
        Clockwork::At.parse(self.at)
      rescue Clockwork::At::FailedToParse
        self.errors.add :at, 'is invalid'
      end
    end
    validate_params
  end

  before_destroy :stop!

  scope :active, -> { where active: true }

  def self.source_class(type)
    return if type.blank?
    "Rightboat::Imports::Sources::#{type.camelcase}".constantize
  end

  def source_class
    self.class.source_class(import_type)
  end

  def running?(include_loading = true)
    return true if include_loading && (self.pid.to_i == -1 && queued_at && queued_at > 1.minutes.ago)
    return false if self.pid.to_i <= 0
    Process.kill(0, self.pid.to_i)
    true
  rescue
    false
  end

  def status
    if running?
      self.pid.to_i > 0 ? 'Running' : 'Loading'
    else
      active? && valid? ? 'Waiting' : 'Inactive'
    end
  end

  def run!
    self.update_column :queued_at, Time.now
    self.update_column :pid, -1
    system `RAILS_ENV=#{Rails.env} bundle exec rake import:run[#{id}] > /dev/null 2>&1 &`
  end

  def stop!(nonblock = true)
    if nonblock
      Process.kill(9, self.pid) if self.pid.to_i > 0
    else
      while running?
        Process.kill(9, self.pid) if self.pid.to_i > 0
      end
    end
  rescue
    retry unless nonblock
  end

  def frequency
    if self.class::FREQUENCY_UNITS.map(&:to_s).include?(self.frequency_unit.to_s)
      if self.frequency_quantity.to_i > 0
        eval "#{self.frequency_quantity}.#{self.frequency_unit}"
      else
        raise "Invalid frequency quantity."
      end
    else
      raise "Invalid frequency unit."
    end
  end

  private
  def validate_params
    return unless source_class
    symbolized_param = param.symbolize_keys
    source_class.validate_param_option.each do |key, validators|
      validators = [validators] unless validators.is_a?(Array)
      validators.each do |validator|
        value = symbolized_param[key.to_sym]
        if validator.to_s == 'presence'
          if value.blank?
            errors.add :param, "[#{key}] can't be blank"
          end
        elsif validator.is_a?(Regexp)
          unless value.blank? || value.to_s =~ validator
            errors.add :param, "[#{key}] is invalid"
          end
        elsif validator.to_s == 'optional'
          # this is optional param for later use case
        else
          raise "Invalid validate option"
        end
      end
    end
  end

end
