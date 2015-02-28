module ClientsHelper
  def client_options
    Client.all.collect { |client| [client.name, client.id] }
  end
end
