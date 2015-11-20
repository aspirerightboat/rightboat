class TestingController < ApplicationController
  def test_email
    TestingMailer.test_email.deliver_now
    render text: "Test email was sent to #{TestingMailer.default_params[:to].first}"
  end
end