class TestingMailer < ApplicationMailer
  default to: ApplicationMailer::DEVELOPER_EMAILS

  after_action :gmail_delivery, only: [:test_gmail]
  after_action :amazon_delivery, only: [:test_amazon]

  def test_gmail
    mail(subject: 'Test Gmail Email — Rightboat')
  end

  def test_amazon
    mail(subject: 'Test Amazon Email - Rightboat')
  end

end
