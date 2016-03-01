module ActiveAdmin::ViewsHelper
  def arbre(&block)
    Arbre::Context.new(&block).to_s
  end

  def yes_no_status(yes)
    arbre do
      yes ? status_tag('Yes', :yes) : status_tag('No', :no)
    end
  end
end