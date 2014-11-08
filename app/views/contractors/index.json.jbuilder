json.array!(@contractors) do |contractor|
  json.extract! contractor, :id, :serial_number, :name
  json.url contractor_url(contractor, format: :json)
end
