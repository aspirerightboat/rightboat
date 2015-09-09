class ImportMailer < ApplicationMailer

  default to: %w(xmpolaris@gmail.com)

  def process_error(error, import, job)
    @error = error
    @import = import
    @job = job
    mail(subject: "Import Processing Error")
  end

  def import_blank(import)
    @import = import
    mail(subject: "Import Blank Error")
  end

  def process_result_error(error, import)
    @error = error
    @import = import
    mail(subject: "Import Result Processing Error")
  end

  def invalid_boat(source_boat)
    @source_boat = source_boat
    @import = @source_boat.import
    mail(subject: "Invalid Boat Error")
  end

  def blank_currency(source_boat)
    @source_boat = source_boat
    @import = @source_boat.import
    mail(subject: "Blank Currency Error")
  end

  def new_unit(unit)
    @unit = unit
    mail(subject: "New Unit")
  end
end
