ActiveAdmin.register Deal do
  menu parent: 'Users'

  config.sort_order = 'id_desc'

  permit_params Deal.column_names - %w(id)

  filter :user, collection: -> { User.companies }
  filter :deal_type, as: :select, collection: -> { Deal::DEAL_TYPES }
  filter :flat_lead_price
  filter :flat_month_price
  filter :trial_started_at
  filter :trial_ended_at
  filter :updated_at
  filter :created_at

  controller do
    def scoped_collection
      end_of_association_chain.includes(user: :broker_info)
    end
  end

  index do
    id_column
    column('Broker') { |deal| link_to deal.user.name, admin_user_path(deal.user) }
    column :deal_type
    column 'Params' do |deal|
      deal.deal_params.each do |k, v|
        div(style: 'white-space: nowrap') { "#{k}: <b>#{v}</b>".html_safe }
      end
    end
    column('Charges Text') { |deal| deal.processed_charges_text }
    column('Trial') { |deal| "#{deal.trial_started_at&.strftime('%F')} - #{deal.trial_ended_at&.strftime('%F')}" }

    actions
  end

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.companies, include_blank: false
      f.input :deal_type, as: :select, collection: Deal::DEAL_TYPES, include_blank: false
      f.input :charges_text
      f.input :flat_lead_price
      f.input :flat_month_price
      f.input :currency, as: :select, collection: Currency.all, include_blank: false
      f.input :trial_started_at, as: :string, input_html: {class: 'datepicker', style: 'width: 100px', value: f.object.trial_started_at&.strftime('%F')}
      f.input :trial_ended_at, as: :string, input_html: {class: 'datepicker', style: 'width: 100px', value: f.object.trial_ended_at&.strftime('%F')}
    end
    actions
  end

end
