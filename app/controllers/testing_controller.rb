class TestingController < ApplicationController
  def test_email
    TestingMailer.test_email.deliver_now
    render text: 'Test email was sent'
  end
end