module Rightboat
  module Imports
    module Sources
      class BoatStream < Base
        BOATSTREAM_XML_PATH = "#{Rails.root}/import_data/boat_stream.xml"

        def enqueue_jobs
          @skip_thread_parsing_boat = true
          download_latest_file if Rails.env.production? # sftp access is configured for import.rightboat.com server only
          log "Parse file #{BOATSTREAM_XML_PATH}"
          Nokogiri::XML::SAX::Parser.new(BoatStreamParser.new(self, @party_ids)).parse_file(BOATSTREAM_XML_PATH)
        end

        def download_latest_file
          log 'connect to sftp'
          sftp = 'sshpass -e sftp -oBatchMode=no -b - rightboats@elba.boats.com'
          remote_file = `echo 'ls -t upload/*.xml' | #{sftp} | grep -v "sftp>" | head -n1`.strip

          log "Download file #{remote_file}"
          `echo "get -P #{remote_file} #{BOATSTREAM_XML_PATH}" | #{sftp}`
        end

        def self.validate_param_option
          {party_ids: [:presence, /\A\d+(, \d+)*\z/]}
        end

        class BoatStreamParser < Nokogiri::XML::SAX::Document
          def initialize(source, party_ids)
            @party_ids = party_ids.split(', ')
            @source = source
            @tree = []
            @country_id_by_iso = Country.pluck(:iso, :id).each_with_object({}) { |(iso, id), h| h[iso] = id }
          end

          def start_element(el, attr = [])
            @el = el
            @attr = attr
            @char = ''
            @tree.push(el)
            if el == 'VehicleRemarketing'
              @boat = SourceBoat.new
              @boat.images = []
              @boat.office = {address_attributes: {}}
            end
          end

          def characters(str)
            return if !@boat || str.blank?
            str.strip!
            @char << str
          end

          def end_element(el)
            process
            @tree.pop
            @attr_hash = nil
            if el == 'VehicleRemarketing' && @boat
              @source.enqueue_job(@boat)
              @boat = nil
            end
          end

          def process
            return if !@boat
            c = @char.to_s

            if @el == 'PartyID'
              if !@party_ids.include?(c)
                @boat = nil
                return
              end
            end

            if @tree.length > 2
              case @tree[-2]
              when 'DocumentIdentification'
                @boat.source_id = c if @el == 'DocumentID'
              when 'Price'
                if @el == 'ChargeAmount'
                  @boat.currency = get_attr('currencyID')
                  @boat.price = c
                end
              when 'Tax' then @boat.vat_rate = c if @el == 'TaxStatusCode'
              when 'SpecifiedOrganization' then @boat.office[:name] = c if @el == 'CompanyName'
              when 'PrimaryContact' then @boat.office[:contact_name] = c if @el == 'PersonName'
              when 'TelephoneCommunication' then @boat.office[:mobile] = c if @el == 'CompleteNumber'
              when 'FaxCommunication' then @boat.office[:fax] = c if @el == 'CompleteNumber'
              when 'URICommunication' then @boat.office[:email] = c if @el == 'CompleteNumber'
              when 'PostalAddress'
                addr = @boat.office[:address_attributes]
                case @el
                when 'LineOne' then addr[:line1] = c
                when 'LineTwo' then addr[:line2] = c
                when 'CityName' then addr[:town_city] = c
                when 'CountryID' then addr[:country_id] = @country_id_by_iso[c]
                when 'Postcode' then addr[:zip] = c
                when 'StateOrProvinceCountrySub-DivisionID' then addr[:county] = c
                end
              when 'ImageAttachmentExtended'
                @boat.images << c if @el == 'URI'
              when 'LocationAddress'
                case @el
                when 'CityName' then @boat.location = c if c != 'Unknown'
                when 'CountryID' then @boat.country = c
                end
              when 'VehicleRemarketingBoat'
                case @el
                when 'MakeString' then @boat.manufacturer = c
                when 'ModelYear' then @boat.year_built = c
                when 'SaleClassCode' then @boat.new_boat = c
                when 'Model' then @boat.model = c
                # when 'VehicleStockString' then
                when 'BoatCategoryCode' then @boat.category = c
                when 'TotalEnginePowerQuantity' then @boat.engine_horse_power = c
                when 'NumberOfBerthsNumeric' then @boat.berths = c
                when 'NumberOfCabinsNumeric' then @boat.cabins = c
                when 'NumberOfHeadsNumeric' then @boat.heads = c
                when 'GeneralBoatDescription' then @boat.description = read_description(c)
                # when 'BuilderName'
                when 'BoatName' then @boat.name = c
                when 'FuelTankCapacityMeasure' then @boat.tankage = c
                when 'HoldingTankCapacityMeasure' then @boat.holding_tanks = c
                when 'WaterTankCapacityMeasure' then @boat.fresh_water_tanks = c
                when 'CruisingSpeedMeasure' then @boat.cruising_speed = c
                when 'MaximumSpeedMeasure' then @boat.max_speed = c
                when 'BeamMeasure' then @boat.beam_m = to_meters(c, get_attr('unitCode'))
                end
              when 'BoatLengthGroup'
                case @el
                when 'BoatLengthCode' then @length_code = c
                when 'BoatLengthMeasure'
                  case @length_code
                  when 'Length At Water Line' then @boat.lwl_m = to_meters(c, get_attr('unitCode'))
                  when 'Length Overall', 'Nominal Length' then @boat.length_m = to_meters(c, get_attr('unitCode'))
                  end
                end
              when 'Hull'
                case @el
                when 'BoatHullMaterialCode' then @boat.hull_construction = c
                when 'BoatHullDesignCode' then @boat.hull_type = c
                end
              when 'Accommodation'
                case @el
                when 'AccommodationTypeCode' then @acc_type_code = c
                when 'Description' then @acc_desc = c
                when 'AccommodationCountNumeric'
                  case @acc_type_code
                  when 'Head' then @boat.heads = c
                  when 'Bathroom' then @boat.bathrooms = c
                  when 'SingleBerth' then @boat.single_berths = c
                  when 'DoubleBerth' then @boat.double_berths = c
                  when 'TwinBerth' then @boat.twin_berths = c
                  when 'Cabin' then @boat.cabins = c
                  when 'Other' && @acc_desc == 'Seating Capacity' then @boat.seating_capacity = c
                  end
                  @acc_type_code = c
                end
              when 'DraftMeasureGroup'
                case @el
                when 'DraftMeasure' then @boat.draft_m = to_meters(c, get_attr('unitCode'))
                # when 'BoatDraftCode' then
                end
              when 'VehicleRemarketingBoatLineItem'
                case @el
                when 'SalesStatus' then (@boat = nil; return) if c == 'Delete'
                # when 'Co-OpIndicator' then
                # when 'CentralIndicator' then
                end
              # when 'BoatClassGroup'
              when 'VehicleRemarketingEngine'
                case @el
                when 'MakeString' then @boat.engine_manufacturer = c
                when 'ModelYear' then @boat.engine_year = c
                when 'Model' then @boat.engine_model = c
                when 'BoatEngineTypeCode' then @boat.engine_type = c
                when 'FuelTypeCode' then @boat.fuel_type = c
                when 'BoatEngineLocationCode' then @boat.engine_location = c
                when 'TotalEngineHoursNumeric' then @boat.engine_hours = c
                when 'PropellerType' then @boat.propeller_type = c
                when 'DriveTransmissionDescription' then @boat.drive_transmission_description = c
                end
              when 'PowerMeasure'
                @boat.engine_horse_power ||= c if @el == 'MechanicalEnergyMeasure'
              when 'AdditionalDetailDescription'
                case @el
                when 'Title'
                  @last_title = c
                when 'Description'
                  if (url = c[/href="([^"]+)"/, 1])
                    @boat.source_url = url
                  end
                  @boat.description ||= ''
                  if @last_title != 'customContactInformation'
                    @boat.description << "<h3>#{@last_title}</h3>#{c}"
                  end
                end
              end
            end
          end

          def get_attr(name)
            @attr_hash ||= @attr.to_h
            @attr_hash[name]
          end

          def to_meters(value_str, unit)
            return value_str if unit == 'meter'
            value_str.to_f.ft_to_m.round(2).to_s if unit == 'feet'
          end

          def read_description(str)
            str = CGI.unescapeHTML(str)
            str.gsub!('&nbsp;', '')
            str
          end
        end

      end
    end
  end
end
