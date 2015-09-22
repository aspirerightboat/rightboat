class AddLeadEmailConfig < ActiveRecord::Migration
  def up
    r = RBConfig.find_or_initialize_by(key: 'lead_quality_check_email')
    r.value = 'boats@rightboat.com'
    r.description = 'When lead status changes to QualityCheck then email will be sent to this admin email'
    r.save
  end
end
