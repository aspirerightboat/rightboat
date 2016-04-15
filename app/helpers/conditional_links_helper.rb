module ConditionalLinksHelper
  def saved_search_manufacturers_link(saved_search)
    if saved_search.manufacturer.present?
      manufacturers = Manufacturer.where(name: saved_search.manufacturer.split(','))
      links = []

      manufacturers.each do |manufacturer|
        links << link_to(manufacturer.name, sale_manufacturer_url(manufacturer))
      end

      links.join(', ').html_safe
    end
  end

  def saved_search_models_link(saved_search)
    links = []

    manufacrturer_models = if saved_search.model.present?
                             Model.includes(:manufacturer).where(name: saved_search.model.split(',')).group_by(&:manufacturer)
                           elsif saved_search.models.present?
                             manufacrturer_models = Model.includes(:manufacturer).where(id: saved_search.models).group_by(&:manufacturer)
                           else
                             {}
                           end

      manufacrturer_models.each do |manufacturer, model|
        link_name = "#{manufacturer.name} #{model.map(&:name).join(', ')}"
        links << link_to(link_name, sale_manufacturer_url(manufacturer: manufacturer.slug, models: model.map(&:id).join('-')))
      end

    links.join(', ').html_safe
  end
end
