ActiveAdmin.register StripeCard do

  menu parent: 'Users'

  config.sort_order = 'id_desc'

  actions :all, except: [:new]

  filter :user, as: :select, collection: User.companies
  filter :last4_or_dynamic_last4_cont, label: 'Last Digits'
  filter :brand
  filter :country_iso
  filter :exp_month
  filter :exp_year
  filter :updated_at
  filter :created_at

  index do
    column :id
    column :broker do |card|
      link_to card.user.name, admin_user_path(card.user)
    end
    column :brand
    column(:country) { |card| card.country_iso }
    column :last_digits
    column(:expiration) { |card| '%02d / %d' % [card.exp_month, card.exp_year] }
    column :created_at

    actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end
end
