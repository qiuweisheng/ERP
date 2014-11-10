module RecordsHelper
  def select_options_for_record_type
    [['收货', 0], ['发货', 1], ['盘点', 2]]
  end

  def text_for_record_type(type)
    pair = select_options_for_record_type.rassoc(type)
    pair.try(:first) || type
  end

  def select_options_for_product
    Product.all.collect do |product|
      ["#{product.serial_number}-#{product.name}", product.id]
    end
  end

  def select_options_for_user
    User.all.select(&->(user){ user.permission > 1 }).collect do |user|
      ["#{user.serial_number}-#{user.name}", user.id]
    end
  end

  def select_options_for_employee
    Employee.all.collect do |employee|
      ["#{employee.serial_number}-#{employee.name}", employee.id]
    end
  end

  def select_options_for_client
    Client.all.collect do |client|
      ["#{client.serial_number}-#{client.name}", client.id]
    end
  end

  def select_options_for_participant
    options = User.all.select(&->(user){ user.permission > 1 }).collect do |user|
      %W[#{user.serial_number}-#{user.name} User::#{user.id}]
    end
    options.concat(Employee.all.collect do |employee|
      %W[#{employee.serial_number}-#{employee.name} Employee::#{employee.id}]
    end)
    options.concat(Client.all.collect do |client|
      %W[#{client.serial_number}-#{client.name} Client::#{client.id}]
    end)
    options.concat(Contractor.all.collect do |contractor|
      %W[#{contractor.serial_number}-#{contractor.name} Contractor::#{contractor.id}]
    end)
  end
end
