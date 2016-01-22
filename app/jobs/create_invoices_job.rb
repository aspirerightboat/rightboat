class CreateInvoicesJob
  attr_reader :inv_logger

  def perform(only_broker_id = nil)
    init_logger
    inv_logger.info('Fetch leads')
    all_leads = fetch_leads(only_broker_id)
    return if all_leads.none?

    leads_by_broker = all_leads.group_by { |lead| lead.boat.user }
    brokers = leads_by_broker.keys
    inv_logger.info("Found #{all_leads.size} leads for #{brokers.size} brokers")

    ensure_contacts(brokers)

    Invoice.transaction do
      xero_invoices = []
      invoices = leads_by_broker.map do |broker, leads|
        inv_logger.info("Prepare invoice for broker_id=#{broker.id} leads_count=#{leads.size}")
        broker_info = broker.broker_info
        discount_rate = broker_info.discount

        i = Invoice.new
        xi = $xero.Invoice.build(type: 'ACCREC', status: 'DRAFT')
        xi.line_amount_types = 'Exclusive'
        xi.date = Time.current.to_date.to_s(:db)
        xi.due_date = 1.month.from_now.to_date.to_s(:db)

        vat_rate = broker.address.try(:country).try(:iso) == 'GB' ? 0.2 : 0
        leads_price = 0
        total_discount = 0
        leads.each do |lead|
          boat = lead.boat
          boat_price_str = "#{boat.price} #{(boat.currency || Currency.default).symbol}"
          lead_price = lead.lead_price
          lead_price_discounted = (lead_price * (1 - discount_rate)).round(2)
          total_discount += lead_price - lead_price_discounted

          line_item_attrs = {
              description: "Lead #{lead.id}\n#{boat.manufacturer_model} #{boat.length_m} m #{boat_price_str}",
              quantity: 1, unit_amount: lead_price, account_code: 200,
              discount_rate: discount_rate * 100,
              line_amount: lead_price_discounted,
          }
          # line_item_attrs.merge!(tax_type: 'SRINPUT') if vat_rate > 0
          xi.add_line_item(line_item_attrs)
          leads_price += lead_price_discounted
        end

        i.subtotal = leads_price
        i.discount_rate = discount_rate
        i.discount = total_discount
        i.total_ex_vat = i.subtotal
        i.vat_rate = vat_rate
        i.vat = (i.total_ex_vat * i.vat_rate).round(2)
        i.total = i.total_ex_vat + i.vat
        i.user = broker
        i.save!
        Enquiry.where(id: leads.map(&:id)).update_all(invoice_id: i.id, status: 'invoiced', updated_at: Time.current)

        xi.sub_total = i.subtotal
        xi.total_tax = i.vat
        xi.total = i.total
        xi.invoice_number = i.id
        xi.currency_code = Currency.default.name
        xi.build_contact(contact_id: broker_info.xero_contact_id, name: broker.name, contact_status: 'ACTIVE')
        xero_invoices << xi
        i
      end

      inv_logger.info('Save invoices to Xero')
      if !$xero.Invoice.save_records(xero_invoices)
        xero_invoices.each do |invoice|
          raise "Invoice Not Saved: #{invoice.errors}" if invoice.errors.any?
        end
      end

      LeadsMailer.invoicing_report(invoices.map(&:id)).deliver_later
    end

    inv_logger.info('Finished')
    true
  rescue StandardError => e
    inv_logger.error("#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    false
  end

  def init_logger
    log_dir = Rails.root + 'log/invoices'
    FileUtils.mkdir_p(log_dir)
    @inv_logger = Logger.new("#{log_dir}/invoices-log-#{Time.current.strftime('%F--%H-%M-%S')}.log")
  end

  def fetch_leads(only_broker_id)
    rel = Enquiry.approved.not_deleted.where(invoice_id: nil)
              .where('enquiries.created_at < ?', Time.current.beginning_of_day)
              .includes(boat: [:manufacturer, :model, :currency, {user: :broker_info}])
    if only_broker_id
      rel = rel.references(:boat).where(boats: {user_id: only_broker_id})
    end
    rel.to_a
  end

  def ensure_contacts(brokers)
    inv_logger.info('Ensure brokers are linked to xero contacts')
    unlinked_brokers = brokers.select { |b| !b.broker_info.xero_contact_id }

    if unlinked_brokers.any?
      inv_logger.info("#{unlinked_brokers.size} brokers are not linked. Create corresponding contacts")

      contacts = unlinked_brokers.map do |broker|
        broker_info = broker.broker_info
        contact = $xero.Contact.build
        contact.name = broker.name
        contact.contact_number = broker.id
        contact.first_name = broker.first_name
        contact.last_name = broker.last_name
        contact.email_address = broker.email
        contact.contact_status = 'ACTIVE'
        contact.tax_number = broker_info.vat_number
        if (address = broker.address)
          contact.add_address(type: 'STREET',
                              line1: address.line1,
                              line2: address.line2,
                              line3: address.line3,
                              city: address.town_city,
                              region: address.county,
                              postal_code: address.zip,
                              country: address.country.try(:iso))
        end
        country_code = address.country.try(:country_code)
        contact.add_phone(type: 'DEFAULT', area_code: country_code, number: broker.phone) if broker.phone.present?
        contact.add_phone(type: 'MOBILE', area_code: country_code, number: broker.mobile) if broker.mobile.present?
        contact
      end

      if !$xero.Contact.save_records(contacts)
        contacts.each do |contact|
          raise "Contact Not Saved: #{contact.errors}" if contact.errors.any?
        end
      end

      contacts.each do |contact|
        broker = brokers.find { |b| b.id.to_s == contact.contact_number.to_s }
        broker.broker_info.update_attribute(:xero_contact_id, contact.contact_id)
      end
    end
    inv_logger.info('All brokers are linked')
  end
end
