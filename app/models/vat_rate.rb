class VatRate < ActiveRecord::Base
  include FixSpelling
  include BoatOwner

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  def tax_paid?(activated = nil)
    is_activated = activated.nil? ? true : activated
    is_activated && !!(self.name.to_s =~ /^1$|^tax paid|^paid|inc vat|vat paid|vatincluded|duty paid|£\s+\d+/i)
  end

  def tax_status(activated = nil)
    is_activated = activated.nil? ? true : activated
    if is_activated
      tax_paid?(activated) ? 'Tax Paid' : 'Tax Unpaid'
    else
      'NA'
    end
  end

  def self.tax_paid
    @tax_paid ||= first
  end

  def self.tax_unpaid
    @tax_not_paid ||= second
  end

  def to_s
    name
  end
end
