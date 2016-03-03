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

  # scheduling options
  validates_presence_of :frequency_quantity, :frequency_unit, :tz, if: :active?
  validates_inclusion_of :frequency_unit, within: FREQUENCY_UNITS, if: :active?
  validates_numericality_of :frequency_quantity, greater_than: 0, if: :active?
  validate :validate_clockwork_params
  validate :validate_import_params

  before_destroy :stop!

  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }

  def self.importer_class_by_type(type)
    Rightboat::Imports::Importers.const_get(type.camelcase)
  end

  def importer_class
    self.class.importer_class_by_type(import_type)
  end

  def loading_or_running?
    loading? || process_running?
  end

  def loading?
    pid == -1 && queued_at
  end

  def process_running?
    pid && pid > 0 && (Process.getpgid(pid) rescue nil).present?
  end

  def try_run_import_rake!(manual)
    if !loading_or_running?
      update_attributes!(queued_at: Time.current, pid: -1)
      system "bundle exec rake import:run[#{id},#{manual ? 'manual' : 'auto'}] > /dev/null 2>&1 &"
    end
  end

  def try_run_import!(manual = false)
    if active? && !process_running?
      importer_class.new(self).run(manual)
    end
  end

  def stop!(force = false)
    Process.kill(force ? 'SIGKILL' : 'SIGINT', pid)
  rescue Errno::EPERM, Errno::ESRCH => e # no such pid running
    logger.error "#{e.class.name}: #{e.message}"
  ensure
    update_column(:pid, 0) if force
  end

  def kill!
    stop!(true)
  end

  def stop_or_kill!
    timeout = Time.current + 30.seconds

    while process_running? && Time.current < timeout
      stop!
      sleep(0.2.seconds)
    end

    kill! if process_running?
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
    symbolized_param = param.symbolize_keys
    importer_class.params_validators.each do |key, validators|
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
