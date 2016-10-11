class Export < ApplicationRecord
  belongs_to :user

  EXPORT_TYPES = %w(openmarine)

  validates_presence_of :user_id
  validates_inclusion_of :export_type, in: -> (_export) { export_types }, if: :export_type_changed?

  scope :active, -> { where active: true }
  scope :inactive, -> { where active: false }

  before_create :create_prefix

  def self.export_types
    @export_types ||= Dir['lib/rightboat/exports/*_exporter.rb'].map { |path| File.basename(path, '.*').chomp('_exporter') }
  end

  def run!
    exporter_class.new(self).run
  end

  def self.run_all!
    active.includes(:user).each do |export|
      export.run!
    end
  end

  def log_dir
    "log/exports/#{export_type}-#{id}"
  end

  def log_path
    "#{log_dir}/#{started_at.strftime('%Y-%m-%d--%H-%M-%S')}.log"
  end

  def feed_public_path
    user_slug = user.slug.dasherize
    type_slug = export_type.dasherize
    pref = ("-#{prefix}" if prefix.present?)
    "/exports/#{user_slug}-#{type_slug}#{pref}.xml"
  end

  def exporter_class
    Rightboat::Exports.const_get("#{export_type}_exporter".camelcase)
  end

  def duration
    if finished_at && started_at
      Time.at(finished_at - started_at).utc
    end
  end

  private

  def create_prefix
    self.prefix = Digest::SHA1::hexdigest("#{user_id}ribbs!").first(10)
  end

end
