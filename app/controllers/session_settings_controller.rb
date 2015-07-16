class SessionSettingsController < ApplicationController
  def change
    if !params['sort-field'].blank?
      set_order_field(params['order-field'])
    elsif !params['view-mode'].blank?
      set_view_layout(params['view-mode'])
    end

    render json: {status: 'success'}
  end
end