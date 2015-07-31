module Sortable

  def self.included(base)
    base.config.paginate = false
    base.config.sort_order = 'position_asc'

    base.send :collection_action, :sort, method: :post do
      (params[:sorted_ids] || []).each_with_index do |id, index|
        resource_class.where(id: id).update_all(position: index + 1)
      end

      head 200
    end
  end

end

module ActiveAdmin
  module Views
    class IndexAsSortableTable < IndexAsTable
      def table_for(*args, &block)
        options = args.extract_options!
        options['data-sortable-url'] = url_for(action: :sort)
        args << options
        insert_tag IndexTableFor, *args, &block
      end

      def self.index_name
        'sortable_table'
      end
    end
  end
end
