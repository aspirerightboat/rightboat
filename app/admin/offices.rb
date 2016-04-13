ActiveAdmin.register Office do
  menu parent: 'Users'

  config.sort_order = 'name_asc'
  permit_params :user_id, :name, :email, :daytime_phone, :evening_phone,
                :fax, :mobile, :website,
                address_attributes: [:line1, :line2, :town_city, :county, :country_id, :zip, :addressible_id, :addressible_type]

  filter :user, as: :select, collection: -> { User.order(:company_name, :first_name) }
  filter :email

  index do
    column :user, sortable: false
    column :name
    column :address
    column :website do |r|
      link_to r.website, r.website, target: :blank unless r.website.blank?
    end
    actions
  end

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection:  User.companies
      f.input :name
      f.input :email
      f.input :daytime_phone
      f.input :evening_phone
      f.input :fax
      f.input :mobile
      f.input :website

      f.has_many :address, allow_destroy: true do |addr_f|
        addr_f.input :line1
        addr_f.input :line2
        addr_f.input :town_city
        addr_f.input :county
        addr_f.input :country, as: :select, collection: Country.order(:name)
        addr_f.input :zip
      end
    end

    f.actions
  end

end
