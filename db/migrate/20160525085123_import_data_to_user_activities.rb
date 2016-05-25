class ImportDataToUserActivities < ActiveRecord::Migration
  def up
    create_table :temp_user_activities do |t|
      t.integer :user_id, default: nil
      t.string :user_email, default: nil
      t.string :kind
      t.integer :boat_id, default: nil
      t.integer :lead_id, default: nil
      t.text :meta_data, default: nil
      t.timestamps
    end

    # import leads into table
    ActiveRecord::Base.connection.execute("INSERT INTO temp_user_activities (user_id, user_email, kind, boat_id, lead_id, meta_data, created_at, updated_at )\
      SELECT user_id, NULL, 'lead', NULL, id, NULL, created_at, updated_at FROM leads WHERE user_id IS NOT NULL")

    # import searches into temp user_activities
    ActiveRecord::Base.transaction do
      SavedSearch.all.each do |ss|
        user_activity = UserActivity.create_search_record(hash: ss.to_succinct_search_hash, user: ss.user)
        user_activity.update(created_at: ss.created_at, updated_at: ss.updated_at)
      end
    end

    # import user_activities into temp table
    ActiveRecord::Base.connection.execute("INSERT INTO temp_user_activities (user_id, user_email, kind, boat_id, lead_id, meta_data, created_at, updated_at )\
      SELECT user_id, user_email, kind, boat_id, lead_id, meta_data, created_at, updated_at FROM user_activities WHERE kind IN ('boat_view', 'search')")

    UserActivity.delete_all

    # Compile all data, sort it and place back to user_activities
    ActiveRecord::Base.connection.execute("INSERT INTO user_activities (user_id, user_email, kind, boat_id, lead_id, meta_data, created_at, updated_at )\
      SELECT user_id, user_email, kind, boat_id, lead_id, meta_data, created_at, updated_at FROM temp_user_activities ORDER BY created_at ASC")

    drop_table :temp_user_activities
  end
end
