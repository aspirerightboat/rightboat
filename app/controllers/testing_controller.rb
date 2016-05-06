class TestingController < ApplicationController

  def test_gmail
    TestingMailer.test_gmail.deliver_now
    render text: "Test email was sent to #{TestingMailer.default_params[:to].inspect}"
  end

  def test_amazon
    TestingMailer.test_amazon.deliver_now
    render text: "Test email was sent to #{TestingMailer.default_params[:to].inspect}"
  end

  def test_error
    raise StandardError.new('Error for testing purposes')
  end
end
