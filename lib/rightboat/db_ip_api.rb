# see: https://www.db-ip.com/api/#documentation
# free API key allows 2,500 queries per day

class Rightboat::DbIpApi
  def self.api_key
    Rails.application.secrets.db_ip_key
  end

  # example of returned data:
  #
  # {
  #     "address" => "173.194.67.1",
  #     "country" => "US",
  #     "stateprov" => "California",
  #     "city" => "Mountain View",
  #     "latitude" => "37.422",
  #     "longitude" => "-122.085",
  #     "tz_offset" => "-7",
  #     "tz_name" => "America/Los_Angeles"
  # }
  def self.addr_info(ip)
    uri = URI("http://api.db-ip.com/addrinfo?addr=#{ip}&api_key=#{api_key}")

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse response.body
    else
      {}
    end
  end

  def self.country(ip)
    addr_info(ip)['country']
  end

  def self.key_info
    uri = URI("http://api.db-ip.com/keyinfo?api_key=#{api_key}")

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse response.body
    else
      {}
    end
  end
end