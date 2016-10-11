class Import < ApplicationRecord
  include BoatOwner

  FREQUENCY_UNITS = %w(day monday)

  belongs_to :user, inverse_of: :imports
  has_many :import_trails
  belongs_to :last_import_trail, class_name: 'ImportTrail'
  has_one :last_finished_trail, -> { where.not(finished_at: nil).order('id DESC') }, class_name: 'ImportTrail'

  serialize :param, Hash

  validates :user_id, presence: true
  validates :threads, presence: true, numericality: {only_integer: true, greater_than: 0, less_than: 11}
  validates :import_type, presence: true, inclusion: {in: Rightboat::Imports::ImporterBase.import_types}
  validates :frequency_unit, presence: true, inclusion: {in: FREQUENCY_UNITS}
  validates :at, presence: true, format: {with: /\A\d\d:\d\d\z/}
  validates :tz, presence: true

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
    Process.kill(force ? 'SIGKILL' : 'SIGINT', pid) if pid && pid > 0
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

  def at_utc
    Time.parse("#{at} #{tz}").utc
  end

  def approx_duration
    if last_import_trail&.finished_at
      dur = last_import_trail.finished_at - last_import_trail.created_at + 1.second
      (dur / 1.minute).ceil.minutes
    else
      1.minute
    end
  end

  def approx_end_time
    at_utc + approx_duration
  end

  private

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
