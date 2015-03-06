json.array!(@profiles) do |profile|
  json.extract! profile, :id, :key, :value
  json.url profile_url(profile, format: :json)
end
