class VatRate < ActiveRecord::Base
  include FixSpelling
  include AdvancedSolrIndex
  include BoatOwner

  # solr_update_association :boats, fields: [:active, :name]

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def tax_paid?(activated = nil)
    is_activated = activated.nil? ? true : activated
    is_activated && !!(self.name.to_s =~ /^tax paid|^paid|inc vat|vat paid|duty paid|£\s+\d+/i)
  end

  def tax_status(activated = nil)
    is_activated = activated.nil? ? true : activated
    if is_activated
      tax_paid?(activated) ? 'Paid' : 'Not Paid'
    else
      'NA'
    end
  end

  def to_s
    name
  end
end
