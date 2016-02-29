class RBConfig < ActiveRecord::Base

  validates :key, uniqueness: true

  def self.cached_configs
    @cached_configs ||= begin
      RBConfig.pluck(:key, :value, :kind).map do |k, v, kind|
        v = case kind.to_sym
            when :integer then v.to_i
            when :float then v.to_f
            when :string then v.to_s
            end
        [k, v]
      end.to_h.symbolize_keys
    end
  end

  def self.[](key)
    cached_configs[key]
  end

  def self.defaults
    [
        {key: 'lead_quality_check_email', value: 'boats@rightboat.com', kind: :string, description: 'When lead status changes to QualityCheck then email will be sent to this admin email'},
        {key: 'leads_approve_delay', value: '72', kind: :integer, description: 'Lead delay before approved in hours'},
        {key: 'invoicing_report_email', value: 'boats@rightboat.com', kind: :string, description: 'Where to send report summary about generated invoices'},
        {key: 'lead_low_price_coef', value: '0.0002', kind: :float, description: 'Coefficient when price is <= £500.000. A £100.000 boat will be charged as 100.000 * 0.0002 = £20'},
        {key: 'lead_high_price_coef', value: '0.0001', kind: :float, description: 'Coefficient when price is > £500.000. A £600.000 boat will be charged as 500.000 * 0.0002 + 100.000 * 0.0001 = £110'},
        {key: 'lead_price_coef_bound', value: '500000', kind: :float, description: 'Under this price lead_low_price_coef is used and under – lead_high_price_coef'},
        {key: 'lead_flat_fee', value: '99', kind: :float, description: 'If no boat price nor length present then lead price will be flat fee in £'},
        {key: 'default_min_lead_price', value: '5', kind: :float, description: 'Default minimum lead price in £. Can be overridden by broker_info settings'},
        {key: 'default_max_lead_price', value: '300', kind: :float, description: 'Default maximum lead price in £. Can be overridden by broker_info settings'},
        {key: 'lead_gap_minutes', value: '3', kind: :float, description: 'Time between lead requests in minutes when second lead will be considered as suspicious'},
    ]
  end

  def self.repair
    @cached_configs = nil
    existing_keys = RBConfig.pluck(:key)
    default_configs = defaults

    # delete old configs
    config_keys_to_delete = existing_keys - default_configs.map { |h| h[:key] }
    RBConfig.where(key: config_keys_to_delete).delete_all if config_keys_to_delete.any?

    # create missing configs
    configs_to_create = default_configs.reject { |h| existing_keys.include?(h[:key]) }
    RBConfig.create(configs_to_create)
  end
end
