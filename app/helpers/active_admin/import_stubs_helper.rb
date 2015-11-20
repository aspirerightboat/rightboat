module ActiveAdmin::ImportStubsHelper
  def import_id_options(import_type)
    cond = ({import_type: import_type} if import_type.present?)
    Import.where(cond).order(:id).joins(:user).pluck('imports.id, users.company_name').map do |id, user_name|
      ["#{id} - #{user_name}", id]
    end
  end
end