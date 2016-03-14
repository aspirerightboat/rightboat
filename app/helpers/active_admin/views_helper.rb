module ActiveAdmin::ViewsHelper
  def arbre(&block)
    Arbre::Context.new(&block).to_s
  end

  def yes_no_status(yes)
    arbre do
      yes ? status_tag('Yes', :yes) : status_tag('No', :no)
    end
  end

  def infinite_prev_next_links
    page_params = params.except(:controller, :action)
    content_tag :name, class: 'pagination' do
      s = String.new
      s << content_tag(:span, content_tag(:a, 'Next ›', href: page_params.merge(page: @page + 1)), class: 'next')
      s << content_tag(:span, content_tag(:a, '‹ Prev', href: page_params.merge(page: @page - 1)), class: 'prev') if @page > 1
    end
  end
end