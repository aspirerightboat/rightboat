# http://proxymesh.com/blog/pages/proxymesh-api.html

class Rightboat::ProxyMesh

  def self.receive_proxy_url
    # Rails.cache.fetch('proxymesh_proxy_url', expires_in: 1.hour) do
    #   user = Rails.application.secrets.proxymesh_user
    #   pass = Rails.application.secrets.proxymesh_pass
    #   res = open('https://proxymesh.com/api/proxies/', http_basic_authentication: [user, pass]).read
    #   json = JSON.parse(res)
    #   'http://' + json['proxies'].sample
    # end

    'http://uk.proxymesh.com:31280' # only proxy that working well
  end

end
