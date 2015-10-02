class AddLeadsApproveDelayConfig < ActiveRecord::Migration
  def up
    RBConfig.repair
  end
end
