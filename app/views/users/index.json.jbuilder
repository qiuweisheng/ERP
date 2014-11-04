json.array!(@users) do |user|
  json.extract! user, :id, :account_id, :name, :type
  json.url user_url(user, format: :json)
end
