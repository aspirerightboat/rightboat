class FixSpecsNames < ActiveRecord::Migration
  def change
    Specification.rename('range', 'engine_range_nautical_miles')
    Specification.rename('ballast', 'ballast_kgs')
    Specification.rename('ballast_weight', 'ballast_kgs')
    Specification.rename('max_speed', 'max_speed_knots')
    Specification.rename('heads' ,'heads_count')
    Specification.rename('berths' ,'berths_count')
    Specification.rename('single_berths' ,'single_berths_count')
    Specification.rename('double_berths' ,'double_berths_count')
    Specification.rename('twin_berths' ,'twin_berths_count')
    Specification.rename('triple_berths' ,'triple_berths_count')
    Specification.rename('cabins' ,'cabins_count')
    Specification.rename('passengers', 'passengers_count')
    Specification.rename('cylinders', 'cylinders_count')
    Specification.rename('air_draft', 'air_draft_m')
    Specification.rename('winches', 'winches_count')
    Specification.rename('crew_cabins', 'crew_cabins_count')
    Specification.rename('crew_berths', 'crew_berths_count')

    Specification.rename('shorepower', 'shore_power')
    Specification.rename('tankage', 'engine_tankage')
    Specification.rename('sprayhood', 'spray_hood')
    Specification.rename('television', 'tv')
  end
end
