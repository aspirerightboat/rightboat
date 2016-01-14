class UpdateConfigMinLeadPrice < ActiveRecord::Migration
  def up
    RBConfig.repair
  end
end
