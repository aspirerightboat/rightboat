xero_logger = Logger.new("#{Rails.root}/log/xero.log", 'weekly')

$xero = Xeroizer::PrivateApplication.new(Figaro.env.xero_consumer_key,
                                         Figaro.env.xero_consumer_secret,
                                         "#{Rails.root}/config/xero/#{Figaro.env.xero_privatekey_filename}",
                                         logger: xero_logger)
