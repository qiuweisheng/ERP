module State
  extend ActiveSupport::Concern
  STATE_VALID   = 0
  STATE_SHADOW = 1
  
  def try_destroy
    if (self.respond_to? :records and self.records.count > 0) or (self.respond_to? :transactions and self.transactions.count > 0)
      self.state = STATE_SHADOW
      self.serial_number = nil if self.respond_to? :serial_number
      self.save(validate: false)
      false
    else
      self.destroy
      true
    end
  end
end