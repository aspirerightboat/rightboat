class Import < ActiveRecord::Base
  include BoatOwner

  FREQUENCY_UNITS = %w(hour day week month)

  belongs_to :user, inverse_of: :imports
  has_many :import_trails
  belongs_to :last_import_trail, class_name: 'ImportTrail'

  serialize :param, Hash

  validates_presence_of :user_id, :import_type
  validates_numericality_of :threads, greater_than: 0, less_than: 10, allow_blank: true
  validates_inclusion_of :import_type, in: -> (_) { Rightboat::Imports::ImporterBase.import_types }, allow_blank: true
  validates_uniqueness_of :import_type, scope: :user_id, if: 'import_type != "eyb"'

  # scheduling options
  validates_presence_of :frequency_quantity, :frequency_unit, :tz, if: :active?
  validates_inclusion_of :frequency_unit, within: FREQUENCY_UNITS, if: :active?
  validates_numericality_of :frequency_quantity, greater_than: 0, if: :active?
  validate :validate_clockwork_params
  validate :validate_import_params

  before_destroy :stop!

  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }

  def self.source_class(type)
    return if type.blank?
    Rightboat::Imports::Importers.const_get(type.camelcase)
  end

  def source_class
    self.class.source_class(import_type)
  end

  def running?
    loading? || process_running?
  end

  def loading?
    pid == -1 && queued_at
  end

  def process_running?
    pid && pid > 0 && (Process.getpgid(pid) rescue nil).present?
  end

  def run!
    return if running?
    update_attributes!(queued_at: Time.current, pid: -1)
    `bundle exec rake import:run[#{id}] > /dev/null 2>&1 &`
  end

  def stop!
    Process.kill('SIGINT', pid)
  rescue Errno::ESRCH => e # no such pid running
    logger.info e.message
  end

  NONBLOCK_STOP_TIMEOUT = 30.seconds
  def nonblock_stop!
    time = Time.current
    while process_running? && Time.current - time < NONBLOCK_STOP_TIMEOUT
      Process.kill('SIGINT', pid)
      sleep(0.2.seconds)
    end
    if Time.current - time >= NONBLOCK_STOP_TIMEOUT
      Process.kill('SIGKILL', pid)
    end
  rescue Errno::ESRCH => e
    logger.info e.message
  end

  def frequency
    if FREQUENCY_UNITS.include?(frequency_unit) && frequency_quantity > 0
      frequency_quantity.send(frequency_unit)
    end
  end

  private

  def validate_clockwork_params
    # at value should be understandable by clockwork
    # valid examples:
    #   01:30, 1:30, **:30, 9:**, 12:00, 18:00, Monday 16:20
    if active? && at.present?
      begin
        Clockwork::At.parse(at)
      rescue Clockwork::At::FailedToParse
        self.errors.add :at, 'is invalid'
      end
    end
  end

  def validate_import_params
    return unless source_class
    symbolized_param = param.symbolize_keys
    source_class.validate_param_option.each do |key, validators|
      validators = [validators] unless validators.is_a?(Array)
      validators.each do |validator|
        value = symbolized_param[key.to_sym]
        if validator == :presence
          if value.blank?
            errors.add :param, "[#{key}] can't be blank"
          end
        elsif validator.is_a?(Regexp)
          if value.blank? || value !~ validator
            errors.add :param, "[#{key}] is invalid"
          end
        else
          raise 'Invalid validate option'
        end
      end
    end
  end

end
