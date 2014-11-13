module RecordsHelper
  def type_texts
    Record::RECORD_TYPES.collect do |index, type|
      "#{index}-#{type}"
    end
    .to_json
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
