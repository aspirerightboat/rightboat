module Rightboat
  module Xero
    class Invoicer

      def process_invoices(dry_run: false)
        logger.info('Started')
        all_leads = fetch_leads
        return true if all_leads.none?

        leads_by_broker = all_leads.group_by { |lead| lead.boat.user }
        brokers = leads_by_broker.keys
        logger.info("Found #{all_leads.size} leads for #{brokers.size} brokers")

        contact_by_broker = ContactsEnsurer.new(logger).run(brokers)
        invoicing_data = prepare_invoicing_data(contact_by_broker, leads_by_broker)
        logger.info('Generate invoices.csv')
        InvoicesCsvGenerator.new(invoicing_data, tax_rate_by_type).run
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
          i.vat_rate = tax_rate.effective_rate/100
          i.vat = (i.total_ex_vat * i.vat_rate).round(2)
          i.total = i.total_ex_vat + i.vat

          [i, xi, leads]
        end
      end

      def save_all(brokers, invoicing_data)
        Invoice.transaction do
          logger.info('Save invoices')
          invoicing_data.each do |invoice, xero_invoice, leads|
            invoice.save!
            xero_invoice.reference = invoice.id
            Lead.where(id: leads.map(&:id)).update_all(invoice_id: invoice.id, status: 'invoiced', updated_at: Time.current)
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

          invoicing_data.each do |invoice, xero_invoice, _leads|
            invoice.update(xero_invoice_id: xero_invoice.id)
          end
        end
      end

      def tax_type_for_broker(broker)
        if broker.country&.iso == 'GI' # Gibraltar
          return 'EXEMPTOUTPUT'
        elsif broker.country&.iso == 'GB' && broker.address.county.in?(%w(Jersey Guernsey))
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

      def invoice_branding_theme
        @invoice_branding_theme ||= $xero.BrandingTheme.first(where: 'Name=="Lead Invoice"')
      end
    end
  end
end
