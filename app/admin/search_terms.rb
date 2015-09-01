ActiveAdmin.register_page 'Search terms' do

  page_action :destroy, method: :delete do
    @activity = Activity.find params[:id]
    @activity.destroy
    redirect_to admin_search_terms_path, notice: 'Search term was deleted'
  end

  content title: 'Search terms' do
    page = (params[:page] || 1).to_i
    size = 3
    offset = (page - 1) * size
    @activities = Activity.search.popular.page(page).per(size)
    total = @activities.total_count
    last = offset + size
    last = total if last > total


    div class: 'paginated_collection' do
      div class: 'paginated_collection_contents' do
        table class: 'index_table' do
          thead do
            tr do
              %w(Parameters Count).each &method(:th)
              th
            end
          end
          tbody do
            @activities.each_with_index do |activity, i|
              tr class: "#{i%2 == 0 ? 'odd' : 'even'}" do
                td do
                  activity.parameters
                end
                td do
                  activity.count
                end
                td do
                  link_to 'Delete', admin_search_terms_destroy_path(id: activity.id), method: :delete
                end
              end
            end
          end
        end
      end
      div class: 'index_footer' do
        nav class: 'pagination' do
          span class: "prev" do
            if page > 1
              a rel: 'prev', href: "/admin/search_terms?page=#{page - 1 }" do
                'Prev'
              end
            end
            if last < total
              a rel: 'next', href: "/admin/search_terms?page=#{page + 1 }" do
                'Next'
              end
            end
          end
        end
        div class: 'pagination_information' do
          "Displaying Search terms <b>#{offset + 1} - #{last}</b> of <b>#{total}</b> in total".html_safe
        end
      end
    end
  end
end
