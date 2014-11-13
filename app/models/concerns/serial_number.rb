module SerialNumber
  extend ActiveSupport::Concern

  module ClassMethods
    def has_serial_number
      before_validation :set_serial_number, on: :create
      before_validation :reset_serial_number, on: :update
      validates_each :serial_number do |record|
        unless record.serial_number <= record.class::MAX_ID
          record.errors.add(:serial_number, "帐户达到最大值:#{record.class::MAX_ID}")
        end
      end
    end
  end

  def to_s
    serial_number and name ? "#{serial_number}-#{name}" : ''
  end

  protected
    def set_serial_number
      new_id = self.class.order('serial_number DESC').first.try(:serial_number)
      if new_id and new_id < self.class::MAX_ID
        self.serial_number = new_id + 1
        return
      end
      # There may be some account that was deleted.
      # In that case, we can reuse those ID. Try to find one.
      new_id = self.class::MIN_ID - 1
      self.class.order('serial_number').lazy.each do |account|
        if account.serial_number - new_id > 1
          break
        else
          new_id = account.serial_number
        end
      end
      self.serial_number = new_id + 1
    end

    def reset_serial_number
      self.serial_number = self.class.find(self.id).serial_number
    end
end