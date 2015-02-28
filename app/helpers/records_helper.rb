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
  
  def user_options
    User.all.reject  { |user| is_admin_permission? user.permission }
            .collect { |user| [user.name, user.id] }
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
        "#{row.serial_number}-#{row.name}"
      end
    end
    .flatten
    .to_json
  end
end
