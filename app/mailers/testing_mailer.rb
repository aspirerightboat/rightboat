class TestingMailer < ApplicationMailer
  default to: %w(boats@rightboat.com) #%w(boats@rightboat.com)

  def test_email
    mail(subject: 'Test Email — Rightboat')
  end
end
