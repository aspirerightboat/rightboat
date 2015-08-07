require 'ezcrypto'

module Rightboat

  class Captcha

    CIPHER_KEY  = "rightboatcaptcha"
    CIPHER_SALT = Figaro.env.captcha_salt.to_s

    attr_reader :a, :b, :operator, :ts

    def initialize
      @a        = (1..10).to_a.sample
      @b        = (1..10).to_a.sample
      @operator = [:+, :*].sample
    end

    def image
      draw = Magick::Draw.new
      draw.pointsize = 12
      draw.font_weight = Magick::NormalWeight
      draw.font_style = Magick::ItalicStyle
      draw.fill = '#60bbff'
      x = draw.get_type_metrics question

      img = Magick::Image.new(x.width, x.height) do
        self.format = 'png'
        self.background_color = 'transparent'
      end

      draw.annotate(img, 0, 0, 0, 0, question) do
        # self.font = 'Helvetica'
        self.gravity = Magick::SouthEastGravity
      end
      ret = img.to_blob
      img.destroy!
      ret
    end

    def initialize_from(secret)
      yml = YAML.load(key.decrypt64(secret))
      @a, @b, @operator, @ts = yml[:a], yml[:b], yml[:operator], yml[:ts]
    end

    def correct?(value)
      (@ts.to_i > (Time.now.to_i - 300)) && result == value.to_i
    end

    def encrypt
      key.encrypt64 to_yaml
    end

    def self.decrypt(secret)
      result = new
      result.initialize_from secret
      result
    end

    def question
      "What is #{@a} #{@operator.to_s} #{@b} ="
    end

    protected

    def to_yaml
      YAML::dump({
                   :a        => @a,
                   :b        => @b,
                   :operator => @operator,
                   :ts       => Time.now.to_i
                 })
    end

    private

    def key
      EzCrypto::Key.with_password CIPHER_KEY, CIPHER_SALT
    end

    def result
      @a.send @operator, @b
    end

  end

end
