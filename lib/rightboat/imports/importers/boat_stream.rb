module Rightboat
  module Imports
    module Importers
      class BoatStream < ImporterBase
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
            @country_id_by_iso = Country.pluck(:iso, :id).to_h
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
              @engines_count = 0
            end
          end

          def characters(str)
            return if !@boat || str.blank?
            @char << str
          end

          def end_element(el)
            process
            @tree.pop
            @attr_hash = nil
            if el == 'VehicleRemarketing' && @boat
              @boat.engine_count = @engines_count if @engines_count > 0
              @source.enqueue_job(@boat)
              @boat = nil
            end
          end

          def process
            return if !@boat

            # @cur_proc.()

            if @tree[0] == 'ProcessVehicleRemarketing'
              case @tree[1]
              when 'ApplicationArea'
                case @tree[2]
                when 'Sender'
                  case @tree[3]
                  when 'LogicalID' # IMT
                  when 'TaskID' # RIGHT.BOATS Inventory Sync
                  when 'CreatorNameCode' # IMT Exporter
                  when 'SenderNameCode' # IMT
                  end
                when 'CreationDateTime' # eg. 2015-12-07T20:01:24-08:00
                when 'BODID' # imt:764321dd-3af0-4c5e-8610-d5d83c768d24
                when 'Destination'
                  case @tree[4]
                  when 'DestinationNameCode' # RIGHTBOATS
                  end
                end
              when 'ProcessVehicleRemarketingDataArea'
                case @tree[2]
                when 'Process' # (acknowledgeCode="Always")
                when 'VehicleRemarketing'
                  case @tree[3]
                  when 'VehicleRemarketingHeader'
                    case @tree[4]
                    when 'DocumentDateTime' # eg. 2015-12-07T20:02:19-08:00
                    when 'DocumentIdentificationGroup'
                      case @tree[5]
                      when 'DocumentIdentification'
                        case @tree[6]
                        when 'DocumentID' then @boat.source_id = chars # 4780518
                        end
                      end
                    end
                  when 'VehicleRemarketingBoatLineItem'
                    case @tree[4]
                    when 'PricingABIE'
                      case @tree[5]
                      when 'PriceHideIndicator' # true | false
                      when 'Price'
                        case @tree[6]
                        when 'ChargeAmount'
                          @boat.currency = get_attr('currencyID') # eg. USD
                          @boat.price = chars # eg. 19999
                        end
                      end
                    when 'Tax'
                      case @tree[5]
                      when 'TaxTypeCode' # N/A
                      when 'TaxStatusCode' then @boat.vat_rate = chars # Paid | Not Paid | Not Applicable | Other
                      end
                    when 'DealerParty'
                      case @tree[5]
                      when 'PartyID'
                        @boat = nil if @party_ids.exclude?(chars)
                      when 'SpecifiedOrganization'
                        case @tree[6]
                        when 'CompanyName' then @boat.office[:name] = chars # eg. Essex Clarke & Carter
                        when 'PrimaryContact'
                          case @tree[7]
                          when 'TypeCode' # DLR | SLSRP
                          when 'TelephoneCommunication'
                            case @tree[8]
                            when 'ChannelCode' # phone
                            when 'CompleteNumber' then @boat.office[:mobile] = chars if @el == 'CompleteNumber' # eg. +44 (0)1634 571605
                            end
                          when 'FaxCommunication'
                            case @tree[8]
                            when 'ChannelCode' # fax
                            when 'CompleteNumber' then @boat.office[:fax] = chars if @el == 'CompleteNumber' # eg. +44 (0)1621 785560
                            end
                          when 'URICommunication'
                            case @tree[8]
                            when 'ChannelCode' # email
                            when 'CompleteNumber' then @boat.office[:email] = chars if @el == 'CompleteNumber' # regular email
                            end
                          when 'PrimaryContact' then @boat.office[:contact_name] = chars if @el == 'PersonName' # eg. Neil Tasker
                          end
                        when 'PostalAddress'
                          addr = @boat.office[:address_attributes]
                          case @el
                          when 'LineOne' then addr[:line1] = chars
                          when 'LineTwo' then addr[:line2] = chars
                          when 'CityName' then addr[:town_city] = chars
                          when 'CountryID' then addr[:country_id] = @country_id_by_iso[chars] # eg. GB
                          when 'Postcode' then addr[:zip] = chars
                          when 'StateOrProvinceCountrySub-DivisionID' then addr[:county] = chars
                          end
                        end
                      end
                    when 'ImageAttachmentExtended'
                      case @el
                      when 'URI' then @boat.images << chars
                      # when ImageLastModifiedDateTime # eg. 2014-08-07T03:04:47-08:00
                      # when UsagePreference # int number 0..n
                      # when ImageAttachmentTitle # some title, not empty
                      end
                    when 'LastModificationDate' # eg. 2015-11-25
                    when 'ItemReceivedDate' # eg. 2014-08-07
                    when 'Location'
                      case @tree[5]
                      when 'LocationAddress'
                        case @el
                        when 'CityName' then @boat.location = chars if chars != 'Unknown' # eg. Chatham | Gwynedd, LL57 4HN | Unknown
                        when 'CountryID' then @boat.country = chars # eg. GB
                        # when 'StateOrProvinceCountrySub-DivisionID'
                        # when 'Postcode'
                        end
                      end
                    when 'VehicleRemarketingBoat'
                      case @tree[5]
                      when 'MakeString' then @boat.manufacturer = chars # eg. Yanmar
                      when 'ModelYear' then @boat.year_built = chars # eg. 1990
                      when 'SaleClassCode' then @boat.new_boat = chars # New | Used
                      when 'Model' then @boat.model = chars # 2GM20 | Sun Odyssey 439 | ...
                      # when 'BoatLengthGroup' # contains
                      case @tree[5]
                      when 'BoatLengthCode' then @length_code = chars
                      when 'BoatLengthMeasure'
                        case @length_code
                        when 'Nominal Length' then @boat.length_m = to_meters(chars, get_attr('unitCode'), false) # sometimes Length Overall is empty so put this value there
                        when 'Length At Water Line' then @boat.lwl_m = to_meters(chars, get_attr('unitCode'), false)
                        when 'Length Overall' then @boat.length_m = to_meters(chars, get_attr('unitCode'), false)
                        when 'Length Of Deck' then @boat.length_on_deck = to_meters(chars, get_attr('unitCode'))
                        end
                      end
                      when 'BeamMeasure' then @boat.beam_m = to_meters(chars, get_attr('unitCode'), false)
                      when 'DraftMeasureGroup'
                        case @tree[6]
                        when 'DraftMeasure' then @draft_measure = to_meters(chars, get_attr('unitCode'))
                        when 'BoatDraftCode'
                          case @tree[7]
                          when 'Max Draft' then @boat.draft_max = @draft_measure
                          when 'Drive Up' then @boat.drive_up = @draft_measure
                          end
                        end
                      when 'FuelTankCapacityMeasure' then @boat.fuel_tanks_capacity = to_liters(chars, get_attr('unitCode'))
                      when 'WaterTankCapacityMeasure' then @boat.water_tanks_capacity = to_liters(chars, get_attr('unitCode'))
                      when 'DisplacementMeasure' then @boat.displacement_kgs = to_kilograms(chars, get_attr('unitCode'))
                      when 'BoatCategoryCode' then @boat.boat_type = chars # Power | Sail
                      # when 'BoatClassGroup' # Ketch true | Cruisers false | ...
                      when 'BoatKeelCode' then @boat.keel_type = chars # Full Keel | Fin Keel | Lifting Keel | Winged Keel | Other | Twin Keel | Bulb Keel | Canting Keel
                      when 'CruisingSpeedMeasure' then @boat.cruising_speed = to_knots(chars, get_attr('unitCode'))
                      when 'TotalEnginePowerQuantity' then @boat.engine_horse_power = chars # eg. 900.0
                      when 'GeneralBoatDescription'
                        @boat.description = @boat.short_description = chars
                        # when 'BuilderName' # contains extended maker name like in MakeString or nil
                      when 'DesignerName' then @boat.designer = chars # eg. J&J Design
                      when 'BoatName' then @boat.name = chars
                      when 'Hull'
                        case @tree[6]
                        when 'BoatHullMaterialCode' then @boat.hull_material = chars
                        when 'BoatHullDesignCode' then @boat.hull_type = chars # Monohull | Deep Vee | RIB | Displacement | Catamaran | Planing | Modified Vee | Semi Displacement | Flat | Pontoon | Trimaran | Tunnel
                        end
                      when 'MaximumSpeedMeasure' then @boat.max_speed = to_knots(chars, get_attr('unitCode'))
                      when 'NumberOfBerthsNumeric' then @boat.berths = chars # eg. 7
                      when 'NumberOfHeadsNumeric' then @boat.heads = chars # eg. 7
                      when 'Accommodation'
                        case @tree[6]
                        when 'AccommodationTypeCode' then @acc_type_code = chars
                        when 'Description' then @acc_desc = chars
                        when 'AccommodationCountNumeric'
                          case @acc_type_code
                          when 'Head' then @boat.heads = chars
                          when 'Bathroom' then @boat.bathrooms = chars
                          when 'SingleBerth' then @boat.single_berths = chars
                          when 'DoubleBerth' then @boat.double_berths = chars
                          when 'TwinBerth' then @boat.twin_berths = chars
                          when 'Cabin' then @boat.cabins = chars
                          when 'Other' && @acc_desc == 'Seating Capacity' then @boat.seating_capacity = chars
                          end
                        end
                      when 'DryWeightMeasure' then @boat.dry_weight = to_kilograms(chars, get_attr('unitCode'))
                      when 'NumberOfCabinsNumeric' then @boat.cabins = chars # eg. 7
                      # when 'VehicleStockString' # Ashore Larkmans | PB1201 | DS | Sales Area | ...
                      when 'BallastWeightMeasure' then @boat.ballast_weight = to_kilograms(chars, get_attr('unitCode'))
                      when 'HoldingTankCapacityMeasure' then @boat.holding_tanks_capacity = to_liters(chars, get_attr('unitCode'))
                      when 'BridgeClearanceMeasure' then @boat.bridge_clearance = to_meters(chars, get_attr('unitCode'))
                      when 'CabinHeadroomMeasure' then @boat.cabin_headroom = to_meters(chars, get_attr('unitCode'))
                      when 'DeadriseMeasure' then @boat.deadrise = to_degrees(chars, get_attr('unitCode'))
                      when 'MaximumNumberOfPassengersNumeric' then @boat.passengers = chars
                      when 'FreeBoardMeasure' then @boat.free_board = to_meters(chars, get_attr('unitCode'))
                      end
                    when 'VehicleRemarketingEngineLineItem'
                      case @tree[5]
                      when 'VehicleRemarketingEngine' # could be 0..4 VehicleRemarketingEngine items for one boat
                        @engines_count += 1
                        case @tree[6]
                        when 'MakeString' then @boat.engine_manufacturer = chars
                        when 'Model' then @boat.engine_model = chars
                        when 'BoatEngineTypeCode' then @boat.engine_type = chars # Inboard | Outboard | Outboard 4 Stroke | Inboard/Outboard | Outboard 2 Stroke | Electric | V Drive | Other
                        when 'FuelTypeCode' then @boat.fuel_type = chars # diesel | unleaded | Other | electric
                        when 'TotalEngineHoursNumeric' then @boat.engine_hours = chars # always int value > 0
                        when 'PropellerType' then @boat.propeller_type = chars # 3 Blade, Folding | Stainless Steel | Bronze, Folding | ...
                        when 'DriveTransmissionDescription' then @boat.drive_transmission_description = chars # Direct | Sail | Stern | Other | Surface | Pod | V | Jet
                        when 'PowerMeasure' # contains MechanicalEnergyMeasure
                        when 'MechanicalEnergyMeasure'
                          @boat.engine_horse_power ||= chars # This value is smaller or equal TotalEnginePowerQuantity
                        when 'ModelYear' then @boat.engine_year = chars
                        when 'BoatEngineLocationCode' then @boat.engine_location = chars # Port | Starboard
                        end
                      end
                    when 'SalesStatus'
                      case chars
                      when 'Active' then @boat.offer_status = 'available'
                      when 'Sale Pending' then @boat.offer_status = 'under_offer'
                      when 'Sold' then @boat.offer_status = 'sold'
                      when 'Delete' then @boat = nil
                      end
                    # when 'Co-OpIndicator' # true | false
                    # when 'CentralIndicator' # true | false
                    when 'AdditionalDetailDescription'
                      case @tree[5]
                      when 'Title'
                        @last_title = chars.titleize
                      when 'Description'
                        @boat.description ||= ''
                        return if @last_title == 'Custom Contact Information'
                        return if @last_title == 'Disclaimer'
                        return if @last_title == 'Important Information'
                        return if @last_title == 'Prueba'
                        return if @last_title == 'Cláusula De Responsabilidad'
                        @boat.description << "<h3>#{@last_title}</h3>#{chars}"
                      end
                    # when 'LastModificationTime' # eg. 05:55:11
                    when 'Marketing'
                      case @tree[5]
                      when 'ProgramIdDescription' # Newly listed and exclusive!!
                      when 'OpportunityTypeString' # PUBLIC | TagLine | SalesMessage | PERSONAL
                      end
                    when 'AdditionalMedia'
                      case @tree[5]
                      when 'MediaSourceURI' # http://marinabenalnautic.com/barcos-ocasion/fountaine-pajot-eleuthera-60
                      when 'MediaTypeString' # External Link | Embedded Video | Video Brochure
                      when 'MediaLastModifiedDateTime' # 2013-05-17T08:52:57-08:00
                      end
                    when 'SoldDate' # eg. 2015-12-07
                    when 'NotForSaleInCountry'
                      case @tree[5]
                      when 'CountryCode' # eg. US
                      end
                    when 'RemarketingWarranty'
                      case @tree[5]
                      when 'WarrantyExpirationDate' # eg. 2016-05-01
                      end
                    end
                  end
                end
              end
            end
          end

          def chars
            @char.to_s.strip
          end

          def get_attr(name)
            @attr_hash ||= @attr.to_h
            @attr_hash[name]
          end

          def to_meters(value_str, unit, include_unit = true)
            res = case unit
                  when 'meter' then value_str
                  when 'feet' then value_str.to_f.ft_to_m.round(2).to_s
                  else (@source.log_warning "Unknown unit: #{unit}"; return value_str)
                  end
            res && include_unit ? "#{res} meters" : res
          end

          def to_liters(value_str, unit)
            res = case unit
                  when 'liter' then value_str
                  when 'gallon' then value_str.to_f.gallons_to_liters.round(2).to_s
                  else (@source.log_warning "Unknown unit: #{unit}"; return value_str)
                  end
            "#{res} liters" if res
          end

          def to_knots(value_str, unit)
            res = case unit
                  when 'knots' then value_str
                  when 'miles per hour' then value_str.to_f.kph_to_knots.round(2).to_s
                  when 'kilometers per hour' then value_str.to_f.mph_to_knots.round(2).to_s
                  else (@source.log_warning "Unknown unit: #{unit}"; return value_str)
                  end
            "#{res} knots"
          end

          def to_kilograms(value_str, unit)
            res = case unit
                  when 'kilogram' then value_str
                  when 'pound' then value_str.to_f.pounds_to_kilograms.round(2).to_s
                  else (@source.log_warning "Unknown unit: #{unit}"; return value_str)
                  end
            "#{res} kilograms"
          end

          def to_degrees(value_str, unit)
            res = case unit
                  when 'degree' then value_str
                  else (@source.log_warning "Unknown unit: #{unit}"; return value_str)
                  end
            "#{res} degrees"
          end
        end

      end
    end
  end
end
