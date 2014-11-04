module Account
  extend ActiveSupport::Concern

  module ClassMethods
    def auto_generate_account_id
      before_create :set_account_id
      before_update :reset_account_id
    end
  end

  private
    def set_account_id
      new_id = self.class.order('account_id DESC').first.try(:account_id)
      if new_id && new_id < self.class::MAX_ID
        self.account_id = new_id + 1
        return
      end
      # There may be some account that was deleted.
      # In that case, we can reuse those ID. Try to find one.
      new_id = self.class::MIN_ID - 1
      self.class.order('account_id').lazy.each do |account|
        if account.account_id - new_id > 1
          break
        else
          new_id = account.account_id
        end
      end
      if new_id >= self.class::MAX_ID
        self.errors.add(:account_id, "帐户达到最大值:#{self.class::MAX_ID}")
        return false
      end
      self.account_id = new_id + 1
    end

    def reset_account_id
      self.account_id = self.class.find(self.id).account_id
    end
end