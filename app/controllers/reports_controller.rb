module Statistics
  def today_transactions(today, user: nil)
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

  def today_sum(today, user: nil)
    condition = 'record_type = :record_type AND date = :date'
    condition << ' AND user_id = :user' if user
    params = { date: today, user: user }
    params[:record_type] = Record::TYPE_DISPATCH
    dispatch_sum = self.transactions.where(condition, params).sum('weight')
    params[:record_type] = Record::TYPE_RECEIVE
    receive_sum = self.transactions.where(condition, params).sum('weight')
    [dispatch_sum, receive_sum]
  end

  def actual_balance(today, user: nil)
    condition = 'record_type = :record_type AND date = :date'
    condition << ' AND user_id = :user' if user
    params = { date: today, user: user, record_type: Record::TYPE_DAY_CHECK }
    if self.transactions.where(condition, params).count > 0
      self.transactions.where(condition, params).sum('weight')
    else
      yesterday_balance(today, user: user)
    end
  end

  def yesterday_balance(today, user: nil, check_type: nil)
    condition = 'record_type = :record_type AND date < :date'
    condition << ' AND user_id = :user' if user
    if self.class == Employee
      check_type = Record::TYPE_MONTH_CHECK unless check_type
      params = { date: today, user: user, record_type: check_type }
      balance = 0
      check_date = self.transactions.where(condition, params).order('created_at DESC').first.try(:date)
      if check_date
        condition = 'record_type = :record_type AND date = :date'
        condition << ' AND user_id = :user' if user
        params[:date] = check_date
        balance = self.transactions.where(condition, params).sum('weight')
      else
        first_record = self.transactions.order('created_at').first
        check_date = (first_record ? first_record.date : Time.now.to_date) - 1.day
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
end

Client.class_eval do
  include Statistics

  def actual_balance(today, user: nil)
  end

  # alias original_today_transactions today_transactions
  # def today_transactions(today, user: nil)
  #   transactions = original_today_transactions(today, user: user)
  #   { dispatch: transactions[:receive], receive: transactions[:dispatch] }
  # end
  #
  # alias original_yesterday_balance yesterday_balance
  # def yesterday_balance(today, user: nil)
  #   - original_yesterday_balance(today, user: user)
  # end
  #
  # alias original_today_sum today_sum
  # def today_sum(today, user: nil)
  #   dispatch_sum, receive_sum = original_today_sum(today, user: user)
  #   [receive_sum, dispatch_sum]
  # end
end

Contractor.class_eval do
  include Statistics

  def actual_balance(today, user: nil)
  end
end

User.class_eval do
  include Statistics

  def yesterday_balance_as_host(today)
    condition = 'date < :date AND record_type = :record_type'
    params = { date: today, record_type: Record::TYPE_DAY_CHECK }
    check_date = self.records.where(condition, params).order('created_at DESC').first.try(:date)
    balance = 0
    if check_date
      condition = 'participant_id = :participant AND date = :date AND record_type = :record_type'
      params[:date] = check_date
      params[:participant] = self
      balance = self.records.where(condition, params).sum('weight')
    else
      first_record = self.records.order('created_at').first
      check_date = (first_record ? first_record.date : Time.now.to_date) - 1.day
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
    condition = 'participant_id = :participant and date = :date and record_type = :record_type'
    params = { participant: self, date: today, record_type: Record::TYPE_DAY_CHECK }
    if self.records.where(condition, params).count > 0
      self.records.where(condition, params).sum('weight')
    else
      yesterday_balance_as_host(today)
    end
  end

  def participants(date)
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
  skip_before_action :need_super_permission
  
  def day_detail
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    user_id = params[:user_id] || session[:user_id]
    @user = User.find(user_id)
    
    @report = []
    @user.participants(@date).each do |participant|
      last_balance = participant.yesterday_balance(@date, user: @user)
      balance = last_balance
      @report.push(name: participant.name, last_balance: last_balance, balance: balance)
      transactions = participant.today_transactions(@date, user: @user)
      transactions[:dispatch].each do |name, value|
        balance += value
        @report.push(product_name: name, dispatch_value: value, balance: balance)
      end
      transactions[:receive].each do |name, value|
        balance -= value
        @report.push(product_name: name, receive_value: value, balance: balance)
      end
      dispatch_sum, receive_sum = participant.today_sum(@date, user: @user)
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
        actual_balance = participant.actual_balance(@date, user: @user)
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
        type: :total
    )
  end

  def day_summary
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    user_id = params[:user_id] || session[:user_id]
    @user = User.find(user_id)

    @report = []
    total_dispatch_sum = 0
    total_receive_sum = 0
    @user.participants(@date).each do |participant|
      last_balance = participant.yesterday_balance(@date, user: @user)
      dispatch_sum, receive_sum = participant.today_sum(@date, user: @user)
      total_dispatch_sum += dispatch_sum
      total_receive_sum += receive_sum
      balance = last_balance + dispatch_sum - receive_sum
      actual_balance = participant.actual_balance(@date, user: @user)
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
        type: :total
    )
  end

  def goods_distribution_detail
    milli = ->(sum) { sum / 1000 }
    gram = ->(sum) { "%.4f" % [sum / 26.717] }
    
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date   
    @report = []
    total = 0
    Record.users(@date).each do |user|
      sum = user.yesterday_balance_as_host(@date + 1.day)
      total += sum
      @report.push name: user.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    Record.participants(@date).each do |participant|
      sum = participant.yesterday_balance(@date + 1.day)
      total += sum
      @report.push name: participant.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    @report.push name: '合计', milli: milli.call(total), gram: gram.call(total), type: :total
  end

  def goods_in_employees
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    @report = []
    total = 0
    Record.employees(@date).each do |employee|
      sum = employee.yesterday_balance(@date + 1.day)
      total += sum
      @report.push name: employee.name, sum: sum, average: sum / employee.colleague_number
    end
    @report.push name: '生产用金合计', sum: total, type: :total
  end

  def depletion
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @column = (@to_date - @from_date).to_i + 1
    @report = []
    Record.employees(@to_date).each do |employee|
      values = []
      depletion_sum = 0
      (@from_date..@to_date).each do |date|
        last_balance = employee.yesterday_balance(date, check_type: Record::TYPE_DAY_CHECK)
        dispatch_sum, receive_sum = employee.today_sum(date)
        actual_balance = employee.actual_balance(date)
        depletion = last_balance + dispatch_sum - receive_sum - actual_balance
        depletion_sum += depletion
        values.push depletion: depletion
      end
      values.push depletion: depletion_sum
      values.push depletion_sum
      @report.push name: employee.name, values: values
    end
  end
  

  def production_by_employees
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    employees = Record.where('date <= ? AND participant_type = ?', @to_date, Employee.name).group('participant_id').collect do |record|
      record.participant
    end
    @report = []
    employees.each do |employee|
      records = Record.where('date >= ? AND date <= ? AND participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE)
      records.each_with_index do |record, i|
        attr = {
            employee_name: (i==0) ? employee.name : '',
            date: record.date,
            product_name: (record.product == nil) ? ('') : (record.product.name),
            produce_weight: record.weight,
            product_num: record.count,
            product_per_employee: record.weight/employee.colleague_number,
            total: false
        }
        @report.push attr
      end

      weight_sum = Record.where('date >= ? AND date <= ? AND participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE).sum('weight')
      attr = {
          produce_total_weight: weight_sum,
          product_total_per_employee: weight_sum/employee.colleague_number,
          total: true
      }
      @report.push attr
    end
  end

  def production_by_type
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    products = Product.all

    @report = []
    products.each do |product|
      records = Record.where('date >= ? AND date <= ? AND product_id = ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, product, Employee.name, Record::TYPE_RECEIVE)
      if (records != nil) && (records.size > 0)
        records.each_with_index do |record, i|
          attr = {
              product_name: (i==0) ? product.name : '',
              date: record.date,
              employee_name: (record.participant == nil) ? ('') : (record.participant.name),
              produce_weight: record.weight,
              product_num: record.count,
              product_per_employee: (record.participant == nil) ? ('') : (record.weight/record.participant.colleague_number),
              total: false
          }
          @report.push attr
        end
        weight_sum = Record.where('date >= ? AND date <= ? AND product_id = ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, product, Employee.name, Record::TYPE_RECEIVE).sum('weight')
        attr = {
            produce_total_weight: weight_sum,
            total: true
        }
        @report.push attr
      end
    end
  end

  def production_summary
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    employees = Record.where('date <= ? AND participant_type = ?', @to_date, Employee.name).group('participant_id').collect do |record|
      record.participant
    end
    @report = []
    employees.each do |employee|
      records = Record.where('date >= ? AND date <= ? AND participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE)
      records.each_with_index do |record, i|
        attr = {
            employee_name: (i==0) ? employee.name : '',
            date: record.date,
            product_name: (record.product == nil) ? ('') : (record.product.name),
            produce_weight: record.weight,
            product_num: record.count,
            product_per_employee: record.weight/employee.colleague_number,
            total: false
        }
        @report.push attr
      end

      weight_sum = Record.where('date >= ? AND date <= ? and participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE).sum('weight')
      attr = {
          produce_total_weight: weight_sum,
          product_total_per_employee: weight_sum/employee.colleague_number,
          total: true
      }
      @report.push attr
    end
  end
  
  def weight_diff
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @report = []
    @users = Record.users(@to_date)
    (@from_date..@to_date).each do |date|
      values = []
      @users.each do |user|
        last_balance = user.yesterday_balance_as_host(date)
        dispatch_sum, receive_sum = user.today_sum_as_host(date)
        actual_balance = user.actual_balance_as_host(date)
        difference = last_balance + receive_sum - dispatch_sum - actual_balance
        values.push difference
      end
      @report.push name: date.strftime('%Y-%m-%d'), values: values
    end
    init = { values: Array.new(@users.size) { 0 } }
    totals = @report.reduce(init) do |r1, r2|
      values = r1[:values].zip(r2[:values]).map { |v1, v2| v1 + v2 }
      { values: values }
    end
    totals.update name: '合计', type: :sum
    @report.push totals
  end
  
  def current_user_balance
    user = User.find(session[:user_id])
    date = Time.now.to_date
    last_balance = user.yesterday_balance_as_host(date)
    dispatch_sum, receive_sum = user.today_sum_as_host(date)
    @balance = last_balance + receive_sum - dispatch_sum
    render(layout: false)
  end
end
