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
    end
  end
end
