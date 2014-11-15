module Statistics
  def day_transactions(today, user)
    transactions = { dispatch: [], receive: [] }
    # Dispatch
    self.transactions.select('product_id, weight').where('user_id = ? and date = ? and record_type = ?', user, today, 0).each do |record|
      transactions[:dispatch].push [record.product.name, record.weight]
    end
    # Receive
    self.transactions.select('product_id, weight').where('user_id = ? and date = ? and record_type = ?', user, today, 1).each do |record|
      transactions[:receive].push [record.product.name, record.weight]
    end
    transactions
  end

  def day_sum(today, user)
    dispatch_sum = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 0).sum('weight')
    receive_sum = self.transactions.where('user_id = ? and date = ? and record_type = ?', user, today, 1).sum('weight')
    [dispatch_sum, receive_sum]
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

  def yesterday_balance_as_host(today)
    latest_check_record = self.records.where('date < ? and record_type = ?', today, 2).order('created_at DESC').first
    if latest_check_record
      check_date = latest_check_record.date
      balance = self.records.where('participant_id = ? and date = ? and record_type = ?', self, check_date, 2).sum('weight')
    else
      check_date = self.records.order('created_at').first.date - 1
    end
    balance -= self.records.where('date > ? and date < ? and record_type = ?', check_date, today, 0).sum('weight')
    balance + self.records.where('date > ? and date < ? and record_type = ?', check_date, today, 1).sum('weight')
  end

  def day_sum_as_host(today)
    dispatch_sum = self.records.where('date = ? and record_type = ?', today, 0).sum('weight')
    receive_sum = self.records.where('date = ? and record_type = ?', today, 1).sum('weight')
    [dispatch_sum, receive_sum]
  end

  def actual_balance_as_host(today)
    self.records.where('participant_id = ? and date = ? and record_type = ?', self, today, 2).sum('weight')
  end
end

Employee.class_eval do
  include Statistics
end

class ReportsController < ApplicationController
  def day_detail
    @date = Date.parse('2014-11-13')
    @user = User.find_by(name: '003陈小艳')
    # Find all the participant TODAY
    participants = @user.records.select('participant_id, participant_type').where('date = ? and record_type != ?', @date, 2).group('participant_id').collect do |record|
      record.participant
    end
    # Get every participant's statistics
    @report = []
    participants.each do |participant|
      last_balance = participant.yesterday_balance(@date, @user)
      @report.push(name: participant.name, last_balance: last_balance)
      transactions = participant.day_transactions(@date, @user)
      balance = 0
      transactions[:dispatch].each do |name, value|
        balance += value
        @report.push(product_name: name, dispatch_value: value, balance: balance)
      end
      transactions[:receive].each do |name, value|
        balance -= value
        @report.push(product_name: name, receive_value: value, balance: balance)
      end
      dispatch_sum, receive_sum = participant.day_sum(@date, @user)
      balance = last_balance + dispatch_sum - receive_sum
      attr = {
          name: '合计',
          last_balance: last_balance,
          dispatch_value: dispatch_sum,
          receive_value: receive_sum,
          balance: balance,
          type: :sum
      }
      if participant.class == Employee
        actual_balance = participant.actual_balance(@date, @user)
        difference = balance - actual_balance
        attr[:actual_balance] = actual_balance
        attr[:depletion] = difference
      end
      @report.push attr
    end

    host_last_balance = @user.yesterday_balance_as_host(@date)
    host_dispatch_sum, host_receive_sum = @user.day_sum_as_host(@date)
    host_balance = host_last_balance - host_dispatch_sum + host_receive_sum
    host_actual_balance = @user.actual_balance_as_host(@date)
    @report.push(
        name: '本柜当日结余',
        last_balance: host_last_balance,
        dispatch_value: host_dispatch_sum,
        receive_value: host_receive_sum,
        balance: host_balance,
        difference: host_balance - host_actual_balance,
        actual_balance: host_actual_balance,
        type: :total_sum
    )
  end

  def day_summary
    @date = Date.parse('2014-11-13')
    @user = User.find_by(name: '003陈小艳')
    participants = @user.records.select('participant_id, participant_type').where('date = ? and record_type != ?', @date, 2).group('participant_id').collect do |record|
      record.participant
    end
    @report = []
    total_dispatch_sum = 0
    total_receive_sum = 0
    participants.each do |participant|
      last_balance = participant.yesterday_balance(@date, @user)
      dispatch_sum, receive_sum = participant.day_sum(@date, @user)
      total_dispatch_sum += dispatch_sum
      total_receive_sum += receive_sum
      balance = last_balance + dispatch_sum - receive_sum
      actual_balance = participant.actual_balance(@date, @user)
      attr = {
          name: participant.name,
          last_balance: last_balance,
          dispatch_sum: dispatch_sum,
          receive_sum: receive_sum,
          balance: balance,
          actual_balance: actual_balance
      }
      if participant.class == Employee
        attr[:depletion] = balance - actual_balance
      end
      @report.push attr
    end
    host_last_balance = @user.yesterday_balance_as_host(@date)
    host_dispatch_sum, host_receive_sum = @user.day_sum_as_host(@date)
    host_balance = host_last_balance - host_dispatch_sum + host_receive_sum
    host_actual_balance = @user.actual_balance_as_host(@date)
    @report.push(
        name: '本柜当日结余',
        last_balance: host_last_balance,
        dispatch_sum: host_dispatch_sum,
        receive_sum: host_receive_sum,
        balance: host_balance,
        difference: host_balance - host_actual_balance,
        actual_balance: host_actual_balance,
        type: :total_sum
    )
  end
end
