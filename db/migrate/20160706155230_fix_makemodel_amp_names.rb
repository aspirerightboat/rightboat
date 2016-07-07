class FixMakemodelAmpNames < ActiveRecord::Migration
  def up
    Manufacturer.where('name LIKE ?', '%&%').each { |record| fix_amp(record) }
    Model.where('name LIKE ?', '%&%').each { |record| fix_amp(record) }
  end

  def fix_amp(record)
    name = record.name
    name = CGI.unescapeHTML(CGI.unescapeHTML(name)) # eg. Yacht &amp;amp; Motor
    record.update_column(:name, name) if record.name != name
  end
end
