ActiveAdmin.register Article do

  permit_params :title, :short, :full, :image, :frontpage, :live, :article_author_id, :article_category_id
end
