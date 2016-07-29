class CreateIframeClicks < ActiveRecord::Migration
  def change
    create_table :iframe_clicks do |t|
      t.references :broker_iframe, index: true
      t.string :ip
      t.string :url

      t.timestamps
    end
  end
end
