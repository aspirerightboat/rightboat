module MisspellFixer
  def self.included(base)

    base.send :member_action, :fetch_name do
      render text: resource.name
    end

    base.send :member_action, :fix_name, method: :post, format: :json do
      new_name = params[:name]

      if resource.name.downcase == new_name.downcase
        resource.update!(name: new_name)
        render json: {}
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
        render json: {replaced_with_other: true}
      else
        resource.update!(name: new_name)
        render json: {}
      end
    end

  end
end