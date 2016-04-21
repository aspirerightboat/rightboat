Dir["#{Rails.root}/lib/ruby_ext/*.rb"].each {|file| require file }
Dir["#{Rails.root}/lib/rails_ext/*.rb"].each {|file| require file }

require 'rightboat/imports/importer_base' # fix "Circular dependency" error while running multithreaded import
