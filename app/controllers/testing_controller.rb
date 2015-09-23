class TestingController < ApplicationController
  def test_email
    # LeadsMailer.invoice_notify_broker(3).deliver_now
    TestingMailer.test_email.deliver_now
    render text: 'Test email was sent'
  end
end