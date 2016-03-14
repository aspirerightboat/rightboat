ActiveAdmin.register_page 'Makers Models' do
  menu parent: 'Boats', priority: 100, label: 'Makers/Models Fixing'

  content title: 'Manufacturers & Models Fixing' do
    render partial: 'makers_models_table'
  end

  sidebar :filters, partial: 'filters'

  controller do
    def index
      @page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 30).to_i
      offset = (@page - 1) * per_page

      @maker_infos = Manufacturer.search(params[:q]).result
                         .joins(:boats).where(boats: {deleted_at: nil})
                         .where(({boats: {user_id: params[:broker_id]}} if params[:broker_id].present?))
                         .group('manufacturers.id, manufacturers.name')
                         .order('COUNT(*) DESC').offset(offset).limit(per_page)
                         .pluck('manufacturers.id, manufacturers.name, COUNT(*)')


      maker_ids = @maker_infos.map(&:first)
      models = Model.where(manufacturer_id: maker_ids)
                   .joins(:boats).where(boats: {deleted_at: nil})
                   .where(({boats: {user_id: params[:broker_id]}} if params[:broker_id].present?))
                   .group('models.id, models.name, models.manufacturer_id')
                   .order('models.manufacturer_id, COUNT(*) DESC')
                   .pluck('models.id, models.name, models.manufacturer_id, COUNT(*)')

      @model_infos_by_maker = models.group_by(&:third)

      @brokers_select_options = User.companies.pluck('CONCAT(company_name, " (", boats_count, ")"), id')
    end
  end

  page_action :fix_name, method: :post, format: :json do
    resource_class = params[:class] == 'Model' ? Model : Manufacturer
    resource = resource_class.find(params[:id])
    new_name = params[:name]

    if resource.name.downcase == new_name.downcase
      resource.update!(name: new_name)
      render json: {success: 'Updated'}
      return
    end

    resource.misspellings.find_or_create_by!(alias_string: resource.name)

    other_res = if resource.is_a?(Model)
                  Model.find_by(name: new_name, manufacturer_id: resource.manufacturer_id)
                else
                  resource.class.find_by(name: new_name)
                end

    if other_res
      resource.merge_and_destroy!(other_res)
      render json: {success: 'Merged with other', replaced_with_other: true}
    else
      resource.update!(name: new_name)
      render json: {success: 'Misspelling created'}
    end
  end

end
