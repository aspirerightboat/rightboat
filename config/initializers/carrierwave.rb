if Rails.env.production?
  CarrierWave.configure do |config|
    config.fog_credentials = {
        provider: 'AWS',
        aws_access_key_id: Figaro.env.aws_s3_access_key_id,
        aws_secret_access_key: Figaro.env.aws_s3_secret_access_key,
        region: 'eu-central-1',
        host: 's3.eu-central-1.amazonaws.com',
        endpoint: 'https://s3.eu-central-1.amazonaws.com'
    }

    config.asset_host = 'https://d2qh54gyqi6t5f.cloudfront.net'

    config.fog_directory  = 'rightboat'
    # config.fog_public     = true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}
    end
end
