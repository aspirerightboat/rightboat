module Rightboat
  module Xero
    class ContactsEnsurer
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def run(brokers)
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

    end
  end
end
