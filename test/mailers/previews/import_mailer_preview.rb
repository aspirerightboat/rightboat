class ImportMailerPreview < ActionMailer::Preview

  def importing_errors
    ImportMailer.importing_errors(ImportTrail.last)
  end
end
