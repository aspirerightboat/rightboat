class SolrIndexJob
  def initialize(klass, id, type = :index)
    @klass = klass
    @id = id
    @type = type
  end

  def perform
    record = @klass.constantize.unscoped.find(@id)
    if @type.to_sym == :index
      record.solr_index_without_dj
    else
      record.solr_remove_from_index_without_dj
    end
  rescue ActiveRecord::RecordNotFound
    # Record destroyed?
  end
end