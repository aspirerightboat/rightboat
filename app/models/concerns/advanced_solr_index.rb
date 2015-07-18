module AdvancedSolrIndex
  extend ActiveSupport::Concern

  included do
    class << self

      def searchable_with_dj(options = {}, &blk)

        # options = options.reverse_merge(auto_index: false, auto_remove: false)

        # make solr index/remove working as background job for safe (DelayedJob)
        solr_searchable(options, &blk)

        handle_asynchronously :solr_index, priority: 10
        handle_asynchronously :solr_remove_from_index, priority: 9

      end

      alias_method :solr_searchable, :searchable
      alias_method :searchable, :searchable_with_dj
    end

    def self.solr_update_association(*relations)
      class_attribute :_sunspot_relations

      self._sunspot_relations ||= {}

      options = relations.extract_options!

      missing_relations = relations.select do |relation|
        !reflections[relation.to_s]
      end

      raise "There is no association: #{missing_relations.join(', ')}" if missing_relations.any?

      # destroy hooking is not needed due dependent & permanent
      around_save :reindex_relations_while_saving

      relations.each do |relation|
        self._sunspot_relations[relation] = options
      end

    end

    def reindex_relations_while_saving
      prev_relations = []
      after_relations = []

      self.class._sunspot_relations.each do |relation, _|
        reflection = self.class.reflections[relation.to_s]
        cardinality = reflection.macro.to_s.gsub('has_', '')
        next unless need_reindex_relation?(relation)
        if cardinality == 'many'
          after_relations << relation
        elsif cardinality == 'one'
          after_relations << relation
        elsif cardinality == 'belongs_to'
          prev_relations << relation if send("#{reflection.foreign_key}_changed?")
          after_relations << relation
        else
          # many-to-many relation
        end
      end

      prev_relations.each do |relation|
        reindex_relation(relation)
      end
      
      yield
      
      after_relations.each do |relation|
        reindex_relation(relation)
      end
    end

    def need_reindex_relation?(relation)
      option = self.class._sunspot_relations[relation]
      if option[:fields]
        reflection = self.class.reflections[relation.to_s]
        if reflection.macro.to_s == 'belongs_to'
          f_key = reflection.foreign_key.to_sym
          option[:fields] << f_key unless option[:fields].include?(f_key)
        end
        changed_attributes.keys.any?{ |k| option[:fields].include? k.to_sym }
      else
        changed_attributes.any?
      end
    end

    def reindex_relation(relation)
      records = send(relation)
      if records.is_a?(ActiveRecord::Base)
        records.solr_index
      else # collection
        records.each { |r| r.solr_index }
      end
    end
  end
end