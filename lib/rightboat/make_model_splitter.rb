module Rightboat
  class MakeModelSplitter
    # some sources has only merged string instead of separate manufacturer/model
    # in this case, search solr and find first
    # if not exists in solr, use split method
    # e.g. yachtworld: Marine Projects Sigma 38, Alloy Yachts Pilothouse
    def self.split(mnm)
      search = Boat.retryable_solr_search! do
        with :manufacturer_model, mnm.downcase
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
end
