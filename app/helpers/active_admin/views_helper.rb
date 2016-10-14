module ActiveAdmin::ViewsHelper
  def arbre(&block)
    Arbre::Context.new(&block).to_s
  end

  def yes_no_status(yes)
    arbre do
      yes ? status_tag('Yes', :yes) : status_tag('No', :no)
    end
  end

  def prev_next_links(show_next = true)
    query_hash = Rack::Utils.parse_query(URI.parse(request.url).query)
    prev_url = "#{request.path}?#{query_hash.merge(page: @page - 1).to_query}" if @page > 1
    next_url = "#{request.path}?#{query_hash.merge(page: @page + 1).to_query}" if show_next
    arbre do
      nav(class: 'pagination') do
        span(class: 'prev') { a(href: prev_url) { '‹ Prev' } } if prev_url
        span(class: 'next') { a(href: next_url) { 'Next ›' } } if next_url
      end
    end
  end

  def pretty_admin_field(resource, attr_name)
    value = if attr_name.end_with?('_id')
              send(:pretty_format, resource.send(attr_name.chomp('_id')))
            else
              html_escape(resource.send(attr_name).to_s).html_safe
            end

    value.present? ? value : '<span class="empty">empty</span>'.html_safe
  end
end
