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
  Boat.not_deleted.order('id DESC').find_each do |boat|
    add boat_path(boat), lastmod: boat.updated_at
  end
end
