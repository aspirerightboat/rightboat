class RegistrationsController < Devise::RegistrationsController
  clear_respond_to
  respond_to :json
  before_filter :ensure_role, only: [:create]

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  private

  def ensure_role
    params[:user][:role] = 'PRIVATE' if params[:user][:role].present? && params[:user][:role] != 'BROKER'
  end
end