class AddLastLeadTrailToEnquiry < ActiveRecord::Migration
  def up
    add_column :enquiries, :last_lead_trail_id, :integer
    add_index :enquiries, :last_lead_trail_id

    Enquiry.includes(:lead_trails).each do |lead|
      last_lead = lead.lead_trails.max_by(&:id)

      if last_lead
        lead.update_column(:last_lead_trail_id, last_lead.id)
      else
        puts "lead ##{lead.id} has no lead_trails. skip"
      end
    end
  end
end
