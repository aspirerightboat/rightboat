module FixSpelling
  extend ActiveSupport::Concern

  included do

    has_many :misspellings, as: :source, dependent: :destroy

    scope :query_with_aliases, lambda { |name|
      q = self.joins("LEFT JOIN misspellings ON source_type = '#{self.name}' AND source_id = #{self.table_name}.id")
      q = q.where('name = :name OR misspellings.alias_string = :name', name: name)
      q.create_with(name: name)
    }

    def merge_into(target)
      self.class.transaction do
        target.misspellings.where(alias_string: self.name).first_or_create!
        self.misspellings.each do |misspelling|
          target.misspellings.where(alias_string: misspelling.alias_string).first_or_create!
        end
        self.class.reflections.each do |name, reflection|
          macro = reflection.macro.to_s
          if macro =~ /has_/
            self.send(name.to_sym).update_all(reflection.foreign_key => target.id)
          end
        end
        self.destroy
      end

    end

  end
end