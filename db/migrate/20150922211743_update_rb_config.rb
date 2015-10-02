class UpdateRbConfig < ActiveRecord::Migration
  def up
    RBConfig.repair
  end
end
