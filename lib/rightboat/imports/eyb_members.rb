# encoding: utf-8

module Rightboat
  module Imports
    class EybMembers < Base
      USER_DATA_MAPPINGS = {
        'name' => :company_name,
        'email1' => :email,
        'phone' => :phone,
        'contact1' => :contact1,
        'contact2' => :contact2,
        'fax' => :fax,
        'website' => :company_weburl
      }

      ADDRESS_DATA_MAPPINGS = {
        'zipcode' => :zip,
        'country_name' => :country,
        'city' => :town_city,
        'adr1' => :line1,
        'adr2' => :line2,
        'adr3' => :line3
      }

      def initialize
        @use_proxy = false
        @_agent = Mechanize.new
        @_agent.user_agent_alias = 'Windows IE 7'
        @_agent.ssl_version = 'SSLv3'
        @_agent.keep_alive = false
        @_agent.max_history = 3
        @_agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
        @_agent.read_timeout = 120
        @_agent.open_timeout = 120

        @members = []
        @thread_count = 1

        @_writer_mutex = Mutex.new
        @_queue_mutex = Mutex.new
        @_queue = Queue.new
      end

      def run
        _end_q = false
        threads = []

        @thread_count.to_i.times do
          threads << Thread.new do
            while true
              job = nil
              @_queue_mutex.synchronize do
                job = @_queue.pop(true) rescue nil
              end

              break if @exit_worker || (_end_q && !job)
              unless job
                sleep 3
                next
              end

              begin
                member = process_job(job)
              rescue Exception => e
                puts e
              end

              @_writer_mutex.synchronize do
                if member && @members.select { |x| x[:broker_id] == member[:broker_id] }.empty?
                  @members << member
                end
              end
            end
          end
        end

        enqueue_jobs
        _end_q = true

        threads.each(&:join)
        process_result
      end

      def enqueue_jobs
        #doc = get('http://www.eyb.fr/exports/RGB/out/auto/RGB_Out.xml')
        doc = Nokogiri::XML(File.read("/Users/chen/work/rightboat/tmp/data.xml"))
        doc.search("//AD").each do |ad|
          job = { ad: ad }
          enqueue_job(job)
        end
      end

      def process_job(job)
        doc = job[:ad]
        member = {
          role: 'COMPANY',
          source: 'eyb',
          active: true,
          updated_by_admin: true,
          address_attributes: {}
        }

        doc.children.each do |node|
          key = node.name.gsub('An_', '').downcase
          val = node.children.text

          if key == 'broker'
            member[:broker_id] = val
          elsif key =~ /^deal/i
            key = key.gsub(/deal_/, '')
            if attr = USER_DATA_MAPPINGS[key]
              member[attr.to_sym] = val
            elsif attr = ADDRESS_DATA_MAPPINGS[key]
              member[:address_attributes][attr.to_sym] = val
            end
          end
        end

        member
      end

      private

      def process_result
        User.where(source: 'eyb').active.update_all(active: false)
        Import.where(import_type: 'eyb').active.update_all(active: false)

        @members.each do |member|
          member[:address_attributes][:country] = 'UK' if member[:address_attributes][:country] = 'Tortola'
          unless member[:company_weburl].blank?
            member[:company_weburl] = 'http://' + member[:company_weburl] unless member[:company_weburl] =~ /http/
          end

          if member[:email] =~ /,/
            member[:email] = member[:email].split(/,/).first.strip
          elsif member[:email] =~ /;/
            member[:email] = member[:email].split(/;/).first.strip
          end

          if user = User.find_by(email: member[:email])
            member[:broker_ids] = user.broker_ids << member[:broker_id] unless user.broker_ids.include?(member[:broker_id])
            user.update(member.except(:broker_id))
          else
            password = Devise.friendly_token[0,20]
            member[:password] = password
            member[:password_confirmation] = password
            member[:username] = member[:company_name].underscore.gsub(/[^\w@.-]/, '_')
            member[:broker_ids] = [member[:broker_id]]
            user = User.create(member.except(:broker_id))
          end

          imports = user.imports.where(import_type: 'eyb')

          user.broker_ids.each do |broker_id|
            unless import = imports.select { |x| x.param['broker_id'] == broker_id.to_s }.first
              import = user.imports.create(import_type: 'eyb', active: false, param: { 'broker_id' => broker_id })
            else
              import.update(active: true)
            end
          end
        end
      end
    end
  end
end