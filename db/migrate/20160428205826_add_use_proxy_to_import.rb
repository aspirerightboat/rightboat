class AddUseProxyToImport < ActiveRecord::Migration
  def up
    add_column :imports, :use_proxy_for_images, :boolean
  end
end
