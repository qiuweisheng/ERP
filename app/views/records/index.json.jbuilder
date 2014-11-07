json.array!(@records) do |record|
  json.extract! record, :id, :record_type, :origin_id, :product_id, :weight, :count, :user_id, :client_id
  json.url record_url(record, format: :json)
end
