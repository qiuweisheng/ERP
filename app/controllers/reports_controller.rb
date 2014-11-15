module Statistics
  def day_statistics(today, user)
    statistics = { dispatch: {}, receive: {}, dispatch_total: 0, receive_total: 0, actual_total: 0 }
    # Dispatch
    self.transactions.select('product_id, weight').where('user_id = ? and date = ? and record_type = ?', user, today, 0).each do |record|
      statistics[:dispatch][record.product.name] = record.weight
    end
    # Receive
    self.transactions.select('product_id, weight').where('user_id = ? and date = ? and record_type = ?', user, today, 1).each do |record|
      statistics[:receive][record.product.name] = record.weight
    end
    # Total
    statistics[:dispatch_total] = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 0).sum('weight')
    statistics[:receive_total] = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 1).sum('weight')
    statistics[:actual_total] = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 2).sum('weight')
    statistics
  end

  def yesterday_balance(today, user)
    if [User, Employee].include? self.class
      check_type = self.class == User ? 2 : 3
      balance = 0
      latest_check_record = self.transactions.where('user_id = ? and date < ? and record_type = ?', user, today, check_type).order('created_at DESC').first
      if latest_check_record
        check_date = latest_check_record.date
        if self.class == User
          balance = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, check_date, check_type).sum('weight')
        end
      else
        check_date = self.transactions.order('created_at').first.date - 1
      end
      balance += self.transactions.where('user_id = ? and date > ? and date < ? and record_type = ?', user, check_date, today, 0).sum('weight')
      balance -= self.transactions.where('user_id = ? and date > ? and date < ? and record_type = ?', user, check_date, today, 1).sum('weight')
    else
      balance = self.transactions.where('user_id = ? and date < ? and record_type = ?', user, today, 0).sum('weight')
      balance -= self.transactions.where('user_id = ? and date < ? and record_type = ?', user, today, 1).sum('weight')
    end
    balance
  end

  def actual_balance(today, user)
    self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 2).sum('weight')
  end
end

Client.class_eval do
  include Statistics

  def actual_balance(today, user)
  end
end

Contractor.class_eval do
  include Statistics

  def actual_balance(today, user)
  end
end

User.class_eval do
  include Statistics
end

Employee.class_eval do
  include Statistics
end

class ReportsController < ApplicationController
  def day
    @date = Date.parse('2014-11-12')
    @user = User.find_by(name: '003陈小艳')
    # Find all the participant TODAY
    participants = @user.records.select('participant_id, participant_type').where('date = ? and record_type != ?', @date, 2).group('participant_id').collect do |record|
      record.participant
    end
    # Get every participant's statistics
    @report = []
    total_dispatch_sum = 0
    total_receive_sum = 0
    participants.each do |participant|
      last_balance = participant.yesterday_balance(@date, @user)
      @report.push(name: participant.name, last_balance: last_balance)
      statistics = participant.day_statistics(@date, @user)
      balance = 0
      dispatch_sum = 0
      statistics[:dispatch].each do |name, value|
        balance += value
        dispatch_sum += value
        total_dispatch_sum += value
        @report.push(product_name: name, dispatch_value: value, balance: balance)
      end
      receive_sum = 0
      statistics[:receive].each do |name, value|
        balance -= value
        receive_sum += value
        total_receive_sum += value
        @report.push(product_name: name, receive_value: value, balance: balance)
      end
      attr = {
          name: '合计',
          last_balance: last_balance,
          dispatch_value: dispatch_sum,
          receive_value: receive_sum,
          balance: last_balance + balance,
          type: :sum
      }
      if participant.class == Employee
        actual_balance = participant.actual_balance(@date, @user)
        difference = last_balance + balance - actual_balance
        attr[:actual_balance] = actual_balance
        attr[:depletion] = difference
      end
      @report.push attr
    end
    last_balance = @user.yesterday_balance(@date, @user)
    balance = total_dispatch_sum - total_receive_sum
    actual_balance = @user.actual_balance(@date, @user)
    @report.push(
        name: '本柜当日结余',
        last_balance: last_balance,
        dispatch_value: total_dispatch_sum,
        receive_value: total_receive_sum,
        balance: balance,
        difference: last_balance + balance - actual_balance,
        actual_balance: actual_balance,
        type: :total_sum
    )
  end
end
