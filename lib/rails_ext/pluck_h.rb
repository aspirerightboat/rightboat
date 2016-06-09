# simplified version of https://github.com/girishso/pluck_to_hash

module PluckH
  extend ActiveSupport::Concern

  module ClassMethods
    def pluck_h(*keys)
      pluck(*keys).map do |values|
        if keys.one?
          {keys.first => values}
        else
          Hash[keys.zip(values)]
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, PluckH)
