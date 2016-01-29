class ImportMailer < ApplicationMailer
  default to: %w(don.fuller@cotoco.com llukomskyy@n-ix.com xmpolaris@hotmail.com)

  def importing_errors(import_trail_id)
    @import_trail = ImportTrail.find(import_trail_id)
    @import = @import_trail.import
    mail(subject: "Errors while importing #{@import.import_type} ##{@import.id}")
  end

  def download_feed_error(feed_name)
    @feed_name = feed_name
    mail(subject: "Errors while downloading feed #{feed_name}")
  end
end
