module SunspotRelation
  extend ActiveSupport::Concern

  included do
    def self.sunspot_related(*relations)
      cattr_accessor :_sunspot_relations

      missing_relations = relations.select do |relation|
        !reflections[relation.to_s]
      end

      raise "There is no association: #{missing_relations.join(', ')}" if missing_relations.any?

      self._sunspot_relations = relations

      around_save :reindex_relations_while_saving
      around_destroy :reindex_relations_while_destroying
    end

    def reindex_relations_while_saving
      self.class._sunspot_relations.each do |relation|
        reflection = self.class.reflections[relation.to_s]
        cardinality = reflection.macro.to_s.gsub('has_', '')
        if cardinality =~ /many/
          has_change = changes.blank?
          yield
          send(relation).unscoped.solr_index if has_change
        elsif cardinality == 'one' or cardinality == 'belongs_to'
          has_change = changes.blank?
          records = [send(relation)] if has_change
          yield
          records << send(relation) if has_change
          records.uniq.reject(&:nil?).each(&:solr_index)  if has_change
        else
          raise "missed relation type? #{cardinality}"
        end
      end
    end

    def reindex_relations_while_destroying
      self.class._sunspot_relations.each do |relation|
        reflection = self.class.reflections[relation.to_s]
        cardinality = reflection.macro.to_s.gsub('has_', '')
        if cardinality =~ /many/
          objects = send(relation)
          yield
          objects.solr_index
        elsif cardinality == 'one' or cardinality == 'belongs_to'
          record = send(relation)
          yield
          record.solr_index if record
        else
          raise "missed relation type? #{cardinality}"
        end
      end
    end

  end
end