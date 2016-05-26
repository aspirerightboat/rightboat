class BoatTemplateSerializer < ActiveModel::Serializer
  delegate :render, to: :scope

  attributes :template

  def template
    render file: 'boats/_boat.html.slim', locals: { boat: object }
  end
end
