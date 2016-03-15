class SplitMakeModelSavedSearch < ActiveRecord::Migration
  def up
    add_column :saved_searches, :manufacturer, :string
    add_column :saved_searches, :model, :string

    make_model_split_hash = {
        'OYSTER MARINE' => ['OYSTER MARINE', ''],
        'Cranchi 34 Zaffiro' => ['Cranchi', '34 Zaffiro'],
        'Boston Whaler' => ['Boston Whaler', ''],
        'Lagoon' => ['Lagoon', ''],
        'Wally Yachts' => ['Wally Yachts', ''],
        'Ribcraft 585' => ['Ribcraft', '585'],
        'Parker' => ['Parker', ''],
        'Beneteau' => ['Beneteau', ''],
        'Bayliner' => ['Bayliner', ''],
        'Sunseeker' => ['Sunseeker', ''],
        'Jeanneau (FR)' => ['Jeanneau (FR)', ''],
        'DISCOVERY' => ['DISCOVERY', ''],
        'Hallberg Rassy' => ['Hallberg Rassy', ''],
        'Sunseeker Martinique 39' => ['Sunseeker', 'Martinique 39'],
        'Beneteau SENSE 50 SHALLOW DRAFT' => ['Beneteau', 'SENSE 50 SHALLOW DRAFT'],
        'Quicksilver Activ 855' => ['Quicksilver', 'Activ 855'],
        'Colvic Victor 40' => ['Colvic', 'Victor 40'],
        'CAPELLI 1000 TEMPEST WA' => ['CAPELLI', '1000 TEMPEST WA'],
        'Suncoast 52' => ['Suncoast', '52'],
        'Teknocantieri Arrogance 50' => ['Teknocantieri', 'Arrogance 50'],
        'Carver European' => ['Carver', 'European'],
        'Calypso 28' => ['Calypso', '28'],
        'Sea Ray 455 Sundancer' => ['Sea Ray', '455 Sundancer'],
        'Lagoon 380 S2' => ['Lagoon', '380 S2'],
        'Bombigher' => ['Bombigher', ''],
        'Lagoon 380' => ['Lagoon', '380'],
        'Clearwater 2200 DC' => ['Clearwater', '2200 DC'],
        'Southerly 115' => ['Southerly', '115'],
        'Jeanneau Polycoque' => ['Jeanneau', 'Polycoque'],
        'Endurance 40' => ['Endurance', '40'],
        'Fairline Targa 47 GT/HT' => ['Fairline', 'Targa 47 GT/HT'],
        'Beneteau MONTE CARLO 47 HARD TOP' => ['Beneteau', 'MONTE CARLO 47 HARD TOP'],
    }

    SavedSearch.pluck(:id, :manufacturer_model).each do |ss_id, make_model|
      if make_model.present?
        maker, model = make_model_split_hash[make_model]
        SavedSearch.where(id: ss_id).update_all(['manufacturer = ?, model = ?', maker, model])
      end
    end

    remove_column :saved_searches, :manufacturer_model
  end
end
