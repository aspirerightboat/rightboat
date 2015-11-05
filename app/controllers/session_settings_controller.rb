class SessionSettingsController < ApplicationController
  def change
    # set_view_layout(params['layout_mode']) if params['layout_mode'].present?

    render json: {status: 'success'}
  end
end