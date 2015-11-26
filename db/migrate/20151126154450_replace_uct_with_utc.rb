class ReplaceUctWithUtc < ActiveRecord::Migration
  def up
    Import.where(tz: 'UCT').update_all(tz: 'UTC')
  end
end
