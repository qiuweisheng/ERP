class ReportsController < ApplicationController
  skip_before_action :need_super_permission
  prepend_before_action :need_admin_permission, except: [:day_detail, :day_summary, :current_user_balance]
  before_action :need_login, only: [:day_detail, :day_summary, :current_user_balance]


  private def check_date_and_user_param()
    if is_admin_permission? session[:permission]
      params[:date] ||= Time.now.to_date.strftime("%Y-%m-%d")
      params[:user_id] ||= session[:user_id]
    else
      params[:date] = Time.now.to_date.strftime("%Y-%m-%d")
      params[:user_id] = session[:user_id]
    end
  end
  
  private def participant_summary(date, user, participant)
    report = []
    last_balance = participant.balance_before_date(date, user)
    dispatch_weight, receive_weight = participant.weights_at_date(date, user: user)
    balance = participant.balance_at_date(date, user)
    row = {
      name: participant.name, 
      last_balance: last_balance, 
      dispatch_value: dispatch_weight, 
      receive_value: receive_weight, 
      balance: balance
    }
    checked_balance_at_date = participant.checked_balance_at_date(date, user)
    row[:checked_balance_at_date] = checked_balance_at_date
    if not participant.is_check_at_date(date, user)
      row.update(checked_balance_at_date: "待盘点")
    end
    if participant.class == Employee
      depletion = balance - checked_balance_at_date
      row[:depletion] = depletion
    end
    if participant.class == Client or participant.class == Contractor
      difference = participant.difference_at_date(date, user: user)
      row[:balance] += difference
      row[:difference] = difference
    end 
    report.push row
    report
  end
  
  private def participant_summarys_of_user(date, user)
    report = []
    user.participants(date).each do |participant|
      report += participant_summary(date, user, participant)
    end
    report
  end
  
  private def participant_detail(date, user, participant)
    report = []
    last_balance = participant.balance_before_date(date, user)
    balance = last_balance
    report.push(name: participant.name, last_balance: last_balance, balance: balance)
    transactions = participant.transactions_at_date(date, user)
    transactions[:dispatch].each do |name, value|
      if participant.class == Client or participant.class == Contractor
        balance -= value
      else
        balance += value
      end
      report.push(product_name: name, dispatch_value: value, balance: balance) if value != 0
    end
    transactions[:receive].each do |name, value|
      if participant.class == Client or participant.class == Contractor
        balance += value
      else
        balance -= value
      end
      report.push(product_name: name, receive_value: value, balance: balance) if value != 0
    end
    if transactions[:return] != nil
      transactions[:return].each do |name, value|
        if participant.class == Client or participant.class == Contractor
          balance += value
        else
          balance -= value
        end
        report.push(product_name: name, receive_value: value, balance: balance, is_return: true) if value != 0
      end
    end
    if participant.class == Client or participant.class == Contractor
      difference = participant.difference_at_date(date, user: user)
      balance += difference
      report.push(balance: balance, difference: difference)
    end
    report
  end
  
  private def participant_details_of_user(date, user)
    report = []
    user.participants(date).each do |participant|
      report += participant_detail(date, user, participant)
      report += participant_summary(date, user, participant).map {|row| row.update(name: '合计', type: :sum)}
    end
    report
  end
  
  private def user_summary_as_client(date, user)
    report = []
    other_dispatch_weight, other_receive_weight = user.weights_at_date(date)
    report.push(
        name: '本柜台',
        dispatch_value: other_receive_weight,
        receive_value: other_dispatch_weight,
    )
    report
  end
  
  private def user_detail_as_client(date, user)
    report = []
    user.users(date: date).each do |usr|
      dispatch_weight, receive_weight = user.weights_at_date(date, user: usr)
      report.push(product_name: usr.name, dispatch_value: receive_weight) if receive_weight != 0
      report.push(product_name: usr.name, receive_value: dispatch_weight) if dispatch_weight != 0
    end
    report += user_summary_as_client(date, user).map{|row| row.update(type: :sum)}
  end
  
  private def user_summary_as_host(date, user)
    report = []
    host_dispatch_weight, host_receive_weight = @user.weights_at_date_as_host(@date)
    host_last_balance = @user.balance_before_date_as_host(@date)
    host_balance = @user.balance_at_date_as_host(@date)
    host_checked_balance_at_date = @user.checked_balance_at_date_as_host(@date)
    row = {
        name: '本柜当日结余',
        last_balance: host_last_balance,
        dispatch_value: host_dispatch_weight,
        receive_value: host_receive_weight,
        balance: host_balance,
        difference: host_checked_balance_at_date - host_balance,
        checked_balance_at_date: host_checked_balance_at_date,
        type: :total
    }
    if not user.is_check_at_date_as_host(date)
      row.update(checked_balance_at_date: "待盘点")
    end
    report.push row
    report
  end
  
  def day_detail
    check_date_and_user_param()
    @date = Date.parse(params[:date])
    @user = User.find(params[:user_id])
    
    @report = participant_details_of_user(@date, @user)
    @report += user_detail_as_client(@date, @user)
    @report += user_summary_as_host(@date, @user)
    
    respond_to do |format|
      format.html
      format.js
      format.xlsx
    end
  end
  
  def day_summary
    check_date_and_user_param()
    @date = Date.parse(params[:date])
    @user = User.find(params[:user_id])

    @report = participant_summarys_of_user(@date, @user) 
    @report += user_summary_as_client(@date, @user)
    @report += user_summary_as_host(@date, @user)

    respond_to do |format|
      format.html
      format.js
      format.xlsx
    end
  end

  def goods_distribution_detail
    milli = ->(sum) { sum / 1000 }
    gram = ->(sum) { "%.4f" % [sum / 26.717] }
    
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date   
    @report = []
    total = 0
    Record.users(@date).each do |user|
      sum = user.checked_balance_at_date_as_host(@date)
      total += sum
      @report.push name: user.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    Record.participants(@date).each do |participant|
      sum = participant.users.map {|user| participant.checked_balance_at_date(@date, user)}.reduce(0, :+)           
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
      sum = employee.users.map {|user| employee.balance_before_date(@date + 1.day, user)}.reduce(0, :+)
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
      depletion_sum = 0
      polish_depletion_sum = 0

      value_array = []
      (@from_date..@to_date).each do |date|
        values = {}
        
        depletion = 0
        employee.users(date: date).each do |user|
          last_balance = employee.balance_before_date(date, user, check_type: Record::TYPE_DAY_CHECK)
          dispatch_weight, receive_weight = employee.weights_at_date(date, user: user)
          checked_balance_at_date = employee.checked_balance_at_date(date, user, check_type: Record::TYPE_DAY_CHECK)
          depletion += last_balance + dispatch_weight - receive_weight - checked_balance_at_date
        end
        depletion_sum += depletion
        values[:depletion] = depletion

        #打磨组:被补偿的打磨损耗(分摊出去部分)
        polish_depletion_compensation = employee.transactions.where('date = ? AND record_type = ?', date, Record::TYPE_APPORTION).sum('weight')
        #生产者:损耗分摊(被分摊部分)
        polish_depletion_share = Record.where('date = ? AND employee_id = ? AND record_type = ?', date, employee, Record::TYPE_APPORTION).sum('weight')
        polish_depletion = polish_depletion_share - polish_depletion_compensation
        polish_depletion_sum += polish_depletion

        values[:polish_depletion] = polish_depletion
        value_array << values
      end
      values = {}
      values[:depletion] = depletion_sum
      values[:polish_depletion] = polish_depletion_sum
      value_array << values

      value_array << (depletion_sum + polish_depletion_sum)

      @report.push name: employee.name, values: value_array
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
      (@from_date..@to_date).each do |date|
        products = Record.where('date = ? AND participant_id = ? AND record_type = ?', date, employee, Record::TYPE_RECEIVE).group('product_id').collect do |record|
          record.product
        end

        products.each_with_index do |product, i|
          records = Record.where('date = ? AND participant_id = ? AND record_type = ? AND product_id = ?', date, employee, Record::TYPE_RECEIVE, product)
          unless records.size <= 0
            sum = Record.where('date = ? AND participant_id = ? AND record_type = ? AND product_id = ?', date, employee, Record::TYPE_RECEIVE, product).sum('weight')
            count = Record.where('date = ? AND participant_id = ? AND record_type = ? AND product_id = ?', date, employee, Record::TYPE_RECEIVE, product).sum('count')
            attr = {
                employee_name: (i==0)? employee.name: '',
                date: date,
                product_name: (records[0].product == nil) ? ('') : (records[0].product.name),
                produce_weight: sum,
                product_num: count,
                product_per_employee: sum/employee.colleague_number,
                total: false
            }
            @report.push attr
          end
        end

      end

      # for each employee,each product, calc the sum of weight
      weight_sum = Record.where('date >= ? AND date <= ? and participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE).sum('weight')
      unless weight_sum == 0
        attr = {
            produce_total_weight: weight_sum,
            product_total_per_employee: weight_sum/employee.colleague_number,
            total: true
        }
        @report.push attr
      end
    end
    # for all employee, calc the sum of product weight
    weight_sum = Record.where('date >= ? AND date <= ? AND record_type = ?', @from_date, @to_date, Record::TYPE_RECEIVE).sum('weight')
    unless weight_sum == 0
      attr = {
          produce_total_weight: weight_sum,
          product_total_per_employee: '',
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
        dispatch_weight, receive_weight = user.weights_at_date_as_host(date)
        checked_balance_at_date = user.checked_balance_at_date_as_host(date)
        difference = checked_balance_at_date - (last_balance + receive_weight - dispatch_weight)
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
    dispatch_weight, receive_weight = @user.weights_at_date_as_host(date)
    @balance = last_balance + receive_weight - dispatch_weight
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

  # TODO
  def client_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @clients = Record.clients(@to_date)

    @report = []
    last_balance = []
    last_balance.push '日期'
    last_balance.push '上期余额'
    month_receive_weight = []
    month_dispatch_weight = []
    month_receive_weight << '本月合计'<<'收回'
    month_dispatch_weight << '本月合计'<<'交与'

    balance = []
    balance << '' << '本月余额'
    weight_diff = []
    weight_diff << '' << '称差'
    @clients.each do |client|
      bal_val = client.balance_before_date(@from_date)
      last_balance.push bal_val

      rev_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_RECEIVE).sum('weight')
      dis_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, client, Record::TYPE_DISPATCH).sum('weight')
      month_receive_weight.push rev_value
      month_dispatch_weight.push dis_value

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
    @report.push receive: month_receive_weight, dispatch: month_dispatch_weight, type: :value
    #weitgh diff
    @report.push weight_diff: weight_diff, type: :weight_diff
    #today balance
    @report.push balance: balance, type: :total
  end
  # TODO
  def contractor_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @contractors = Record.contractors(@to_date)

    @report = []
    last_balance = []
    last_balance.push '日期'
    last_balance.push '上期余额'
    month_receive_weight = []
    month_dispatch_weight = []
    month_receive_weight << '本月合计'<<'收回'
    month_dispatch_weight << '本月合计'<<'交与'

    balance = []
    balance << '' << '本月余额'

    @contractors.each do |contractors|
      bal_val = contractors.balance_before_date(@from_date)
      last_balance.push bal_val

      rev_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, contractors, Record::TYPE_RECEIVE).sum('weight')
      dis_value = Record.where('date >= ? AND date <= ?AND participant_id = ? AND record_type = ?', @from_date, @to_date, contractors, Record::TYPE_DISPATCH).sum('weight')
      month_receive_weight.push rev_value
      month_dispatch_weight.push dis_value

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
    @report.push receive: month_receive_weight, dispatch: month_dispatch_weight, type: :value
    #today balance
    @report.push balance: balance, type: :total
  end
  
end

module StatisticsCommon
  # user为nil时，表示所有柜台
  def _weights_of_types_at_date(records, types, date, user)
    records = records.created_by_user(user) if user
    records.of_types(types).at_date(date).sum('weight')
  end
  
  def _weights_of_types_between_date_exclusive(records, types, begin_date, end_date, user)
    records = records.created_by_user(user) if user
    records.of_types(types).between_date_exclusive(begin_date, end_date).sum('weight')
  end
  
  def _weights_at_date(records, date, user)
    dispatch_weight = _weights_of_types_at_date(records, Record::DISPATCH, date, user)
    receive_weight = _weights_of_types_at_date(records, Record::RECEIVE, date, user)
    [dispatch_weight, receive_weight]
  end

  # 有指定check_type时，直接按check_type查找，没有的话按月盘点，日盘点的顺序查找
  def _checked_balance_at_date(records, date, user, check_type)
    records = records.created_by_user(user).of_participant(self).at_date(date)
    if check_type
       if records.of_type(check_type).count > 0
         records.of_type(check_type).sum('weight')
       else
         yield
       end
    else
      if records.of_type(Record::TYPE_MONTH_CHECK).count > 0
        records.of_type(Record::TYPE_MONTH_CHECK).sum('weight')
      elsif records.of_type(Record::TYPE_DAY_CHECK).count > 0
        records.of_type(Record::TYPE_DAY_CHECK).sum('weight')
      else
        yield
      end
    end
  end
  
  def _get_last_check_type_and_date(records, date, user, check_type)
    if check_type
      check_date = _check_date(records, date, user, check_type)
    else
      day_check_date = _check_date(records, date, user, Record::TYPE_DAY_CHECK)
      month_check_date = _check_date(records, date, user, Record::TYPE_MONTH_CHECK)
      if month_check_date >= day_check_date
        check_date = month_check_date
        check_type = Record::TYPE_MONTH_CHECK
      else
        check_date = day_check_date
        check_type = Record::TYPE_DAY_CHECK
      end
    end
    [check_date, check_type]
  end
  
  def _checked_balance_before_date(records, date, user, check_type)
    check_date, check_type = _get_last_check_type_and_date(records, date, user, check_type)
    balance = records.created_by_user(user).of_participant(self).of_type(check_type).at_date(check_date).sum('weight')
    [balance, check_date, check_type]
  end
  
  def _check_date(records, date, user, check_type)
    records = records.created_by_user(user).before_date(date).of_participant(self)
    check_date = records.of_type(check_type).order('date DESC').first.try(:date)
    unless check_date
      first_record = Record.order('date').first
      check_date = (first_record ? first_record.date : Time.now.to_date) - 1.day
    end
    check_date
  end
  
  def _is_check_at_date(records, date, user)
    if records.created_by_user(user).of_participant(self).of_types([Record::TYPE_DAY_CHECK, Record::TYPE_MONTH_CHECK]).at_date(date).count > 0
      true
    else
      false
    end
  end
  
  def transactions_at_date(date, user)
    transactions = {dispatch: [], receive: []}
    records = self.transactions.select('product_id, weight').created_by_user(user).at_date(date)
    records.of_types(Record::DISPATCH).each do |record|
      transactions[:dispatch].push [record.product.try(:name), record.weight]
    end
    records.of_types(Record::RECEIVE).each do |record|
      transactions[:receive].push [record.product.try(:name), record.weight]
    end
    transactions
  end
  
  def weights_at_date(date, user: nil)
    _weights_at_date(self.transactions, date, user)
  end
  
  def is_check_at_date(date, user)
    _is_check_at_date(self.transactions, date, user)
  end
  
  def users(date: nil)
    transactions = self.transactions
    transactions = transactions.at_date(date) if date
    transactions.group('user_id').collect {|r| r.user}.select {|u| u != self}
  end 
end

module StatisticsForExternal
  include StatisticsCommon
  
  def balance_before_date(date, user)
    balance, check_date, check_type = _checked_balance_before_date(self.transactions, date, user, nil)
    balance -= _weights_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance += _weights_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance += _weights_of_types_between_date_exclusive(self.transactions, [Record::TYPE_RETURN], check_date, date, user)
    balance += _weights_of_types_between_date_exclusive(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user)
    last_balance = balance_before_date(date, user)
    dispatch_weight, receive_weight = weights_at_date(date, user: user)
    last_balance - dispatch_weight + receive_weight
  end
  
  def checked_balance_at_date(date, user)
    _checked_balance_at_date(self.transactions, date, user, nil) do 
      balance_before_date(date + 1.day, user)
    end
  end
  
  def weights_at_date(date, user: nil)
    dispatch_weight, receive_weight = _weights_at_date(self.transactions, date, user)
    receive_weight += _weights_of_types_at_date(self.transactions, [Record::TYPE_RETURN], date, user)
    # receive_weight += _weights_of_types_at_date(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], date, user)
    [dispatch_weight, receive_weight]
  end
  
  def difference_at_date(date, user: nil)
    _weights_of_types_at_date(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], date, user)
  end
  
  alias transactions_at_date_orig transactions_at_date
  def transactions_at_date(date, user)
    transactions = transactions_at_date_orig(date, user)
    transactions[:return] = []
    records = self.transactions.select('product_id, weight').created_by_user(user).at_date(date)
    records.of_types([Record::TYPE_RETURN]).each do |record|
      transactions[:return].push [record.product.try(:name), record.weight]
    end
    transactions
  end
end

Client.class_eval do
  include StatisticsForExternal
end

Contractor.class_eval do
  include StatisticsForExternal
end

Employee.class_eval do
  include StatisticsCommon
  
  def balance_before_date(date, user, check_type: Record::TYPE_MONTH_CHECK)
    balance, check_date, check_type = _checked_balance_before_date(self.transactions, date, user, check_type)
    balance += _weights_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance -= _weights_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user, check_type: Record::TYPE_MONTH_CHECK)
    last_balance = balance_before_date(date, user, check_type: check_type)
    dispatch_weight, receive_weight = weights_at_date(date, user: user)
    last_balance + dispatch_weight - receive_weight
  end
  
  def checked_balance_at_date(date, user, check_type: nil)
    _checked_balance_at_date(self.transactions, date, user, check_type) do
      balance_before_date(date + 1.day, user, check_type: check_type)
    end
  end
end

User.class_eval do
  include StatisticsCommon
  
  def balance_before_date(date, user)
    balance, check_date, check_type = _checked_balance_before_date(self.transactions, date, user, nil)
    balance += _weights_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance -= _weights_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user)
    last_balance = balance_before_date(date, user)
    dispatch_weight, receive_weight = weights_at_date(date, user: user)
    last_balance + dispatch_weight - receive_weight
  end
  
  def checked_balance_at_date(date, user)
    _checked_balance_at_date(self.transactions, date, user, nil) do
      balance_before_date(date + 1.day, user)
    end
  end
  
  def balance_before_date_as_host(date)
    balance, check_date, check_type = _checked_balance_before_date(self.records, date, self, nil)
    # 发货
    balance -= _weights_of_types_between_date_exclusive(self.records, Record::DISPATCH, check_date, date, self)
    # 收货
    balance += _weights_of_types_between_date_exclusive(self.records, Record::RECEIVE, check_date, date, self)
    # 客户退货
    balance += _weights_of_types_between_date_exclusive(self.records, [Record::TYPE_RETURN], check_date, date, self)
    # 去别的柜台交易
    trade_with_other_user = _weights_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, nil)
    trade_with_other_user -= _weights_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, nil)
    balance += trade_with_other_user
  end
  
  def balance_at_date_as_host(date)
    last_balance = balance_before_date_as_host(date)
    dispatch_weight, receive_weight = weights_at_date_as_host(date)
    last_balance - dispatch_weight + receive_weight
  end
  
  def checked_balance_at_date_as_host(date)
    _checked_balance_at_date(self.records, date, self, nil) do
      balance_before_date_as_host(date + 1.day)
    end
  end

  def weights_at_date_as_host(date)
    records = self.records.at_date(date)
    transactions = self.transactions.at_date(date)
    # 去别的柜台领货、去别的柜台还货
    other_dispatch_weight, other_receive_weight = _weights_at_date(self.transactions, date, nil)
    # 收发货
    dispatch_weight, receive_weight = _weights_at_date(self.records, date, self)
    # 客户退货
    return_weight = _weights_of_types_at_date(self.records, [Record::TYPE_RETURN], date, self)
    
    dispatch_weight += other_receive_weight
    receive_weight += other_dispatch_weight + return_weight
    [dispatch_weight, receive_weight, other_dispatch_weight, other_receive_weight]
  end
  
  def is_check_at_date_as_host(date)
    _is_check_at_date(self.records, date, self)
  end

  def participants(date)
    self.records.at_date(date).group('participant_id').collect  { |r| r.participant }.select {|p| p != self}
    # group = self.records.at_date(date).group('participant_id')
    #           .collect  { |r| r.participant }
    #           .group_by { |p| p.class }
    # [Employee, User, Contractor, Client]
    #   .map    { |c| group[c] }
    #   .select { |p| p }
    #   .flatten
  end
end
