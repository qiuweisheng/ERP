module Account
  extend ActiveSupport::Concern

  module ClassMethods
    def has_unique_account_id
      before_validation :set_account_id, on: :create
      before_validation :reset_account_id, on: :update
      validates_each :account_id do |record|
        unless record.account_id <= record.class::MAX_ID
          record.errors.add(:account_id, "帐户达到最大值:#{record.class::MAX_ID}")
        end
      end
    end
  end

  protected
    def set_account_id
      new_id = self.class.order('account_id DESC').first.try(:account_id)
      if new_id and new_id < self.class::MAX_ID
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
      self.account_id = new_id + 1
    end

    def reset_account_id
      self.account_id = self.class.find(self.id).account_id
    end
end