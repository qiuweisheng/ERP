module ClientsHelper
  def client_options
    Client.all.collect { |client| [client.name, client.id] }
  end

  def client_options_all
    client_map = []
    client_map << ['全部', -1]
    client_map += Client.all.collect { |client| [client.name, client.id] }
  end
end
