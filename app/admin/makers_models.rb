ActiveAdmin.register_page 'Makers Models' do
  menu parent: 'Boats', priority: 100, label: 'Makers/Models Fixing'

  content title: 'Manufacturers & Models Fixing' do
    render partial: 'makers_models_table'
  end

  sidebar :filters, partial: 'filters'

  controller do
    def index
      @makers_models = fetch_makers_models
    end

    private

    def fetch_makers_models
      Boat.not_deleted.search(params[:q]).result
          .joins(:manufacturer, :model).group('manufacturers.id, manufacturers.name').order('COUNT(*) DESC')
          .pluck("manufacturers.id, manufacturers.name, COUNT(*),
                               GROUP_CONCAT(DISTINCT models.name SEPARATOR ' | '),
                               GROUP_CONCAT(DISTINCT models.id SEPARATOR ',')".squish)
          .map do |maker_id, maker_name, boats_count, model_names_str, model_ids_str|
        model_names = model_names_str.split(' | ')
        model_ids = model_ids_str.split(',')
        model_infos = model_ids.zip(model_names) #.sort_by(&:second)

        [maker_id, maker_name, boats_count, model_infos]
      end
    end
  end

end
