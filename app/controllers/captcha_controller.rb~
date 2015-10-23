class CaptchaController < ApplicationController
  def new
    session[:captcha] = Rightboat::Captcha.generate
    head :ok
  end

  def image
    return head(:not_found) if !session[:captcha]
    send_data Rightboat::Captcha.image(session[:captcha].with_indifferent_access), disposition: :inline, type: 'image/png'
  end
end