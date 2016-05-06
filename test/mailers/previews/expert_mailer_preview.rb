class ExpertMailerPreview < ActionMailer::Preview

  def importing_errors
    ExpertMailer.importing_errors(ImportTrail.last)
  end
end
