ActiveAdmin.register_page 'Makers Models' do
  menu parent: 'Boats', priority: 100, label: 'Makers/Models Fixing'

  content title: 'Manufacturers & Models Fixing' do
    render partial: 'makers_models_table'
  end

  sidebar :filters, partial: 'filters'

  controller do
    def index
      per_page = (params[:per_page] || 30).to_i
      offset = ((params[:page] || 1).to_i - 1) * per_page

      makers_rel = Manufacturer.search(params[:q]).result
      @paginator_array = Kaminari.paginate_array([], total_count: makers_rel.count).page(params[:page]).per(per_page)
      @makers_counts = makers_rel
                           .joins(:boats).group('manufacturers.id')
                           .order('COUNT(*) DESC').offset(offset).limit(per_page)
                           .pluck('manufacturers.id, COUNT(*)')


      maker_ids = @makers_counts.map(&:first)
      makers = Manufacturer.where(id: maker_ids).includes(:models).references(:models).order('manufacturers.id, models.name')
                   .select('manufacturers.id, manufacturers.name, models.id, models.name')

      @makers_counts.map! do |maker_id, models_count|
        maker = makers.find { |m| m.id == maker_id }
        [maker, models_count]
      end
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
