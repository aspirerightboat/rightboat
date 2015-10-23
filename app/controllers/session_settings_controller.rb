class SessionSettingsController < ApplicationController
  def change
    set_order_field(params['order-field']) if params['sort-field'].present?
    set_view_layout(params['view-mode']) if params['view-mode'].present?
    set_currency(params['currency']) if params['currency'].present?
    set_length_unit(params['length_unit']) if params['length_unit'].present?

    render json: {status: 'success'}
  end
end