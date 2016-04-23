module FixSpelling
  extend ActiveSupport::Concern

  included do

    has_many :misspellings, as: :source, dependent: :destroy

    scope :query_with_aliases, -> (value) {
      q = joins("LEFT JOIN misspellings ON source_type = '#{name}' AND source_id = #{table_name}.id")
      q = q.where("#{table_name}.name = :name OR misspellings.alias_string = :name", name: value)
      q.create_with(name: value)
    }

    def merge_into(target)
      self.class.transaction do
        target.misspellings.where(alias_string: self.name).first_or_create!
        self.misspellings.each do |misspelling|
          target.misspellings.where(alias_string: misspelling.alias_string).first_or_create!
        end
        self.class.reflections.each do |name, reflection|
          macro = reflection.macro.to_s
          if macro =~ /has_/ && !reflection.options[:through]
            self.send(name.to_sym).update_all(reflection.foreign_key => target.id)
          end
        end
        self.destroy
      end

    end

  end
end