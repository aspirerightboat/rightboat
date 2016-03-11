class TestingController < ApplicationController
  def test_email
    TestingMailer.test_email.deliver_now
    render text: "Test email was sent to #{TestingMailer.default_params[:to].first}"
  end

  def test_error
    raise StandardError.new('Error for testing purposes')
  end
end