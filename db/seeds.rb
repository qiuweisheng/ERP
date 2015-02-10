# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create!([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create!(name: 'Emanuel', city: cities.first)

User.delete_all

User.create!([
    {
        name: '老板',
        password: 'z',
        permission: 0
    },
    {
        name: '经理',
        password: 'z',
        permission: 1
    },
    {
        name: '收发部',
        password: 'z',
        permission: 2
    },
    {
        name: '黄滢仪',
        password: 'z',
        permission: 3
    },
    {
        name: '叶静娇',
        password: 'z',
        permission: 3
    },
    {
        name: '付田',
        password: 'z',
        permission: 3
    },
    {
        name: '李意璇',
        password: 'z',
        permission: 3
    },
    {
        name: '林太1',
        password: 'z',
        permission: 3
    },
    {
        name: '林太2',
        password: 'z',
        permission: 3
    },
])

Product.delete_all

open('./db/product.txt', 'r:bom|utf-8') do |file|
  file.each_line do |line|
    Product.create!(name: line.strip) unless line.strip.empty?
  end
end


Client.delete_all

Client.create!({name: '0'})
Client.create!([
    # c1
    { name: '王老板' },
    # c2
    { name: '陈老板' },
    # c3
    { name: '张老板' },
    # c4
    { name: '周老板' },
    # c5
    { name: '李老板' },
    # c6
    { name: '克徕帝' },
    # c7
    { name: '六福' },
    # c8
    { name: '崔琦' },
    # c9
    { name: '华友' },
    # c10
    { name: '金福佳' },
    # c11
    { name: '金嘉福' },
    # c12
    { name: '六六福' },
    # c13
    { name: 'TSL' }
])

Department.delete_all

open('./db/department.txt', 'r:bom|utf-8') do |file|
  file.each_line do |line|
    Department.create!(name: line.strip) unless line.strip.empty?
  end
end

Employee.delete_all

open('./db/employee.txt') do |file|
  file.each_line do |line|
    unless line.strip.empty?
      name, department, colleague_number = line.strip.split(/\s+/)
      Employee.create!(
          name: name,
          department_id: Department.find_by(name: department).id,
          colleague_number: colleague_number
      )
    end
  end
end

#Client.delete_all
#Client.create!([
#  {name: 'DEE'},
#  {name: 'CRD'},
#  {name: 'TSL'},
#  {name: '金兴利'},
#  {name: '周小姐'},
#  {name: '兴劢'},
#  {name: '权淦'},
#  {name: '古太'}
#])

Contractor.delete_all
Contractor.create!([
  {name: '晋圣'},
  {name: '高纯亮'},
  {name: '莫泽超'},
  {name: '德隆'},
  {name: '鑫宏'},
  {name: '鸿艺'},
  {name: '兆嘉'},
  {name: '杨永舒'},
  {name: '新新星'},
  {name: '宝泰鑫'},
  {name: '乾鑫'},
  {name: '西普'}
])

class Record < ActiveRecord::Base
  TYPE_DISPATCH          = 0
  TYPE_RECEIVE           = 1
  TYPE_PACKAGE_DISPATCH  = 2
  TYPE_PACKAGE_RECEIVE   = 3
  TYPE_POLISH_DISPATCH   = 4
  TYPE_POLISH_RECEIVE    = 5
  TYPE_DAY_CHECK         = 6
  TYPE_MONTH_CHECK       = 7
  YTPE_APPORTION         = 8
  TYPE_RETURN            = 9
  TYPE_WEIGHT_DIFFERENCE = 10


  RECORD_TYPES = {
      '发货' => TYPE_DISPATCH,
      '收货' => TYPE_RECEIVE,
      '<包装>发货' => TYPE_PACKAGE_DISPATCH,
      '<包装>收货' => TYPE_PACKAGE_RECEIVE,
      '<打磨>发货' => TYPE_POLISH_DISPATCH,
      '<打磨>收货' => TYPE_POLISH_RECEIVE,
      '<日>盘点' => TYPE_DAY_CHECK,
      '<月>盘点' => TYPE_MONTH_CHECK,
      '打磨分摊' => YTPE_APPORTION,
      '客户退货' => TYPE_RETURN,
      '客户称差' => TYPE_WEIGHT_DIFFERENCE
  }
end

Record.delete_all

open('./db/record.txt', 'r:bom|utf-8') do |file|
  file.each_line do |line|
    unless line.strip.empty?
      type, _, product, weight, count, user, participant, klass, date = line.strip.split(/\s+/)
      Record.create!({
          record_type: Record::RECORD_TYPES[type],
          product_id: Product.find_by(name: product).try(:id),
          weight: weight.to_f,
          count: count.to_i,
          user_id: User.find_by(name: user).id,
          participant_id: klass.classify.constantize.find_by(name:participant).id,
          participant_type: klass,
          date: Date.parse(date)
      })
    end
  end
end
