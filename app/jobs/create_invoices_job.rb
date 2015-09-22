class CreateInvoicesJob
  def perform
    leads = Enquiry.where(invoice_id: nil).where(status: 'approved').where('created_at < ?', Time.current.beginning_of_day)
                .includes(boat: {user: :broker_info}).to_a
    invoice_ids = leads.group_by { |lead| lead.boat.user }.map do |broker, leads|
      broker_info = broker.broker_info
      i = Invoice.new
      i.subtotal = leads.sum { |lead| lead.boat.length_ft * broker_info.lead_rate }.round(2)
      i.discount_rate = broker_info.discount
      i.discount = (i.subtotal * broker_info.discount).round(2)
      i.total_ex_vat = i.subtotal - i.discount
      i.vat_rate = broker.address.try(:country).try(:iso) == 'GB' ? 0.2 : 0
      i.vat = (i.total_ex_vat * i.vat_rate).round(2)
      i.total = i.total_ex_vat + i.vat
      i.user = broker
      Invoice.transaction do
        i.save!
        Enquiry.where(id: leads.map(&:id)).update_all(invoice_id: i.id, status: 'invoiced')
      end
      i.id
    end
    LeadsMailer.invoicing_report(invoice_ids).deliver_now
  end
end
