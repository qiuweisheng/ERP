class ReportsController < ApplicationController
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:day_detail, :day_summary, :current_user_balance]
  before_action :need_login, only: [:day_detail, :day_summary, :current_user_balance]

  def day_detail
    unless is_admin_permission? session[:permission]
      params[:date] = nil
      params[:user_id] = nil
    end
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    user_id = params[:user_id] || session[:user_id]
    @user = User.find(user_id)
    
    @report = []
    @user.participants(@date).each do |participant|
      last_balance = participant.balance_before_date(@date, user: @user)
      balance = last_balance
      @report.push(name: participant.name, last_balance: last_balance, balance: balance)
      transactions = participant.transactions_at_date(@date, user: @user)
      transactions[:dispatch].each do |name, value|
        balance += value
        @report.push(product_name: name, dispatch_value: value, balance: balance)
      end
      transactions[:receive].each do |name, value|
        balance -= value
        @report.push(product_name: name, receive_value: value, balance: balance)
      end
      dispatch_sum, receive_sum = participant.weights_at_date(@date, user: @user)
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
        checked_balance_at_date = participant.checked_balance_at_date(@date, user: @user)
        difference = balance - checked_balance_at_date
        attr[:checked_balance_at_date] = checked_balance_at_date
        attr[:depletion] = difference
      end
      @report.push attr
    end

    host_dispatch_sum, host_receive_sum, other_dispatch_sum, other_receive_sum = @user.weights_at_date_as_host(@date)
    @report.push(
        name: '本柜台',
        dispatch_value: other_receive_sum,
        receive_value: other_dispatch_sum,
        type: :sum
    )
    host_last_balance = @user.balance_before_date_as_host(@date)
    host_balance = host_last_balance - host_dispatch_sum + host_receive_sum
    host_checked_balance_at_date = @user.checked_balance_at_date_as_host(@date)
    @report.push(
        name: '本柜当日结余',
        last_balance: host_last_balance,
        dispatch_value: host_dispatch_sum,
        receive_value: host_receive_sum,
        balance: host_balance,
        difference: host_checked_balance_at_date - host_balance,
        checked_balance_at_date: host_checked_balance_at_date,
        type: :total
    )
  end

  def day_summary
    unless is_admin_permission? session[:permission]
      params[:date] = nil
      params[:user_id] = nil
    end
    
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    user_id = params[:user_id] || session[:user_id]
    @user = User.find(user_id)

    @report = []
    total_dispatch_sum = 0
    total_receive_sum = 0
    @user.participants(@date).each do |participant|
      last_balance = participant.balance_before_date(@date, user: @user)
      dispatch_sum, receive_sum = participant.weights_at_date(@date, user: @user)
      total_dispatch_sum += dispatch_sum
      total_receive_sum += receive_sum
      balance = last_balance + dispatch_sum - receive_sum
      checked_balance_at_date = participant.checked_balance_at_date(@date, user: @user)
      attr = {
          name: participant.name,
          last_balance: last_balance,
          dispatch_sum: dispatch_sum,
          receive_sum: receive_sum,
          balance: balance,
          checked_balance_at_date: checked_balance_at_date
      }
      if participant.class == Employee
        attr[:depletion] = balance - checked_balance_at_date
      end
      @report.push attr
    end
    host_dispatch_sum, host_receive_sum, other_dispatch_sum, other_receive_sum = @user.weights_at_date_as_host(@date)
    @report.push(
        name: '本柜台',
        dispatch_sum: other_receive_sum,
        receive_sum: other_dispatch_sum,
        type: :sum
    )
    host_last_balance = @user.balance_before_date_as_host(@date)
    host_balance = host_last_balance - host_dispatch_sum + host_receive_sum
    host_checked_balance_at_date = @user.checked_balance_at_date_as_host(@date)
    @report.push(
        name: '本柜当日结余',
        last_balance: host_last_balance,
        dispatch_sum: host_dispatch_sum,
        receive_sum: host_receive_sum,
        balance: host_balance,
        difference: host_balance - host_checked_balance_at_date,
        checked_balance_at_date: host_checked_balance_at_date,
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
      sum = user.balance_before_date_as_host(@date + 1.day)
      total += sum
      @report.push name: user.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    Record.participants(@date).each do |participant|
      sum = participant.balance_before_date(@date + 1.day)
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
      sum = employee.balance_before_date(@date + 1.day)
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
        last_balance = employee.balance_before_date(date, check_type: Record::TYPE_DAY_CHECK)
        dispatch_sum, receive_sum = employee.weights_at_date(date)
        checked_balance_at_date = employee.checked_balance_at_date(date)
        depletion = last_balance + dispatch_sum - receive_sum - checked_balance_at_date
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
        last_balance = user.balance_before_date_as_host(date)
        dispatch_sum, receive_sum = user.weights_at_date_as_host(date)
        checked_balance_at_date = user.checked_balance_at_date_as_host(date)
        difference = last_balance + receive_sum - dispatch_sum - checked_balance_at_date
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
    @user = User.find(session[:user_id])
    date = Time.now.to_date
    last_balance = @user.balance_before_date_as_host(date)
    dispatch_sum, receive_sum = @user.weights_at_date_as_host(date)
    @balance = last_balance + receive_sum - dispatch_sum
    respond_to do |format|
      format.html { render layout: false }
      format.js
    end
  end
  
  def client_weight_difference
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @report = []
    @clients = Record.clients(@to_date)
    @clients.each do |client|
      (@from_date..@to_date).each do |date|
        weight_diff = Record.where('date = ? AND participant_id = ? AND record_type = ?', date, client, Record::TYPE_WEIGHT_DIFFERENCE).sum('weight')
        attr = {
            date: date.strftime('%Y-%m-%d'),
            client_name: client.name,
            value: weight_diff
        }
        @report.push attr
      end
      weight_diff = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_WEIGHT_DIFFERENCE).sum('weight')
      attr = {
          date: '合计',
          value: weight_diff,
          type: :sum
      }
      @report.push attr
    end
    weight_diff = Record.where('date >= ? AND date <= ?AND participant_type = ? AND record_type = ?', @from_date, @to_date, Client.name, Record::TYPE_WEIGHT_DIFFERENCE).sum('weight')
    attr = {
        date: '总计',
        value: weight_diff,
        type: :total
    }
    @report.push attr
  end

  def client_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @clients = Record.clients(@to_date)

    @report = []
    last_balance = []
    last_balance.push '日期'
    last_balance.push '上期余额'
    month_receive_sum = []
    month_dispatch_sum = []
    month_receive_sum << '本月合计'<<'收回'
    month_dispatch_sum << '本月合计'<<'交与'

    balance = []
    balance << '' << '本月余额'
    weight_diff = []
    weight_diff << '' << '称差'
    @clients.each do |client|
      bal_val = client.balance_before_date(@from_date)
      last_balance.push bal_val

      rev_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_RECEIVE).sum('weight')
      dis_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_DISPATCH).sum('weight')
      month_receive_sum.push rev_value
      month_dispatch_sum.push dis_value

      diff = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_WEIGHT_DIFFERENCE).sum('weight')
      weight_diff.push diff
      balance.push (bal_val + dis_value - rev_value - diff)
    end
    @report.push last_balance: last_balance, type: :head

    (@from_date..@to_date).each do |date|
      dispatch = []
      receive = []
      dispatch << date.strftime('%Y-%m-%d') << '交与'
      receive << date.strftime('%Y-%m-%d') << '收回'
      @clients.each do |client|
        dis, rev = client.weights_at_date(date)
        receive << rev
        dispatch << dis
      end
      @report.push receive: receive, dispatch: dispatch, type: :value
    end
    #summary
    @report.push receive: month_receive_sum, dispatch: month_dispatch_sum, type: :value
    #weitgh diff
    @report.push weight_diff: weight_diff, type: :weight_diff
    #today balance
    @report.push balance: balance, type: :total
  end

  def contractor_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @contractors = Record.contractors(@to_date)

    @report = []
    last_balance = []
    last_balance.push '日期'
    last_balance.push '上期余额'
    month_receive_sum = []
    month_dispatch_sum = []
    month_receive_sum << '本月合计'<<'收回'
    month_dispatch_sum << '本月合计'<<'交与'

    balance = []
    balance << '' << '本月余额'

    @contractors.each do |contractors|
      bal_val = contractors.balance_before_date(@from_date)
      last_balance.push bal_val

      rev_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, contractors, Record::TYPE_RECEIVE).sum('weight')
      dis_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, contractors, Record::TYPE_DISPATCH).sum('weight')
      month_receive_sum.push rev_value
      month_dispatch_sum.push dis_value

      balance.push (bal_val + dis_value - rev_value)
    end
    @report.push last_balance: last_balance, type: :head

    (@from_date..@to_date).each do |date|
      dispatch = []
      receive = []
      dispatch << date.strftime('%Y-%m-%d') << '交与'
      receive << date.strftime('%Y-%m-%d') << '收回'
      @contractors.each do |contractor|
        dis, rev = contractor.weights_at_date(date)
        receive << rev
        dispatch << dis
      end
      @report.push receive: receive, dispatch: dispatch, type: :value
    end
    #summary
    @report.push receive: month_receive_sum, dispatch: month_dispatch_sum, type: :value
    #today balance
    @report.push balance: balance, type: :total
  end
  
end

module Statistics
  def transactions_at_date(date, user: nil)
    transactions = { dispatch: [], receive: [] }
    records = self.transactions.select('product_id, weight').at_date(date)
    records = records.created_by_user(user) if user
    records.of_type(Record::TYPE_DISPATCH).each do |record|
      transactions[:dispatch].push [record.product.try(:name), record.weight]
    end
    records.of_type(Record::TYPE_RECEIVE).each do |record|
      transactions[:receive].push [record.product.try(:name), record.weight]
    end
    transactions
  end
  
  def weights_at_date(date, user: nil)
    records = self.transactions.at_date(date)
    records = records.created_by_user(user) if user
    dispatch_weight = records.of_type(Record::TYPE_DISPATCH).sum('weight')
    receive_weight = records.of_type(Record::TYPE_RECEIVE).sum('weight')
    [dispatch_weight, receive_weight]
  end

  def checked_balance_at_date(date, user: nil)
    records = self.transactions.at_date(date).of_type(Record::TYPE_DAY_CHECK)
    records = records.created_by_user(user) if user
    if records.count > 0
      records.sum('weight')
    else
      balance_before_date(date, user: user)
    end
  end
  
  def balance_before_date(date, user: nil)
    records = self.transactions.before_date(date)
    records = records.created_by_user(user) if user
    balance = records.of_type(Record::TYPE_DISPATCH).sum('weight')
    balance -= records.of_type(Record::TYPE_RECEIVE).sum('weight')
  end
end

Client.class_eval do
  include Statistics

  def checked_balance_at_date(date, user: nil)
  end
end

Contractor.class_eval do
  include Statistics

  def checked_balance_at_date(date, user: nil)
  end
end

User.class_eval do
  include Statistics

  def balance_before_date_as_host(date)
    balance = 0
    # 找日盘点日期
    check_date = self.records.of_type(Record::TYPE_DAY_CHECK).before_date(date).order('created_at DESC').first.try(:date)
    if check_date
      # 柜台当天的日盘点值
      balance = self.records.of_type(Record::TYPE_DAY_CHECK).of_participant(self).at_date(check_date).sum('weight')
    else
      first_record = self.records.order('created_at').first
      check_date = (first_record ? first_record.date : Time.now.to_date) - 1.day
    end
    records = self.records.between_date_exclusive(check_date, date)
    transactions = self.transactions.between_date_exclusive(check_date, date)
    # 发货
    balance -= records.of_type(Record::TYPE_DISPATCH).sum('weight')
    balance -= records.of_type(Record::TYPE_PACKAGE_DISPATCH).sum('weight')
    balance -= records.of_type(Record::TYPE_POLISH_DISPATCH).sum('weight')
    # 收货
    balance += records.of_type(Record::TYPE_RECEIVE).sum('weight')
    balance += records.of_type(Record::TYPE_PACKAGE_RECEIVE).sum('weight')
    balance += records.of_type(Record::TYPE_POLISH_RECEIVE).sum('weight')
    # 客户退货
    balance += records.of_type(Record::TYPE_RETURN).sum('weight')
    # 去别的柜台领货
    balance += transactions.of_type(Record::TYPE_DISPATCH).sum('weight')
    balance += transactions.of_type(Record::TYPE_PACKAGE_DISPATCH).sum('weight')
    balance += transactions.of_type(Record::TYPE_POLISH_DISPATCH).sum('weight')
    # 去别的柜台还货
    balance -= transactions.of_type(Record::TYPE_RECEIVE).sum('weight')
    balance -= transactions.of_type(Record::TYPE_PACKAGE_RECEIVE).sum('weight')
    balance -= transactions.of_type(Record::TYPE_POLISH_RECEIVE).sum('weight') 
  end

  def weights_at_date_as_host(date)
    records = self.records.at_date(date)
    transactions = self.transactions.at_date(date)
    # 去别的柜台领货
    other_dispatch_weight = transactions.of_type(Record::TYPE_DISPATCH).sum('weight')
    other_dispatch_weight += transactions.of_type(Record::TYPE_PACKAGE_DISPATCH).sum('weight')
    other_dispatch_weight += transactions.of_type(Record::TYPE_POLISH_DISPATCH).sum('weight')
    # 去别的柜台还货
    other_receive_weight = transactions.of_type(Record::TYPE_RECEIVE).sum('weight')
    other_receive_weight += transactions.of_type(Record::TYPE_PACKAGE_RECEIVE).sum('weight')
    other_receive_weight += transactions.of_type(Record::TYPE_POLISH_RECEIVE).sum('weight') 
    # 发货
    dispatch_weight = records.of_type(Record::TYPE_DISPATCH).sum('weight')
    dispatch_weight += records.of_type(Record::TYPE_PACKAGE_DISPATCH).sum('weight')
    dispatch_weight += records.of_type(Record::TYPE_POLISH_DISPATCH).sum('weight')
    # 收货
    receive_weight = records.of_type(Record::TYPE_RECEIVE).sum('weight')
    receive_weight += records.of_type(Record::TYPE_PACKAGE_RECEIVE).sum('weight')
    receive_weight += records.of_type(Record::TYPE_POLISH_RECEIVE).sum('weight')
    
    dispatch_weight += other_receive_weight
    receive_weight += other_dispatch_weight
    [dispatch_weight, receive_weight, other_dispatch_weight, other_receive_weight]
  end

  def checked_balance_at_date_as_host(date)
    records = self.records.of_type(Record::TYPE_DAY_CHECK).of_participant(self).at_date(date)
    if records.count > 0
      records.sum('weight')
    else
      balance_before_date_as_host(date)
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
  
  def balance_before_date(date, user: nil, check_type: nil)
    records = self.transactions
    records = records.created_by_user(user) if user
    check_type = Record::TYPE_MONTH_CHECK unless check_type
    check_date = records.of_type(check_type).before_date(date).order('created_at DESC').first.try(:date)
    balance = 0
    if check_date
      balance = records.of_type(check_type).at_date(check_date).sum('weight')
    else
      first_record = self.transactions.order('created_at').first
      check_date = (first_record ? first_record.date : Time.now.to_date) - 1.day
    end
    balance += records.of_type(Record::TYPE_DISPATCH).between_date_exclusive(check_date, date).sum('weight')
    balance -= records.of_type(Record::TYPE_RECEIVE).between_date_exclusive(check_date, date).sum('weight')
  end
end
