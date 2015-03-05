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

  private def check_date_range_and_client_param()
    if is_admin_permission? session[:permission]
      params[:from_date] ||= Time.now.to_date.strftime("%Y-%m-%d")
      params[:to_date] ||= Time.now.to_date.strftime("%Y-%m-%d")
      params[:client_id] ||= session[:client_id]
    else
      params[:from_date] = Time.now.to_date.strftime("%Y-%m-%d")
      params[:to_date] = Time.now.to_date.strftime("%Y-%m-%d")
      params[:client_id] = session[:client_id]
    end
  end

  private def check_date_range_and_contractor_param()
    if is_admin_permission? session[:permission]
      params[:from_date] ||= Time.now.to_date.strftime("%Y-%m-%d")
      params[:to_date] ||= Time.now.to_date.strftime("%Y-%m-%d")
      params[:contractor_id] ||= session[:contractor_id]
    else
      params[:from_date] = Time.now.to_date.strftime("%Y-%m-%d")
      params[:to_date] = Time.now.to_date.strftime("%Y-%m-%d")
      params[:contractor_id] = session[:contractor_id]
    end
  end

  private def participant_summary(date, user, participant)
    report = []
    last_balance = participant.balance_before_date(date, user)
    dispatch_weight, receive_weight = participant.weights_at_date(date, user)
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
      difference = participant.difference_at_date(date, user)
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
      difference = participant.difference_at_date(date, user)
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
      dispatch_weight, receive_weight = user.weights_at_date(date, usr)
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

  private def ext_customer_trans_detail(date: nil, user: nil, participant: nil, last_balance: nil, last_check_value: nil)
    report = []
    rev_sum, dis_sum, return_sum, weight_diff_sum = 0, 0, 0, 0
    #(1) desc
    balance = last_balance
    report.push(date: date, name: user.name, balance: balance)
    transactions = participant.transactions_at_date(date, user)
    #(2) dispatch
    transactions[:dispatch].each do |name, value|
      balance -= value
      dis_sum += value
      report.push(product_name: name, dispatch_value: value, balance: balance) if value != 0
    end
    #(3) receive
    transactions[:receive].each do |name, value|
      balance += value
      rev_sum += value
      report.push(product_name: name, receive_value: value, balance: balance) if value != 0
    end
    #(4) return
    if transactions[:return] != nil
      transactions[:return].each do |name, value|
        balance += value
        return_sum += value
        report.push(product_name: name, return_value: value, balance: balance, is_return: true) if value != 0
      end
    end
    #(5) weight diff
    difference = participant.difference_at_date(date, user)
    balance += difference
    weight_diff_sum += difference
    report.push(balance: balance, difference: difference) if difference != 0
    #(6) check
    checked_balance_at_date = participant.checked_balance_at_date(date, user)
    if participant.is_check_at_date(date, user)
      row = {
          balance: checked_balance_at_date+last_check_value, check_value: checked_balance_at_date
      }
      report.push(row) if checked_balance_at_date != 0
      last_check_value = checked_balance_at_date + last_check_value
      balance = last_check_value
    end
    #(7) summary
    report.push(name: '合计', dispatch_value: dis_sum, receive_value: rev_sum, return_value: return_sum, difference: weight_diff_sum, balance: balance, type: :sum)
    #
    {report: report, balance: balance, check_value: last_check_value}
  end

  private def ext_customer_trans_summary(participant: nil, from_date: nil, to_date: nil, last_balance: nil, balance: nil)
    report = []
    rev_sum, dis_sum, return_sum, weight_diff_sum = 0, 0, 0, 0
    transactions = participant.transactions.between_date(from_date, to_date)
    rev_sum = transactions.of_types(Record::RECEIVE).sum('weight')
    dis_sum = transactions.of_types(Record::DISPATCH).sum('weight')
    return_sum = transactions.of_type(Record::TYPE_RETURN).sum('weight')
    weight_diff_sum = transactions.of_type(Record::TYPE_WEIGHT_DIFFERENCE).sum('weight')
    checked_balance_at_date = participant.checked_balance_at_date(to_date, nil)
    row = {
      name: '总计',
      type: :total,
      last_balance: last_balance,
      dispatch_value: dis_sum,
      receive_value: rev_sum,
      return_value: return_sum,
      difference: weight_diff_sum,
      balance: balance,
      check_value: participant.is_check_at_date(to_date, nil) ? checked_balance_at_date : '',
    }
    report.push row
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
      format.xlsx {
        filename = "(#{@user.name})收发日报表(明细)#{@date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
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
      format.xlsx {
        filename = "(#{@user.name})收发日报表(汇总)#{@date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def goods_flow
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
        
    milli = ->(sum) { sum }
    gram = ->(sum) { "%.4f" % [sum / 26.717] }
    @report = []
    users = User.all
    employees = Employee.all
    clients = Client.all
    last_balance = users.map {|user| user.balance_before_date_as_host(@from_date)}.reduce(0, :+)
    employees.map do |employee|
      employee.users(date: @from_date - 1.day).each do |user|
        last_balance += employee.balance_before_date(@from_date, user)
      end
    end
    @report.push name: '上期余额', milli: milli.call(last_balance), gram: gram.call(last_balance), type: :sum
  
    client_receive_weight = clients.map {|client| client.dispatch_weight_between_date(@from_date, @to_date)}.reduce(0, :+)
    @report.push name: '客户来料', milli: milli.call(client_receive_weight), gram: gram.call(client_receive_weight)
    
    client_dispatch_weight = clients.map {|client| client.receive_weight_between_date(@from_date, @to_date)}.reduce(0, :+)
    @report.push name: '交与客户', milli: milli.call(client_dispatch_weight), gram: gram.call(client_dispatch_weight)
    
    client_return_weight = clients.map {|client| client.return_weight_between_date(@from_date, @to_date)}.reduce(0, :+)
    @report.push name: '客户退货', milli: milli.call(client_return_weight), gram: gram.call(client_return_weight)
    
    client_weight_difference = clients.map {|client| client.weight_difference_between_date(@from_date, @to_date)}.reduce(0, :+)
    @report.push name: '客户称差', milli: milli.call(client_weight_difference), gram: gram.call(client_weight_difference)
    depletion = 0
    employees.each do |employee|
      users.each do |user|
        depletion += employee.depletion_between_date(@from_date, @to_date, user)
      end
    end
    # employee_receive_weight = Record.of_participant_type(Employee)
    #                                 .between_date(@from_date, @to_date)
    #                                 .of_types(Record::DISPATCH)
    #                                 .sum("weight")
    # employee_dispatch_weight = Record.of_participant_type(Employee)
    #                                  .between_date(@from_date, @to_date)
    #                                  .of_types(Record::RECEIVE)
    #                                  .sum("weight")
    # employee_checked_weight = Record.of_participant_type(Employee)
    #                                 .between_date(@from_date, @to_date)
    #                                 .of_types([Record::TYPE_DAY_CHECK, Record::TYPE_MONTH_CHECK])
    #                                 .sum("weight")
    # depletion = employee_receive_weight - employee_dispatch_weight - employee_checked_weight
    @report.push name: '工厂损耗', milli: milli.call(depletion), gram: gram.call(depletion)
    user_difference = 0
    (@from_date..@to_date).each do |date|
      users.each do |user|
        user_difference += user.balance_at_date_as_host(date) - user.checked_balance_at_date_as_host(date)
      end
    end
    # user_dispatch_weight = Record.of_not_participant_type(User)
    #                              .between_date(@from_date, @to_date)
    #                              .of_types(Record::DISPATCH)
    #                              .sum("weight")
    #
    # user_dispatch_weight += Record.of_participant_type(User)
    #                               .between_date(@from_date, @to_date)
    #                               .of_types(Record::RECEIVE)
    #                               .sum("weight")
    #
    # user_receive_weight = Record.of_not_participant_type(User)
    #                             .between_date(@from_date, @to_date)
    #                             .of_types(Record::RECEIVE + [Record::TYPE_RETURN])
    #                             .sum("weight")
    #
    # user_receive_weight += Record.of_participant_type(User)
    #                              .between_date(@from_date, @to_date)
    #                              .of_types(Record::DISPATCH)
    #                              .sum("weight")
    #
    # user_checked_weight = Record.of_participant_type(User)
    #                             .between_date(@from_date, @to_date)
    #                             .of_types([Record::TYPE_DAY_CHECK, Record::TYPE_MONTH_CHECK])
    #                             .sum("weight")
    # user_difference = user_receive_weight - user_dispatch_weight - user_checked_weight
    @report.push name: '柜台称差', milli: milli.call(user_difference), gram: gram.call(user_difference)
    sum = last_balance + client_receive_weight - client_dispatch_weight + client_return_weight - client_weight_difference - depletion - user_difference
    @report.push name: '本次结余', milli: milli.call(sum), gram: gram.call(sum), type: :sum

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "黄金流量表(汇总)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def goods_distribution_detail
    milli = ->(sum) { sum }
    gram = ->(sum) { "%.4f" % [sum / 26.717] }
    
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date   
    @report = []

    # 柜台
    user_total = 0
    Record.users(@date).each do |user|
      sum = user.checked_balance_at_date_as_host(@date)
      user_total += sum
      @report.push name: user.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    @report.push name: '柜台合计', milli: milli.call(user_total), gram: gram.call(user_total), type: :sum

    # 工人
    employee_total = 0
    Record.employees(@date).each do |employee|
      sum = employee.users.map {|user| employee.checked_balance_at_date(@date, user, check_type: Record::TYPE_MONTH_CHECK)}.reduce(0, :+)
      employee_total += sum
      @report.push name: employee.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    @report.push name: '工人合计', milli: milli.call(employee_total), gram: gram.call(employee_total), type: :sum

    # 外部客户
    client_total = 0
    Record.clients(@date).each do |client|
      sum = client.users.map {|user| client.checked_balance_at_date(@date, user)}.reduce(0, :+)
      client_total += sum
      @report.push name: client.name, milli: milli.call(sum), gram: gram.call(sum)
    end

    # 外包
    contractor_total = 0
    Record.contractors(@date).each do |contractor|
      sum = contractor.users.map {|user| contractor.checked_balance_at_date(@date, user)}.reduce(0, :+)
      client_total += sum
      @report.push name: contractor.name, milli: milli.call(sum), gram: gram.call(sum)
    end
    ext_client_total = client_total + contractor_total
    @report.push name: '外部客户合计', milli: milli.call(ext_client_total), gram: gram.call(ext_client_total), type: :sum

    # 总计
    total = user_total + employee_total + ext_client_total
    @report.push name: '合计', milli: milli.call(total), gram: gram.call(total), type: :total

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "黄金分布表(明细)#{@date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def goods_in_employees
    @date = params[:date] ? Date.parse(params[:date]) : Time.now.to_date
    @report = []
    total = 0
    Record.employees(@date).each do |employee|
      sum = employee.users.map {|user| employee.checked_balance_at_date(@date, user, check_type: Record::TYPE_MONTH_CHECK)}.reduce(0, :+)
      total += sum
      @report.push name: employee.name, sum: sum, average: "%.2f" % [sum / employee.colleague_number]
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
          balance = employee.balance_at_date(date, user, check_type: nil)
          checked_balance_at_date = employee.checked_balance_at_date(date, user)
          depletion += balance - checked_balance_at_date
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
    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "损耗明细汇总表#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
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

      unless records.size <= 0
        records.each_with_index do |record, i|
          attr = {
              employee_name: (i==0) ? employee.name : '',
              date: record.date,
              product_name: (record.product == nil) ? ('') : (record.product.name),
              produce_weight: record.weight,
              product_num: record.count,
              product_per_employee: "%.2f" % [record.weight/employee.colleague_number]
          }
          @report.push attr
        end

        weight_sum = Record.where('date >= ? AND date <= ? AND participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE).sum('weight')
        attr = {
            employee_name: '合计',
            produce_weight: weight_sum,
            product_per_employee: "%.2f" % [weight_sum/employee.colleague_number],
            type: :total
        }
        @report.push attr
      end
    end
    # for all employee, calc the sum of product weight
    weight_sum = Record.where('date >= ? AND date <= ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, Employee.name, Record::TYPE_RECEIVE).sum('weight')
    attr = {
        employee_name: '总计',
        produce_weight: weight_sum,
        type: :total
    }
    @report.push attr
    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "生产统计表(生产组)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
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
              product_per_employee: (record.participant == nil) ? ('') : ("%.2f" % [record.weight/record.participant.colleague_number])
          }
          @report.push attr
        end
        weight_sum = Record.where('date >= ? AND date <= ? AND product_id = ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, product, Employee.name, Record::TYPE_RECEIVE).sum('weight')
        attr = {
            product_name: '合计',
            produce_weight: weight_sum,
            type: :total
        }
        @report.push attr
      end
    end
    # for all employee, calc the sum of product weight
    weight_sum = Record.where('date >= ? AND date <= ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, Employee.name, Record::TYPE_RECEIVE).sum('weight')
    attr = {
        product_name: '总计',
        produce_weight: weight_sum,
        type: :total
    }
    @report.push attr
    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "生产统计表(品种)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
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
                product_per_employee: "%.2f" % [sum/employee.colleague_number]
            }
            @report.push attr
          end
        end

      end

      # for each employee,each product, calc the sum of weight
      weight_sum = Record.where('date >= ? AND date <= ? AND participant_id = ? AND record_type = ?', @from_date, @to_date, employee, Record::TYPE_RECEIVE).sum('weight')
      unless weight_sum == 0
        attr = {
            employee_name: '合计',
            produce_weight: weight_sum,
            product_per_employee: "%.2f" % [weight_sum/employee.colleague_number],
            type: :sum
        }
        @report.push attr
      end
    end
    # for all employee, calc the sum of product weight
    weight_sum = Record.where('date >= ? AND date <= ? AND participant_type = ? AND record_type = ?', @from_date, @to_date, Employee.name, Record::TYPE_RECEIVE).sum('weight')
    attr = {
        employee_name: '总计',
        produce_weight: weight_sum,
        type: :total
    }
    @report.push attr

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "生产统计表(汇总)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
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
        balance = user.balance_at_date_as_host(date)
        checked_balance_at_date = user.checked_balance_at_date_as_host(date)
        difference = checked_balance_at_date - balance
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

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "各柜台称差明细汇总表#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
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

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "客户称差统计表#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def client_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @clients = Record.clients(@to_date)

    @report = []
    last_balance_row = []
    last_balance_row << '日期'<<'上期实际余额'
    month_dispatch_weight_row = []
    month_receive_weight_row = []
    month_return_weight_row = []
    month_diff_weight_row = []

    month_dispatch_weight_row << '本月合计'<<'交与'
    month_receive_weight_row << '本月合计'<<'收回'
    month_return_weight_row << '本月合计'<<'退货'
    month_diff_weight_row << '本月合计'<<'称差'

    total_last_balance = 0
    all_client_total_month_dispatch_weight = 0
    all_client_total_month_receive_weight = 0
    all_client_total_month_return_weight = 0
    all_client_total_month_diff_weight = 0

    theoretical_balance_row = []
    theoretical_balance_row << '' << '本月余额(理论)'
    all_client_total_balance = 0
    real_balance_row = []
    real_balance_row << '' << '本月余额(实际)'
    all_client_total_real_balance = 0

    @clients.each do |client|
      bal_val = client.users.map {|user| client.balance_before_date(@from_date, user)}.reduce(0, :+)
      last_balance_row << "#{bal_val}"
      total_last_balance += bal_val

      dis_value = client.transactions.of_types(Record::DISPATCH).between_date(@from_date, @to_date).sum('weight')
      rev_value = client.transactions.of_types(Record::RECEIVE).between_date(@from_date, @to_date).sum('weight')
      return_value = client.transactions.of_type(Record::TYPE_RETURN).between_date(@from_date, @to_date).sum('weight')
      weight_diff_value = client.transactions.of_type(Record::TYPE_WEIGHT_DIFFERENCE).between_date(@from_date, @to_date).sum('weight')

      month_dispatch_weight_row << "#{dis_value}"
      month_receive_weight_row << "#{rev_value}"
      month_return_weight_row << "#{return_value}"
      month_diff_weight_row << "#{weight_diff_value}"

      all_client_total_month_dispatch_weight += dis_value
      all_client_total_month_receive_weight += rev_value
      all_client_total_month_return_weight += return_value
      all_client_total_month_diff_weight += weight_diff_value

      theoretical_balance = bal_val + rev_value + return_value - dis_value + weight_diff_value
      all_client_total_balance += theoretical_balance
      theoretical_balance_row << "#{theoretical_balance}"

      real_bal_val = client.users.map {|user| client.checked_balance_at_date(@to_date, user)}.reduce(0, :+)
      real_balance_row << "#{real_bal_val}"
      all_client_total_real_balance += real_bal_val
    end
    last_balance_row << "#{total_last_balance}"
    @report.push values: last_balance_row, type: :head

    (@from_date..@to_date).each do |date|
      total_receive_at_day = 0
      total_dispatch_at_day = 0
      total_return_at_day = 0
      total_weight_diff_at_day = 0

      dispatch_row = []
      receive_row = []
      return_row = []
      diff_weight_row = []
      dispatch_row << date.strftime('%Y-%m-%d') << '交与'
      receive_row << date.strftime('%Y-%m-%d') << '收回'
      return_row << date.strftime('%Y-%m-%d') << '退货'
      diff_weight_row << date.strftime('%Y-%m-%d') << '称差'

      @clients.each do |client|
        rev = client.transactions.of_types(Record::RECEIVE).at_date(date).sum('weight')
        dis = client.transactions.of_types(Record::DISPATCH).at_date(date).sum('weight')
        ret = client.transactions.of_type(Record::TYPE_RETURN).at_date(date).sum('weight')
        dif = client.transactions.of_type(Record::TYPE_WEIGHT_DIFFERENCE).at_date(date).sum('weight')
        dispatch_row << "#{dis}"
        receive_row << "#{rev}"
        return_row << "#{ret}"
        diff_weight_row << "#{dif}"

        total_dispatch_at_day += dis
        total_receive_at_day += rev
        total_return_at_day += ret
        total_weight_diff_at_day += dif
      end
      dispatch_row << "#{total_dispatch_at_day}"
      receive_row << "#{total_receive_at_day}"
      return_row << "#{total_return_at_day}"
      diff_weight_row << "#{total_weight_diff_at_day}"

      @report.push values: dispatch_row
      @report.push values: receive_row
      @report.push values: return_row
      @report.push values: diff_weight_row
    end
    #summary
    month_dispatch_weight_row << "#{all_client_total_month_dispatch_weight}"
    month_receive_weight_row << "#{all_client_total_month_receive_weight}"
    month_return_weight_row << "#{all_client_total_month_return_weight}"
    month_diff_weight_row << "#{all_client_total_month_diff_weight}"
    @report.push values: month_dispatch_weight_row, type: :sum
    @report.push values: month_receive_weight_row, type: :sum
    @report.push values: month_return_weight_row, type: :sum
    @report.push values: month_diff_weight_row, type: :sum

    #today theoretical balance
    theoretical_balance_row << "#{all_client_total_balance}"
    @report.push values: theoretical_balance_row, type: :total

    #today real balance
    real_balance_row << "#{all_client_total_real_balance}"
    @report.push values: real_balance_row, type: :total

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "客户往来台帐(汇总)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def client_transactions_detail
    check_date_range_and_client_param
    @from_date = Date.parse(params[:from_date])
    @to_date = Date.parse(params[:to_date])
    @client = params[:client_id] ? Client.find(params[:client_id]) : Client.first
    @report = []
    last_balance = @client.users.map {|user| @client.balance_before_date(@from_date, user)}.reduce(0, :+)
    @report.push(date: @from_date, last_balance: last_balance, balance: last_balance, type: :sum)

    result = {report: @report, balance: last_balance, check_value: 0}
    (@from_date..@to_date).each do |date|
      @client.users.each do |user|
        result = ext_customer_trans_detail(date: date, user: user, participant: @client, last_balance: result[:balance], last_check_value: result[:check_value])
        @report += result[:report]
      end
    end
    @report += ext_customer_trans_summary(participant: @client, from_date: @from_date, to_date: @to_date, last_balance: last_balance, balance: result[:balance])

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "客户(#{@client.name})往来台帐(明细)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def contractor_transactions
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Time.now.to_date
    @to_date = params[:to_date] ? Date.parse(params[:to_date]) : Time.now.to_date
    @contractors = Record.contractors(@to_date)

    @report = []
    last_balance_row = []
    last_balance_row << '日期'<<'上期实际余额'
    month_dispatch_weight_row = []
    month_receive_weight_row = []
    month_return_weight_row = []
    month_diff_weight_row = []

    month_dispatch_weight_row << '本月合计'<<'交与'
    month_receive_weight_row << '本月合计'<<'收回'
    month_return_weight_row << '本月合计'<<'退货'
    month_diff_weight_row << '本月合计'<<'称差'

    total_last_balance = 0
    all_contractor_total_month_dispatch_weight = 0
    all_contractor_total_month_receive_weight = 0
    all_contractor_total_month_return_weight = 0
    all_contractor_total_month_diff_weight = 0

    theoretical_balance_row = []
    theoretical_balance_row << '' << '本月余额(理论)'
    all_contractor_total_balance = 0
    real_balance_row = []
    real_balance_row << '' << '本月余额(实际)'
    all_contractor_total_real_balance = 0

    @contractors.each do |contractor|
      bal_val = contractor.users.map {|user| contractor.balance_before_date(@from_date, user)}.reduce(0, :+)
      last_balance_row << "#{bal_val}"
      total_last_balance += bal_val

      dis_value = contractor.transactions.of_types(Record::DISPATCH).between_date(@from_date, @to_date).sum('weight')
      rev_value = contractor.transactions.of_types(Record::RECEIVE).between_date(@from_date, @to_date).sum('weight')
      return_value = contractor.transactions.of_type(Record::TYPE_RETURN).between_date(@from_date, @to_date).sum('weight')
      weight_diff_value = contractor.transactions.of_type(Record::TYPE_WEIGHT_DIFFERENCE).between_date(@from_date, @to_date).sum('weight')

      month_dispatch_weight_row << "#{dis_value}"
      month_receive_weight_row << "#{rev_value}"
      month_return_weight_row << "#{return_value}"
      month_diff_weight_row << "#{weight_diff_value}"

      all_contractor_total_month_dispatch_weight += dis_value
      all_contractor_total_month_receive_weight += rev_value
      all_contractor_total_month_return_weight += return_value
      all_contractor_total_month_diff_weight += weight_diff_value

      theoretical_balance = bal_val + rev_value + return_value - dis_value + weight_diff_value
      all_contractor_total_balance += theoretical_balance
      theoretical_balance_row << "#{theoretical_balance}"

      real_bal_val = contractor.users.map {|user| contractor.checked_balance_at_date(@to_date, user)}.reduce(0, :+)
      real_balance_row << "#{real_bal_val}"
      all_contractor_total_real_balance += real_bal_val
    end
    last_balance_row << "#{total_last_balance}"
    @report.push values: last_balance_row, type: :head

    (@from_date..@to_date).each do |date|
      total_receive_at_day = 0
      total_dispatch_at_day = 0
      total_return_at_day = 0
      total_weight_diff_at_day = 0

      dispatch_row = []
      receive_row = []
      return_row = []
      diff_weight_row = []
      dispatch_row << date.strftime('%Y-%m-%d') << '交与'
      receive_row << date.strftime('%Y-%m-%d') << '收回'
      return_row << date.strftime('%Y-%m-%d') << '退货'
      diff_weight_row << date.strftime('%Y-%m-%d') << '称差'

      @contractors.each do |contractor|
        rev = contractor.transactions.of_types(Record::RECEIVE).at_date(date).sum('weight')
        dis = contractor.transactions.of_types(Record::DISPATCH).at_date(date).sum('weight')
        ret = contractor.transactions.of_type(Record::TYPE_RETURN).at_date(date).sum('weight')
        dif = contractor.transactions.of_type(Record::TYPE_WEIGHT_DIFFERENCE).at_date(date).sum('weight')
        dispatch_row << "#{dis}"
        receive_row << "#{rev}"
        return_row << "#{ret}"
        diff_weight_row << "#{dif}"

        total_dispatch_at_day += dis
        total_receive_at_day += rev
        total_return_at_day += ret
        total_weight_diff_at_day += dif
      end
      dispatch_row << "#{total_dispatch_at_day}"
      receive_row << "#{total_receive_at_day}"
      return_row << "#{total_return_at_day}"
      diff_weight_row << "#{total_weight_diff_at_day}"

      @report.push values: dispatch_row
      @report.push values: receive_row
      @report.push values: return_row
      @report.push values: diff_weight_row
    end
    #summary
    month_dispatch_weight_row << "#{all_contractor_total_month_dispatch_weight}"
    month_receive_weight_row << "#{all_contractor_total_month_receive_weight}"
    month_return_weight_row << "#{all_contractor_total_month_return_weight}"
    month_diff_weight_row << "#{all_contractor_total_month_diff_weight}"
    @report.push values: month_dispatch_weight_row, type: :sum
    @report.push values: month_receive_weight_row, type: :sum
    @report.push values: month_return_weight_row, type: :sum
    @report.push values: month_diff_weight_row, type: :sum

    #today theoretical balance
    theoretical_balance_row << "#{all_contractor_total_balance}"
    @report.push values: theoretical_balance_row, type: :total

    #today real balance
    real_balance_row << "#{all_contractor_total_real_balance}"
    @report.push values: real_balance_row, type: :total

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "外工厂往来台帐(汇总)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end

  def contractor_transactions_detail
    check_date_range_and_contractor_param
    @from_date = Date.parse(params[:from_date])
    @to_date = Date.parse(params[:to_date])
    @contractor = params[:contractor_id] ? Contractor.find(params[:contractor_id]) : Contractor.first
    @report = []
    last_balance = @contractor.users.map {|user| @contractor.balance_before_date(@from_date, user)}.reduce(0, :+)
    @report.push(date: @from_date, last_balance: last_balance, balance: last_balance, type: :sum)

    result = {report: @report, balance: last_balance, check_value: 0}
    (@from_date..@to_date).each do |date|
      @contractor.users.each do |user|
        result = ext_customer_trans_detail(date: date, user: user, participant: @contractor, last_balance: result[:balance], last_check_value: result[:check_value])
        @report += result[:report]
      end
    end
    @report += ext_customer_trans_summary(participant: @contractor, from_date: @from_date, to_date: @to_date, last_balance: last_balance, balance: result[:balance])

    respond_to do |format|
      format.html
      format.js
      format.xlsx {
        filename = "外工厂(#{@contractor.name})往来台帐(明细)#{@from_date}至#{@to_date}"
        response.headers['Content-Disposition'] = %Q(attachment; filename="#{filename}.xlsx")
      }
    end
  end
end

module StatisticsCommon
  # user为nil时，表示所有柜台
  def _weight_of_types_at_date(records, types, date, user)
    records = records.created_by_user(user) if user
    records.of_types(types).at_date(date).sum('weight')
  end
  
  def _weight_of_types_between_date_exclusive(records, types, begin_date, end_date, user)
    records = records.created_by_user(user) if user
    records.of_types(types).between_date_exclusive(begin_date, end_date).sum('weight')
  end
  
  def _weight_of_types_between_date(records, types, begin_date, end_date, user)
    records = records.created_by_user(user) if user
    records.of_types(types).between_date(begin_date, end_date).sum('weight')
  end
  
  def _weights_at_date(records, date, user)
    dispatch_weight = _weight_of_types_at_date(records, Record::DISPATCH, date, user)
    receive_weight = _weight_of_types_at_date(records, Record::RECEIVE, date, user)
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
  
  def weights_at_date(date, user=nil)
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
    balance -= _weight_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance += _weight_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance += _weight_of_types_between_date_exclusive(self.transactions, [Record::TYPE_RETURN], check_date, date, user)
    balance += _weight_of_types_between_date_exclusive(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user)
    last_balance = balance_before_date(date, user)
    dispatch_weight, receive_weight = weights_at_date(date, user)
    last_balance - dispatch_weight + receive_weight
  end
  
  def checked_balance_at_date(date, user)
    _checked_balance_at_date(self.transactions, date, user, nil) do 
      balance_before_date(date + 1.day, user)
    end
  end

  def weights_at_date(date, user=nil)
    dispatch_weight, receive_weight = _weights_at_date(self.transactions, date, user)
    receive_weight += _weight_of_types_at_date(self.transactions, [Record::TYPE_RETURN], date, user)
    # receive_weight += _weight_of_types_at_date(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], date, user)
    [dispatch_weight, receive_weight]
  end
  
  def difference_at_date(date, user=nil)
    _weight_of_types_at_date(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], date, user)
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
  
  def dispatch_weight_between_date(begin_date, end_date, user=nil)
    _weight_of_types_between_date(self.transactions, [Record::TYPE_RECEIVE], begin_date, end_date, user)
  end
  
  def receive_weight_between_date(begin_date, end_date, user=nil)
    _weight_of_types_between_date(self.transactions, [Record::TYPE_DISPATCH], begin_date, end_date, user)
  end
  
  def return_weight_between_date(begin_date, end_date, user=nil)
    _weight_of_types_between_date(self.transactions, [Record::TYPE_RETURN], begin_date, end_date, user)
  end
  
  def weight_difference_between_date(begin_date, end_date, user=nil)
    _weight_of_types_between_date(self.transactions, [Record::TYPE_WEIGHT_DIFFERENCE], begin_date, end_date, user)
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
    balance += _weight_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance -= _weight_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user, check_type: Record::TYPE_MONTH_CHECK)
    last_balance = balance_before_date(date, user, check_type: check_type)
    dispatch_weight, receive_weight = weights_at_date(date, user)
    last_balance + dispatch_weight - receive_weight
  end
  
  # 默认查找月盘点或日盘点
  def checked_balance_at_date(date, user, check_type: nil)
    _checked_balance_at_date(self.transactions, date, user, check_type) do
      balance_before_date(date + 1.day, user, check_type: check_type)
    end
  end
  
  # Done
  def depletion_between_date(begin_date, end_date, user)
    begin_checked_balance = checked_balance_at_date(begin_date - 1.day, user, check_type: nil)
    end_checked_balance = balance_before_date(end_date + 1.day, user, check_type: nil)
    receive_weight = _weight_of_types_between_date(self.transactions, Record::DISPATCH, begin_date, end_date, user)
    dispatch_weight = _weight_of_types_between_date(self.transactions, Record::RECEIVE, begin_date, end_date, user)
    begin_checked_balance + receive_weight - dispatch_weight - end_checked_balance
  end
end

User.class_eval do
  include StatisticsCommon
  
  def balance_before_date(date, user)
    balance, check_date, check_type = _checked_balance_before_date(self.transactions, date, user, nil)
    balance += _weight_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, user)
    balance -= _weight_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, user)
    balance
  end
  
  def balance_at_date(date, user)
    last_balance = balance_before_date(date, user)
    dispatch_weight, receive_weight = weights_at_date(date, user)
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
    balance -= _weight_of_types_between_date_exclusive(self.records, Record::DISPATCH, check_date, date, self)
    # 收货
    balance += _weight_of_types_between_date_exclusive(self.records, Record::RECEIVE, check_date, date, self)
    # 客户退货
    balance += _weight_of_types_between_date_exclusive(self.records, [Record::TYPE_RETURN], check_date, date, self)
    # 去别的柜台交易
    trade_with_other_user = _weight_of_types_between_date_exclusive(self.transactions, Record::DISPATCH, check_date, date, nil)
    trade_with_other_user -= _weight_of_types_between_date_exclusive(self.transactions, Record::RECEIVE, check_date, date, nil)
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
    return_weight = _weight_of_types_at_date(self.records, [Record::TYPE_RETURN], date, self)
    
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
