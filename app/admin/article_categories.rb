ActiveAdmin.register ArticleCategory do

  menu parent: "Articles", label: "Categories", priority: 1

  permit_params :name, :slug
end
