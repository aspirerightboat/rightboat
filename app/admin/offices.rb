ActiveAdmin.register Office do
  menu parent: 'Users'

  config.sort_order = 'name_asc'
  permit_params :user_id, :name, :email, :daytime_phone, :evening_phone,
                :fax, :mobile, :website,
                address_attributes: [:line1, :line2, :town_city, :county, :country_id, :zip, :addressible_id, :addressible_type]

  filter :user, collection: -> { User.companies }
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

  show do |office|
    default_main_content
    panel 'Address' do
      attributes_table_for office.address do
        (Address.column_names - %w(id addressible_id addressible_type)).each { |column| row column }
      end
    end
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
