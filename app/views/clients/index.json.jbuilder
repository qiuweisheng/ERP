json.array!(@clients) do |client|
  json.extract! client, :id, :account_id, :name
  json.url client_url(client, format: :json)
end
