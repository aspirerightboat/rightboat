class TestingController < ApplicationController
  def test_email
    # LeadsMailer.invoice_notify_broker(3).deliver_now
    TestingMailer.test_email.deliver_now
    render text: 'Test email was sent'
  end

  def test_user_create
    # u = User.new
    # u.assign_attributes(username: 'username', first_name: 'first_name', last_name: 'last_name',
    #                     email: 'email@gmail.com', password: '12345678', password_confirmation: '12345678')
    # u.save
  end
end