class ApplicationMailer < ActionMailer::Base
  default from: "do-not-reply@rightboat.com", bcc:"notifications@rightboat.com"
  layout 'mailer'
end
