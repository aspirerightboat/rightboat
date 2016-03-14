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
    page_params = params.except(:controller, :action)
    content_tag :nav, class: 'pagination' do
      s = String.new
      s << content_tag(:span, content_tag(:a, '‹ Prev', href: "?#{page_params.merge(page: @page - 1).to_query}"), class: 'prev') if @page > 1
      s << content_tag(:span, content_tag(:a, 'Next ›', href: "?#{page_params.merge(page: @page + 1).to_query}"), class: 'next') if show_next
      s.html_safe
    end
  end
end