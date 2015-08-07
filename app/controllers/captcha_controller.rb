class CaptchaController < ApplicationController
  def new
    captcha = Rightboat::Captcha.new
    render json: { key: captcha.encrypt }, status: 200
  end

  def image
    captcha = Rightboat::Captcha.decrypt(params[:key])
    send_data captcha.image, disposition: :inline, type: 'image/png'
  end
end