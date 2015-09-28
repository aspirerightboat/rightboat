ActiveAdmin.register ArticleAuthor do

  menu parent: "Articles", label: "Author", priority: 2

  permit_params :title, :name, :description, :photo, :google_plus_link, :twitter_handle, :slug
end
