class SessionSettingsController < ApplicationController
  def change
    if !params['sort-field'].blank?
      set_order_field(params['order-field'])
    end
    if !params['view-mode'].blank?
      set_view_layout(params['view-mode'])
    end
    if !params['currency'].blank?
      set_currency(params['currency'])
    end
    if !params['length_unit'].blank?
      set_length_unit(params['length_unit'])
    end

    render json: {status: 'success'}
  end
end