module RecordsHelper
  def select_options_for_record_type
    [['收货', 0], ['发货', 1], ['盘点', 2]]
  end

  def text_for_record_type(type)
    pair = select_options_for_record_type.rassoc(type)
    pair.try(:first) || type
  end

  def select_options_for_product
    options = []
    Product.all.each do |product|
      options << [product.name, product.id]
    end
    options
  end

  def select_options_for_user
    options = []
    User.all.each do |user|
      unless [0,1].include? user.permission
        options << ["#{user.serial_number}-#{user.name}", user.id]
      end
    end
    options
  end

  def select_options_for_client
    options = []
    User.all.each do |user|
      unless [0,1].include? user.permission
        options << %W[#{user.serial_number}-#{user.name} User::#{user.id}]
      end
    end
    Employee.all.each do |employee|
      options << %W[#{employee.serial_number}-#{employee.name} Employee::#{employee.id}]
    end
    Client.all.each do |client|
      options << %W[#{client.name} Client::#{client.id}]
    end
    options
  end
end
