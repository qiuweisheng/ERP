module RecordsHelper
  def record_type_options_for_normal
    [Record::TYPE_DISPATCH, Record::TYPE_RECEIVE, Record::TYPE_RETURN].collect do |type|
      [Record::RECORD_TYPES[type], type]
    end
  end
  
  def record_type_options_for_check
    [Record::TYPE_DAY_CHECK, Record::TYPE_MONTH_CHECK].collect do |type|
      [Record::RECORD_TYPES[type], type]
    end
  end
  
  def record_type_options_for_polish
    [Record::TYPE_DISPATCH, Record::TYPE_RECEIVE, Record::TYPE_APPORTION].collect do |type|
      [Record::RECORD_TYPES[type], type]
    end
  end
  
  def record_type_options
    Record::RECORD_TYPES.collect do |type, name|
      [name, type]
    end
  end

  def record_type_options_all
    record_type_map = []
    record_type_map << ['全部', -1]
    record_type_map += record_type_options
  end

  def user_options
    User.all.reject  { |user| is_admin_permission? user.permission }
            .collect { |user| [user.name, user.id] }
  end

  def user_options_all
    user_map = []
    user_map << ['全部', -1]
    user_map += user_options
  end

  def particpant_options_all
    particpant_map = []
    particpant_map << ['全部', '']
    particpant_map += Employee.all.collect do |employee|
      str = "Employee-#{employee.id}"
      [employee.name, str]
    end
    particpant_map += User.all.collect do |user|
      str = "User-#{user.id}"
      [user.name, str]
    end
  end

  def order_number_options_all
    order_num_map = []
    order_num_map << ['全部', '*']
    order_num_map << ['无单号', '']
    order_num_map += Record.order(:order_number).select{|record| record.order_number != ''}.collect do |record|
      unless record.order_number == ''
        [record.order_number, record.order_number]
      end
    end
    order_num_map.uniq
  end

  %w[product user employee client].each do |name|
    class_eval <<-END
      def #{name}_texts
        "#{name}".classify.constantize.all.collect do |#{name}|
          "\#{#{name}.serial_number}-\#{#{name}.name}"
        end
        .to_json
      end
    END
  end

  def participant_texts
    Record::PARTICIPANT_CLASS_NAMES.collect do |class_name|
      class_name.to_s.classify.constantize.all.collect do |row|
        if class_name == :user &&  row.permission < 2
          ''
        else
          "#{row.serial_number}-#{row.name}"
        end
      end.delete_if {|s| s == ''}
    end
    .flatten
    .to_json
  end
end
