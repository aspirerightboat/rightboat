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
        {key: 'lead_price_coef', value: '0.0002', kind: :float, description: 'If boat has price is £100.000 then invoice price will be eg. 100_000 * 0.0002 = £20'},
        {key: 'lead_flat_fee', value: '99', kind: :float, description: 'If no boat price nor length present then invoice price will be flat fee in £'},
        {key: 'min_lead_price', value: '2', kind: :float, description: 'Min lead price in £'},
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
