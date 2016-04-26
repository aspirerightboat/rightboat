module MakemodelLinksHelper

  def manufacturer_links(manufacturers)
    links = manufacturers.map do |manufacturer|
      link_to(manufacturer.name, sale_manufacturer_url(manufacturer))
    end

    links.join(', ').html_safe
  end

  def model_links(models)
    links = models.group_by(&:manufacturer).map do |manufacturer, scoped_models|
      link_name = "#{manufacturer.name} #{scoped_models.map(&:name).join(', ')}"
      link_to(link_name, sale_manufacturer_url(manufacturer, models: scoped_models.map(&:id).join('-')))
    end

    links.join(', ').html_safe
  end

  def saved_search_manufacturer_links(saved_search)
    manufacturer_links(Manufacturer.where(id: saved_search.manufacturers))
  end

  def saved_search_model_links(saved_search)
    if saved_search.models.present?
      models = Model.includes(:manufacturer).where(id: saved_search.models)
      model_links(models)
    end
  end

  def maker_links_by_names(names, last_word_connector = nil)
    Manufacturer.where(name: names).pluck(:name, :slug).map do |name, slug|
      link_to(name, sale_manufacturer_path(slug))
    end.to_sentence(last_word_connector: last_word_connector || ' and ').html_safe
  end

end
