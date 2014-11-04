module Account
  extend ActiveSupport::Concern

  private
    def set_account_id
      new_id = self.class::MIN_ID - 1
      self.class.order('account_id').lazy.each do |account|
        if account.account_id - new_id > 1
          break
        else
          new_id = account.account_id
        end
      end
      new_id += 1
      if new_id > self.class::MAX_ID
        self.errors.add(:account_id, "帐户达到最大值:#{self.class::MAX_ID}")
        return false
      end
      self.account_id = new_id
    end

    def reset_account_id
      self.account_id = self.class.find(self.id).account_id
    end
end