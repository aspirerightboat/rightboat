class FixImportThreadsCount < ActiveRecord::Migration
  def up
    Import.includes(:last_import_trail).each do |import|
      trail = import.last_import_trail
      next if !trail
      boats_count = trail.boats_count
      threads = ([boats_count / 100.0, 1.0].min * 9).ceil
      puts [boats_count, threads].inspect
      import.update(threads: threads)
    end
  end
end
