json.array!(@departments) do |department|
  json.extract! department, :id, :account_id, :name
  json.url department_url(department, format: :json)
end
