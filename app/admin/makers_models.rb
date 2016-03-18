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
      res = resource.update(name: new_name)

      if !res
        if (same_name_resource = resource.where(name: new_name).where.not(id: resource.id).first)
          resource.merge_and_destroy!(same_name_resource)
          render json: 'Merged with other', replaced_with_other: true
          return
        else
          resource.update!(name: new_name)
        end
      end

      render json: {success: 'Updated'}
      return
    end

    if params[:create_misspellings] && resource.name != 'Unknown'
      resource.misspellings.find_or_create_by!(alias_string: resource.name)
    end

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

  page_action :split_name, method: :post, format: :json do
    maker = Manufacturer.find(params[:id])
    new_maker_name = params[:part1]
    prepend_model_names = params[:part2]

    if new_maker_name.present? && new_maker_name != maker.name
      maker.models.each { |m| m.prepend_name!(prepend_model_names) }

      model_names = maker.models(true).pluck(:id, :name).to_h

      if (other_manufacturer = Manufacturer.where(name: new_maker_name).first)
        maker.merge_and_destroy!(other_manufacturer)
        render json: {success: 'Merged with other', replaced_with_other: true, model_names: model_names}
      else
        maker.update!(name: new_maker_name)
        render json: {success: 'Updated', model_names: model_names}
      end
    else
      head :bad_request
    end
  end

end
