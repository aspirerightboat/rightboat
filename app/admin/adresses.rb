# ActiveAdmin.register Address do
#   menu parent: 'Users'
#
#   config.sort_order = 'name_asc'
#   permit_params :line1, :line2, :town_city, :county, :country_id, :zip,
#                 :addressible_id, :addressible_type, :created_at, :updated_at
#
#   filter :addressible, as: :select, collection: -> { User.companies }
#
#   index do
#     column :line1
#     column :line2
#     column :town_city
#     column :county
#     column :country_id
#     column :zip
#     column :addressible
#     column :addressible_type
#     actions
#   end
#
#   form do |f|
#     f.inputs do
#       f.input :line1
#       f.input :line2
#       f.input :town_city
#       f.input :county
#       f.input :country_id
#       f.input :zip
#
#       f.has_many :address, allow_destroy: true, new_record: false do |addr_f|
#         addr_f.input :line1
#         addr_f.input :line2
#         addr_f.input :town_city
#         addr_f.input :county
#         addr_f.input :country
#         addr_f.input :zip
#       end
#     end
#
#     f.actions
#   end
#
# end
