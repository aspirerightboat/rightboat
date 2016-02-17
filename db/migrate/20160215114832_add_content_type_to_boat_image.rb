class AddContentTypeToBoatImage < ActiveRecord::Migration
  def up
    add_column :boat_images, :content_type, :string
    add_column :boat_images, :caption, :string
    add_column :boat_images, :http_etag, :string
    add_column :boat_images, :downloaded_at, :datetime
    BoatImage.update_all('downloaded_at = updated_at')
    remove_column :boat_images, :source_ref

    BoatImage.where(file: nil).delete_all

    BoatImage.update_all <<-SQL.strip_heredoc
      content_type = CASE RIGHT(file, 3)
        WHEN 'jpg' THEN 'image/jpeg'
        WHEN 'jpeg' THEN 'image/jpeg'
        WHEN 'png' THEN 'image/png'
        WHEN 'gif' THEN 'image/gif'
        WHEN 'bmp' THEN 'image/bmp'
      END
    SQL
  end
end
