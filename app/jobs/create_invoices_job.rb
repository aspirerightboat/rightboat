class CreateInvoicesJob
  attr_reader :inv_logger

  def perform(only_broker_id = nil)
    init_logger
    inv_logger.info('Fetch leads')
    all_leads = fetch_leads(only_broker_id)
    return true if all_leads.none?

    leads_by_broker = all_leads.group_by { |lead| lead.boat.user }
    brokers = leads_by_broker.keys
    inv_logger.info("Found #{all_leads.size} leads for #{brokers.size} brokers")

    contact_by_broker = ensure_contacts(brokers)

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
        xi.reference = i.id
        xi.currency_code = Currency.default.name
        xi.build_contact(contact_id: broker_info.xero_contact_id, name: contact_by_broker[broker].name, contact_status: 'ACTIVE')
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
    inv_logger.info('Fetch contacts for brokers')
    contact_by_broker = {}

    maybe_linked_brokers = brokers.select { |b| b.broker_info.xero_contact_id.present? }
    maybe_linked_brokers.each_slice(10) do |brokers_slice| # slice in groups by 10 because Xero throws "Xeroizer::ObjectNotFound" if there are too many
      search_str = brokers_slice.map { |b| %(ContactID.ToString()=="#{b.broker_info.xero_contact_id}") }.join(' OR ')
      contacts = $xero.Contact.all(where: search_str)
      brokers_slice.each do |broker|
        contact_id = broker.broker_info.xero_contact_id
        contact = contacts.find { |c| c.contact_id == contact_id }
        contact_by_broker[broker] = contact if contact
        inv_logger.info("Cannot fetch Contact with contact_id=#{contact_id} for broker_id=#{broker.id} (#{broker.name})") if !contact
      end
    end
    inv_logger.info("Fetched #{contact_by_broker.size} contacts for #{maybe_linked_brokers.size} brokers by contact_id")

    unlinked_brokers = brokers - contact_by_broker.keys
    if unlinked_brokers.any?
      inv_logger.info("#{unlinked_brokers.size} brokers are not linked. Try to find contacts by brokers name/contact_num")

      unlinked_brokers.each_slice(10) do |brokers_slice|
        search_str = brokers_slice.map { |b| %(ContactNumber=="#{b.id}" OR Name=="#{b.name}") }.join(' OR ')
        contacts = $xero.Contact.all(where: search_str)
        brokers_slice.each do |broker|
          broker_id = broker.id.to_s
          broker_name = broker.name
          contact = contacts.find { |c| c.contact_number == broker_id || c.name == broker_name }
          if contact
            contact_by_broker[broker] = contact
            broker.update_column(:xero_contact_id, contact.id)
            inv_logger.info("Found contact #{contact.id} for broker_id=#{broker_id} (#{broker_name})")
          end
        end
      end

      unlinked_brokers = brokers - contact_by_broker.keys
      inv_logger.info("#{unlinked_brokers.size} brokers are still not linked. Create contacts for them")

      new_contacts = unlinked_brokers.map { |broker| build_contact_for_broker(broker) }
      if $xero.Contact.save_records(new_contacts)
        new_contacts.each do |c|
          inv_logger.info("Contact created for broker_id=#{c.contact_number} (#{c.name})")
        end
      else
        new_contacts.each do |c|
          inv_logger.error("Contact not saved: broker_id=#{c.contact_number} (#{c.name}) errors=#{c.errors}") if c.errors.present?
        end
        raise 'Save Contacts Error'
      end

      unlinked_brokers.each do |broker|
        broker_id = broker.id.to_s
        contact = new_contacts.find { |c| c.contact_number == broker_id }
        broker.broker_info.update_column(:xero_contact_id, contact.contact_id)
        contact_by_broker[broker] = contact
      end
    end

    inv_logger.info('All brokers are linked')

    contact_by_broker
  end

  def build_contact_for_broker(broker)
    broker_info = broker.broker_info
    contact = $xero.Contact.build
    contact.name = broker.name
    contact.contact_number = broker.id.to_s
    contact.first_name = broker.first_name
    contact.last_name = broker.last_name
    contact.email_address = broker.email
    contact.contact_status = 'ACTIVE'
    contact.tax_number = broker_info.vat_number
    contact.is_customer = true
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
end
