ActiveAdmin.register BerthEnquiry do

  menu parent: 'Other', label: 'Berth Requests'

  config.sort_order = 'created_at_desc'

  index do
    column :id
    column :name do |berth_enquiry|
      link_to berth_enquiry.user.name, admin_user_path(berth_enquiry.user)
    end
    column :email do |berth_enquiry|
      link_to berth_enquiry.user.email, admin_user_path(berth_enquiry.user)
    end
    column :buy
    column :rent
    column :home
    column :short_term
    column :length do |berth_enquiry|
      "#{berth_enquiry.length_min} ~ #{berth_enquiry.length_max} #{berth_enquiry.length_unit}"
    end
    column :location do |berth_enquiry|
      "#{berth_enquiry.location}(#{berth_enquiry.latitude}, #{berth_enquiry.longitude})"
    end
    actions
  end
end
