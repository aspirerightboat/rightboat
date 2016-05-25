module ActiveAdmin::UsersHelper
  def user_admin_link(user)
    link_to user.name, admin_user_path(user)
  end

  def user_activity_to_sentence(activity)
    if activity.kind == 'boat_view'
      content_tag :p, class: activity.kind do
        concat content_tag(:span, activity.created_at.to_s(:time), class: 'status_tag')
        concat " User has viewed a boat: "
        concat link_to "#{activity.boat.manufacturer.to_s} - #{activity.boat.model.to_s}", admin_boat_path(activity.boat_id)
      end
    elsif activity.kind == 'lead'
      content_tag :p, class: activity.kind do
        concat content_tag(:span, activity.created_at.to_s(:time), class: 'status_tag')
        concat " User has made a lead: "
        concat link_to "#{activity.lead.boat.manufacturer.to_s} - #{activity.lead.boat.model.to_s}", admin_lead_path(activity.lead_id)
      end
    elsif activity.kind == 'search'
      content_tag :p, class: activity.kind do
        concat content_tag(:span, activity.created_at.to_s(:time), class: 'status_tag')
        concat " User has saved a search: "
        concat content_tag(:i, query_to_readable_string(activity))
      end
    end
  end

  private

  def query_to_readable_string(activity)
    models = activity.meta_data[:models] && Model.where(id: activity.meta_data[:models])
    manufacturers = activity.meta_data[:manufacturers] && Manufacturer.where(id: activity.meta_data[:manufacturers])
    activity.meta_data[:models] = models&.pluck(:name)
    activity.meta_data[:manufacturers] = manufacturers&.pluck(:name)
    activity.meta_data.delete_if { |_,v| v.nil? }
    activity.meta_data.to_s.gsub('=>', ': ')
  end
end
