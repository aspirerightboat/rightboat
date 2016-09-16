class LeadRejectedToCancelled < ActiveRecord::Migration
  def change
    Lead.where(status: 'rejected').update_all(status: 'cancelled')
  end
end
