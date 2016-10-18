SitemapGenerator::Sitemap.default_host = 'https://www.rightboat.com'

SitemapGenerator::Sitemap.create do
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  add '/contact'
  add '/toc'
  add '/privacy_policy'
  add '/cookies_policy'
  add '/sell_my_boats'

  Rightboat::SitemapHelper.boats_with_makemodel_slugs.find_each do |boat|
    add sale_boat_path(boat.manufacturer_slug, boat.model_slug, boat.slug), lastmod: boat.updated_at
  end

  Rightboat::SitemapHelper.active_manufacturer_slugs.each do |maker_slug|
    add sale_manufacturer_path(maker_slug), priority: 0.4
  end

  Rightboat::SitemapHelper.active_makemodel_slugs.each do |maker_slug, model_slug|
    add sale_model_path(maker_slug, model_slug), priority: 0.3
  end

end
