class RBConfig < ActiveRecord::Base

  validates :key, uniqueness: true

  def self.store
    @@all_configs ||= RBConfig.pluck(:key, :value).each_with_object({}) { |(k, v), h| h[k] = v }
  end

  def self.get(key)
    where(key: key).pluck(:value).first
  end

  def self.repair
    configs = [
        {key: 'lead_quality_check_email', value: 'boats@rightboat.com', description: 'When lead status changes to QualityCheck then email will be sent to this admin email'},
        {key: 'leads_approve_delay', value: '72', description: 'Lead delay before approved in hours'},
        {key: 'invoicing_report_email', value: 'boats@rightboat.com', description: 'Where to send report summary about generated invoices'},
    ]

    available_keys = RBConfig.pluck(:key)

    # delete old configs
    config_keys_to_delete = available_keys - configs.map { |h| h[:key] }
    RBConfig.where(key: config_keys_to_delete).delete_all if config_keys_to_delete.any?

    # create missing configs
    configs_to_create = configs.reject { |h| available_keys.include?(h[:key]) }
    RBConfig.create(configs_to_create)
  end
end