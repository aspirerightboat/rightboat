ActiveAdmin.register MarineEnquiry do

  menu parent: 'Other', priority: 2

  config.sort_order = 'created_at_desc'
end
