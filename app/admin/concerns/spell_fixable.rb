module SpellFixable

  def self.included(base)

    base.send :member_action, :active, method: :post do
      if resource.update_attributes(active: true)
        flash[:notice] = "#{resource} is activated successfully."
      else
        flash[:error] = "Sorry, #{resource} can't be activated."
      end
      redirect_to :back
    end

    base.send :member_action, :disable, method: :post do
      if resource.update_attributes(active: false)
        flash[:notice] = "#{resource} is disabled successfully."
      else
        flash[:error] = "Sorry, #{resource} can't be disabled."
      end
      redirect_to :back
    end

    base.send :collection_action, :all, method: :get, format: :json do
      obj = resource_class
      if resource_class.name == 'Model'
        obj = obj.where(manufacturer_id: obj.find(params[:id]).manufacturer_id)
      end
      collection = obj.select(:id, :name).order(:name).map{ |r|
        { id: r.id, name: r.name }
      }

      render json: collection
    end

    base.send :member_action, :merge, method: :post do
      target = resource_class.find(params[:to])
      if resource.merge_into(target)
        flash[:notice] = "#{resource} has merged into #{target}"
      else
        flash[:error] = "Sorry, #{resource} can't be merged into #{target}"
      end
      redirect_to :back
    end

    base.send :collection_action, :search, method: :get, format: :json do
      collection = resource_class.where('name LIKE ?', "%#{params[:term]}%").select(:id, :name).limit(10)
      render json: collection.map { |x| { id: x.id, value: x.name} }, root: false
    end
  end

end