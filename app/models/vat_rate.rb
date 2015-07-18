class VatRate < ActiveRecord::Base
  include FixSpelling
  include AdvancedSolrIndex

  has_many :boats, inverse_of: :vat_rate, dependent: :restrict_with_error

  solr_update_association :boats, fields: [:active, :name]

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  scope :active, -> { where active: true }

  def tax_paid?(activated = nil)
    is_activated = activated.nil? ? active? : activated
    is_activated && !!(self.name.to_s =~ /inc vat|tax paid/i)
  end

  def tax_status(activated = nil)
    is_activated = activated.nil? ? active? : activated
    if is_activated
      tax_paid?(activated) ? "Paid" : "Not Paid"
    else
      'NA'
    end
  end

  def to_s
    name
  end
end
