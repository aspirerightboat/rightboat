class FixMakeModelNames < ActiveRecord::Migration
  def up
    # Convert
    # Maker: Beneteau Swift Trawler 44
    # Models: Swift Trawler 44, Unknown
    # To
    # Maker: Beneteau
    # Models: Swift Trawler 44
    Manufacturer.includes(:models).each do |maker|
      maker.models.each do |model|
        next if model.name == 'Unknown'
        model_name_regexp = /#{Regexp.escape(model.name)}/i

        if maker.name =~ model_name_regexp
          new_maker_name = maker.name.sub(model_name_regexp, '').strip

          if new_maker_name.present?
            fix_model_names(maker.models, model.name)
            maker.models.reset
            fix_maker_name(maker, new_maker_name)
          end

          break
        end
      end
    end

    # Convert
    # Maker: Beneteau Clipper 393
    # Models: Unknown
    # To
    # Maker: Beneteau
    # Models: Clipper 393
    Manufacturer.includes(:models).each do |maker|
      if maker.name =~ /\d/
        maker_name, model_name, _success = split_make_model(maker.name, maker.id)

        if maker.name != maker_name
          fix_model_names(maker.models, model_name)
          maker.models.reset
          fix_maker_name(maker, maker_name)
        end
      end
    end

  end

  def fix_model_names(models, source_model_name)
    models.each do |model|
      next if model.name == source_model_name

      new_model_name = model.name == 'Unknown' ? source_model_name : "#{model.name} #{source_model_name}"

      if (other_model = models.find { |m| m.name == new_model_name })
        model.merge_and_destroy!(other_model)
      else
        model.update!(name: new_model_name)
      end
    end
  end

  def fix_maker_name(maker, new_maker_name)
    if (other_maker = Manufacturer.where(name: new_maker_name).first)
      maker.merge_and_destroy!(other_maker)
      # maker.models(true).each do |model|
      #   model.move_to_manufacturer(other_maker)
      #   # if (other_model = other_maker.models.where(name: model.name).first)
      #   #   model.merge_and_destroy!(other_model, other_maker)
      #   # else
      #   #   res = model.update(manufacturer: other_maker)
      #   #   if !res
      #   #     puts [maker.name, other_maker.name, model.name].inspect
      #   #     raise StandardError.new("qwqwe")
      #   #   end
      #   #   model.boats.each { |b| b.update!(manufacturer: other_maker) }
      #   # end
      # end
      #
      # maker.misspellings.update_all(source_id: other_maker.id)
      # maker.buyer_guides.update_all(manufacturer_id: other_maker.id)
      # maker.finances.update_all(manufacturer_id: other_maker.id)
      # maker.insurances.update_all(manufacturer_id: other_maker.id)
      # maker.reload
      # maker.destroy!
    else
      maker.update!(name: new_maker_name)
    end
  end

  def split_make_model(mnm, except_maker_id)
    search = Boat.solr_search do
      with :manufacturer_model, mnm
      without :manufacturer_id, except_maker_id if except_maker_id
      order_by :live, :desc
      paginate per_page: 1
    end

    if (boat = search.results.first)
      maker = boat.manufacturer.name
      model = boat.model.name
      return [maker, model, true]
    end

    tokens = mnm.scan(/\S+/)

    (tokens.size - 1).downto(1).each do |i|
      maker = tokens[0...i].join(' ')

      if (maker_found = Manufacturer.query_with_aliases(maker).first)
        maker = maker_found.name
        model = tokens[i..-1].join(' ')
        return [maker, model, true]
      end
    end

    maker = tokens.first
    model = tokens[1..-1].join(' ')
    [maker, model, false]
  end

end
