FactoryGirl.define do
  factory :boat, class: Boat do
    user
    association :category, factory: :boat_category
    boat_type
    currency
    engine_model
    engine_manufacturer
    drive_type
    country
    fuel_type
    vat_rate
    manufacturer
    model

    sequence(:name) { |n| "boat-name-#{n}" }
    sequence(:slug) { |n| "boat-slug-#{n}" }

    deleted_at nil
    new_boat false
    location 'United Kingdom, Chichester, West Sussex'
    geo_location "united kingdom, chichester, west sussex"
    year_built 2000
    price 100_000
    length_m 10
    sequence(:description) { |n| "Description #{n}" }
    sequence(:short_description) { |n| "Short Description #{n}" }
    secure_payment false
    offer_status "available"
    status :active
  end

  factory :boat_category do
    sequence(:name) { |n| "category-#{n}" }
  end

  factory :boat_type do
    sequence(:name) { |n| "boat_type_name-#{n}" }
    sequence(:slug) { |n| "boat_type_slug-#{n}" }
  end

  factory :currency do
    name 'USD'
    rate 1
    symbol '$'
    sequence(:position)

    trait :euro do
      name 'EUR'
      symbol '€'
      rate 1.2
    end
  end

  factory :fuel_type do
    sequence(:name) { |n| "fuel-#{n}" }
  end

  factory :vat_rate do
    sequence(:name) { |n| "vat-#{n}" }
  end

  factory :engine_model do
    sequence(:name) { |n| "engine-model-#{n}" }
  end

  factory :engine_manufacturer do
    sequence(:name) { |n| "engine_manufacturer-#{n}" }
    display_name nil
  end

  factory :drive_type do
    sequence(:name) { |n| "drive_type-#{n}" }
  end

  factory :model do
    manufacturer
    sequence(:name) { |n| "model-#{n}" }
    sequence(:slug) { |n| "model-slug-#{n}" }
    sailing 0
  end

  factory :manufacturer do
    sequence(:name) { |n| "manufacturer-#{n}" }
    sequence(:slug) { |n| "manufacturer-#{n}" }
  end

  factory :country do
    iso "US"
    name "United States of America"
    slug "united-states-of-america"
    country_code 1
    suspicious false
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@test.com" }
    sequence(:password) { |n| "user#{n}@test.com" }
    sign_in_count 1
    current_sign_in_at Time.current
    last_sign_in_at Time.current
    current_sign_in_ip '127.0.0.1'
    last_sign_in_ip '127.0.0.1'
    title "Mr."
    role 99 # admin
    first_name "first"
    last_name "last"
    sequence(:username) { |n| "user#{n}" }
    sequence(:slug) { |n| "user-#{n}" }
    email_confirmed true
    active true
    updated_by_admin true
  end

  factory :saved_search do
    user
    alert true
  end

  factory :user_alert do
    user
    favorites true
    saved_searches true
    suggestions true
    newsletter true
    enquiry true
  end
end
