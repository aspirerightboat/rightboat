class Rightboat::XeroInvoicer

  def process_invoices(dry_run: false)
    logger.info('Started')
    all_leads = fetch_leads
    return true if all_leads.none?

    leads_by_broker = all_leads.group_by { |lead| lead.boat.user }
    brokers = leads_by_broker.keys
    logger.info("Found #{all_leads.size} leads for #{brokers.size} brokers")

    contact_by_broker = ensure_contacts(brokers)
    invoicing_data = prepare_invoicing_data(contact_by_broker, leads_by_broker)
    generate_csv(invoicing_data)
    save_all(brokers, invoicing_data) unless dry_run

    logger.info('Finished')
    true
  rescue StandardError => e
    logger.error("#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}")
    Rightboat::CleverErrorsNotifier.try_notify(e, nil, nil, where: self.class.name)
    false
  end

  private

  def prepare_invoicing_data(contact_by_broker, leads_by_broker)
    leads_by_broker.map do |broker, leads|
      logger.info("Prepare invoice for broker_id=#{broker.id} (#{broker.name}) leads_count=#{leads.size}")
      broker_info = broker.broker_info
      deal = broker.deal
      discount_rate = broker_info.discount
      broker_currency = deal.currency

      xi = $xero.Invoice.build(type: 'ACCREC', status: 'DRAFT')
      xi.date = Time.current.to_date
      xi.due_date = xi.date
      xi.branding_theme_id = invoice_branding_theme&.branding_theme_id
      xi.currency_code = broker_currency.name
      xi.build_contact(contact_id: broker_info.xero_contact_id, name: contact_by_broker[broker].name, contact_status: 'ACTIVE')

      leads_price = 0
      leads_price_discounted = 0
      total_discount = 0
      tax_type = tax_type_for_broker(broker)
      tax_rate = tax_rate_by_type[tax_type]

      leads.each do |lead|
        boat = lead.boat
        description = "Lead ##{lead.id}, #{lead.name} for #{boat.display_name}, #{boat.price_str}"
        description << ", #{boat.length_m} m" if boat.length_m
        lead_price = Currency.convert(lead.lead_price, lead.lead_price_currency, broker_currency).round(2)
        leads_price += lead_price
        lead_price_discounted = (lead_price * (1 - discount_rate))
        total_discount += lead_price - lead_price_discounted
        leads_price_discounted += lead_price_discounted

        xi.add_line_item(description: description,
                         quantity: 1, unit_amount: lead_price, account_code: 200,
                         discount_rate: discount_rate * 100,
                         line_amount: lead_price_discounted,
                         tax_type: tax_type)
      end

      i = Invoice.new
      i.user = broker
      i.subtotal = leads_price
      i.discount_rate = discount_rate
      i.discount = total_discount
      i.total_ex_vat = leads_price_discounted
      i.vat_rate = tax_rate.effective_rate
      i.vat = (i.total_ex_vat * i.vat_rate).round(2)
      i.total = i.total_ex_vat + i.vat

      [i, xi, leads]
    end
  end

  def generate_csv(invoicing_data)
    CSV.open('/public/invoices.csv', 'wb') do |csv|
      csv << ['Contact Name',
              'Invoice No',
              'Invoice Date',
              'Net',
              'VAT',
              'Total £',
              'Total €',
              'Total $',
              'STR',
              'GC',
              'DEBTOR',
              'Tax Type',
              'Currency',
              'PO Country',
              'US County',
      ]
      invoicing_data.each do |i, xi, _leads|
        currency = i.user.deal.currency.name
        payment_method = i.user.broker_info.payment_method
        tax_rate = tax_rate_by_type[xi.line_items.first.tax_type]
        user_address = i.user.address
        csv << [xi.contact.name, # Contact Name
                xi.id, # Invoice No
                xi.date, # Invoice Date
                i.total_ex_vat, # Net
                i.vat, # VAT
                (i.total if currency == 'GBP'), # Total £
                (i.total if currency == 'EUR'), # Total €
                (i.total if currency == 'USD'), # Total $
                ('Y' if payment_method == 'card'), # STR
                ('Y' if payment_method == 'dd'), # GC
                ('Y' if payment_method['none']), # DEBTOR
                tax_rate.name, # Tax Type
                currency, # Currency
                user_address.country.name, # PO Country
                (user_address.county if user_address.country.iso == 'US'), # US County
        ]
      end
    end
  end

  def save_all(brokers, invoicing_data)
    Invoice.transaction do
      logger.info('Save invoices')
      invoicing_data.each do |invoice, xero_invoice, leads|
        invoice.save!
        xero_invoice.reference = invoice.id
        Lead.where(id: leads.map(&:id)).update_all(invoice_id: i.id, status: 'invoiced', updated_at: Time.current)
      end

      logger.info('Save invoices to Xero')
      xero_invoices = invoicing_data.map { |_i, xi, _leads| xi }
      res = $xero.Invoice.save_records(xero_invoices)
      if !res
        xero_invoices.each do |i|
          broker = brokers.find { |b| b.broker_info.xero_contact_id == i.contact.contact_id }
          logger.error("Failed to save invoice for broker_id=#{broker.id} (#{broker.name}) errors=#{i.errors}") if i.errors.present?
        end
        raise StandardError.new('Save Invoices Error')
      end
    end
  end

  def tax_type_for_broker(broker)
    if broker.country.iso == 'GI' # Gibraltar
      return 'EXEMPTOUTPUT'
    elsif broker.country.iso == 'GB' && broker.address.county.in?(%w(Jersey Guernsey))
      return 'EXEMPTOUTPUT'
    end

    case broker.deal.currency.name
    when 'GBP' then 'OUTPUT2'
    when 'EUR' then 'ECZROUTPUTSERVICES'
    when 'USD' then 'EXEMPTOUTPUT'
    end
  end

  def tax_rate_by_type
    @tax_rate_by_type ||= begin
      tax_rates = $xero.TaxRate.all(where: 'TaxType=="OUTPUT2" OR TaxType=="ECZROUTPUTSERVICES" OR TaxType=="EXEMPTOUTPUT"')
      tax_rates.index_by(&:tax_type)
    end
  end

  def logger
    @logger ||= begin
      log_dir = Rails.root + 'log/invoices'
      FileUtils.mkdir_p(log_dir)
      Logger.new("#{log_dir}/invoices-log-#{Time.current.strftime('%F--%H-%M-%S')}.log")
    end
  end
  
  def fetch_leads
    Lead.approved.not_deleted.not_invoiced.where('created_at < ?', Time.current.beginning_of_day)
        .includes(boat: [:manufacturer, :model, :currency, user: [:broker_info, deal: :currency, address: :country]]).to_a
  end

  def ensure_contacts(brokers)
    logger.info('Fetch xero contacts for brokers')
    contact_by_broker = {}

    maybe_linked_brokers = brokers.select { |b| b.broker_info.xero_contact_id.present? }
    maybe_linked_brokers.each_slice(10) do |brokers_slice| # slice in groups by 10 because Xero throws "Xeroizer::ObjectNotFound" if there are too many
      search_str = brokers_slice.map { |b| %(ContactID.ToString()=="#{b.broker_info.xero_contact_id}") }.join(' OR ')
      contacts = $xero.Contact.all(where: search_str)
      brokers_slice.each do |broker|
        contact_id = broker.broker_info.xero_contact_id
        contact = contacts.find { |c| c.contact_id == contact_id }
        contact_by_broker[broker] = contact if contact
        logger.warn("Cannot find Contact with contact_id=#{contact_id} for broker_id=#{broker.id} (#{broker.name})") if !contact
      end
    end
    logger.info("Found #{maybe_linked_brokers.size} contacts for brokers by contact_id")

    unlinked_brokers = brokers - contact_by_broker.keys
    if unlinked_brokers.any?
      logger.info("#{unlinked_brokers.size} brokers are not linked. Try to find contacts by name/contact_number")

      unlinked_brokers.each_slice(10) do |brokers_slice|
        search_str = brokers_slice.map { |b| %(ContactNumber=="#{b.id}" OR Name=="#{b.name}") }.join(' OR ')
        contacts = $xero.Contact.all(where: search_str)
        brokers_slice.each do |broker|
          broker_id = broker.id.to_s
          broker_name = broker.name
          contact = contacts.find { |c| c.contact_number == broker_id || c.name == broker_name }
          if contact
            contact_by_broker[broker] = contact
            broker.broker_info.update_column(:xero_contact_id, contact.id)
            logger.info("Found contact #{contact.id} for broker_id=#{broker_id} (#{broker_name})")
          end
        end
      end
    end

    unlinked_brokers = brokers - contact_by_broker.keys
    if unlinked_brokers.any?
      logger.info("#{unlinked_brokers.size} brokers are still not linked. Create contacts for them")

      new_contacts = unlinked_brokers.map { |broker| build_contact_for_broker(broker) }
      res = $xero.Contact.save_records(new_contacts)
      new_contacts.each do |c|
        logger.info("Contact created for broker_id=#{c.contact_number} (#{c.name})") if c.errors.blank?
        logger.error("Contact not created for broker_id=#{c.contact_number} (#{c.name}) errors=#{c.errors}") if c.errors.present?
      end
      raise 'Create Contacts Error' if !res

      unlinked_brokers.each do |broker|
        broker_id = broker.id.to_s
        contact = new_contacts.find { |c| c.contact_number == broker_id }
        broker.broker_info.update_column(:xero_contact_id, contact.contact_id)
        contact_by_broker[broker] = contact
      end
    end

    logger.info('All brokers are linked')

    contact_by_broker
  end

  def build_contact_for_broker(broker)
    contact = $xero.Contact.build
    contact.name = broker.name
    contact.contact_number = broker.id.to_s
    contact.first_name = broker.first_name
    contact.last_name = broker.last_name
    contact.email_address = broker.email
    contact.contact_status = 'ACTIVE'
    contact.tax_number = broker.broker_info.vat_number
    contact.is_customer = true
    contact.default_currency = broker.deal.currency.name
    if (address = broker.address)
      contact.add_address(type: 'POBOX',
                          line1: address.line1,
                          line2: address.line2,
                          line3: address.line3,
                          city: address.town_city,
                          region: address.county,
                          postal_code: address.zip,
                          country: address.country&.iso)
    end
    country_code = address.country&.country_code
    contact.add_phone(type: 'DEFAULT', area_code: country_code, number: broker.phone) if broker.phone.present?
    contact.add_phone(type: 'MOBILE', area_code: country_code, number: broker.mobile) if broker.mobile.present?
    contact
  end

  def invoice_branding_theme
    $xero.BrandingTheme.first(where: 'Name=="Lead Invoice"')
  end
end
