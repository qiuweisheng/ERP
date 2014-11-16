module Statistics
  def today_transactions(today, user=nil)
    transactions = { dispatch: [], receive: [] }
    condition = 'record_type = :record_type AND date = :date '
    condition << ' AND user_id = :user' if user
    params = { date: today, user: user }
    # Dispatch
    params[:record_type] = Record::TYPE_DISPATCH
    self.transactions.select('product_id, weight').where(condition, params).each do |record|
      transactions[:dispatch].push [record.product.name, record.weight]
    end
    # Receive
    params[:record_type] = Record::TYPE_RECEIVE
    self.transactions.select('product_id, weight').where(condition, params).each do |record|
      transactions[:receive].push [record.product.name, record.weight]
    end
    transactions
  end

  def today_sum(today, user=nil)
    condition = 'record_type = :record_type AND date = :date '
    condition << ' AND user_id = :user' if user
    params = { date: today, user: user }
    params[:record_type] = Record::TYPE_DISPATCH
    dispatch_sum = self.transactions.where(condition, params).sum('weight')
    params[:record_type] = Record::TYPE_RECEIVE
    receive_sum = self.transactions.where(condition, params).sum('weight')
    [dispatch_sum, receive_sum]
  end

  def yesterday_balance(today, user=nil)
    condition = 'record_type = :record_type AND date < :date'
    condition << ' AND user_id = :user' if user
    if [User, Employee].include? self.class
      check_type = self.class == User ? Record::TYPE_DAY_CHECK : Record::TYPE_MONTH_CHECK
      params = { date: today, user: user, record_type: check_type }
      balance = 0
      latest_check_record = self.transactions.where(condition, params).order('created_at DESC').first
      if latest_check_record
        check_date = latest_check_record.date
        if self.class == User
          condition = 'record_type = :record_type AND date = :date'
          condition << ' AND user_id = :user' if user
          balance = self.transactions.where(condition, params).sum('weight')
        end
      else
        check_date = self.transactions.order('created_at').first.date - 1.day
      end
      condition = 'record_type = :record_type AND date < :today AND date > :check_date'
      condition << ' AND user_id = :user' if user
      params = { today: today, check_date: check_date, user: user }
      params[:record_type] = Record::TYPE_DISPATCH
      balance += self.transactions.where(condition, params).sum('weight')
      params[:record_type] = Record::TYPE_RECEIVE
      balance -= self.transactions.where(condition, params).sum('weight')
    else
      params = { date: today, user: user }
      params[:record_type] = Record::TYPE_DISPATCH
      balance = self.transactions.where(condition, params).sum('weight')
      params[:record_type] = Record::TYPE_RECEIVE
      balance -= self.transactions.where(condition, params).sum('weight')
    end
    balance
  end

  def actual_balance(today, user=nil)
    condition = 'record_type = :record_type AND date = :date'
    condition << ' AND user_id = :user' if user
    params = { date: today, user: user, record_type: Record::TYPE_DAY_CHECK }
    self.transactions.where(condition, params).sum('weight')
  end
end

Client.class_eval do
  include Statistics

  def actual_balance(today, user=nil)
  end
end

Contractor.class_eval do
  include Statistics

  def actual_balance(today, user=nil)
  end
end

User.class_eval do
  include Statistics

  def yesterday_balance_as_host(today)
    condition = 'date < :date AND record_type = :record_type'
    params = { date: today, record_type: Record::TYPE_DAY_CHECK }
    latest_check_record = self.records.where(condition, params).order('created_at DESC').first
    balance = 0
    if latest_check_record
      check_date = latest_check_record.date
      condition = 'participant_id = :participant AND date = :date AND record_type = :record_type'
      params[:participant] = self
      balance = self.records.where(condition, params).sum('weight')
    else
      check_date = self.records.order('created_at').first.date - 1
    end
    condition = 'date > :check_date AND date < :today AND record_type = :record_type'
    params = { check_date: check_date, today: today, record_type: Record::TYPE_DISPATCH }
    balance -= self.records.where(condition, params).sum('weight')
    balance += self.transactions.where(condition, params).sum('weight')
    params[:record_type] = Record::TYPE_RECEIVE
    balance += self.records.where(condition, params).sum('weight')
    balance - self.transactions.where(condition, params).sum('weight')
  end

  def today_sum_as_host(today)
    condition = 'date = :date AND record_type = :record_type'
    params = { date: today, record_type: Record::TYPE_DISPATCH }
    other_dispatch_sum = self.transactions.where(condition, params).sum('weight')
    dispatch_sum = self.records.where(condition, params).sum('weight')
    params[:record_type] = Record::TYPE_RECEIVE
    other_receive_sum = self.transactions.where(condition, params).sum('weight')
    receive_sum = self.records.where(condition, params).sum('weight')
    dispatch_sum += other_receive_sum
    receive_sum += other_dispatch_sum
    [dispatch_sum, receive_sum, other_dispatch_sum, other_receive_sum]
  end

  def actual_balance_as_host(today)
    self.records.where('participant_id = ? and date = ? and record_type = ?', self, today, 2).sum('weight')
  end

  def today_participants(date)
    group = self.records.where('date = ? and record_type != ?', date, 2).group('participant_id')
              .collect  { |r| r.participant }
              .group_by { |p| p.class }
    [Employee, User, Contractor, Client]
      .map    { |c| group[c] }
      .select { |p| p }
      .flatten
  end
end

Employee.class_eval do
  include Statistics
end

class ReportsController < ApplicationController
  def day_detail
    @date = Date.parse('2014-11-13')
    @user = User.find_by(name: '003陈小艳')
    # Get every participant's statistics
    @report = []
    @user.today_participants(@date).each do |participant|
      last_balance = participant.yesterday_balance(@date, @user)
      balance = last_balance
      @report.push(name: participant.name, last_balance: last_balance, balance: balance)
      transactions = participant.today_transactions(@date, @user)
      transactions[:dispatch].each do |name, value|
        balance += value
        @report.push(product_name: name, dispatch_value: value, balance: balance)
      end
      transactions[:receive].each do |name, value|
        balance -= value
        @report.push(product_name: name, receive_value: value, balance: balance)
      end
      dispatch_sum, receive_sum = participant.today_sum(@date, @user)
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

    host_dispatch_sum, host_receive_sum, other_dispatch_sum, other_receive_sum = @user.today_sum_as_host(@date)
    @report.push(
        name: '本柜台',
        dispatch_value: other_receive_sum,
        receive_value: other_dispatch_sum,
        type: :sum
    )
    host_last_balance = @user.yesterday_balance_as_host(@date)
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
    @report = []
    total_dispatch_sum = 0
    total_receive_sum = 0
    @user.today_participants(@date).each do |participant|
      last_balance = participant.yesterday_balance(@date, @user)
      dispatch_sum, receive_sum = participant.today_sum(@date, @user)
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
    host_dispatch_sum, host_receive_sum, other_dispatch_sum, other_receive_sum = @user.today_sum_as_host(@date)
    @report.push(
        name: '本柜台',
        dispatch_sum: other_receive_sum,
        receive_sum: other_dispatch_sum,
        type: :sum
    )
    host_last_balance = @user.yesterday_balance_as_host(@date)
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

  def goods_distribution
    @date = Date.parse('2014-11-13')
  end

  def goods_in_employees
    @date = Date.parse('2014-11-13')
    employees = Record.where('date <= ? and participant_type = ?', @date, Employee.name).group('participant_id').collect do |record|
      record.participant
    end
    @report = []
    employees.each do |employee|
      sum = Record.where('date <= ? and participant_id and record_type = ?', @date, employee, 0).sum('weight')
    end
  end
end
