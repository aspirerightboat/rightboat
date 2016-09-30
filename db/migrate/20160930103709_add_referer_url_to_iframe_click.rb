class AddRefererUrlToIframeClick < ActiveRecord::Migration
  def change
    add_column :iframe_clicks, :referer_url, :string
  end
end
