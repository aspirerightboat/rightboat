class UpdateRbConfig2 < ActiveRecord::Migration
  def change
    RBConfig.repair
  end
end
