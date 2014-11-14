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
        name: '001游玲',
        password: 'z',
        permission: 3
    },
    {
        name: '002陈仪雅',
        password: 'z',
        permission: 3
    },
    {
        name: '003陈小艳',
        password: 'z',
        permission: 3
    },
    {
        name: '004颜锦枝',
        password: 'z',
        permission: 3
    }
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
    { name: '李老板' }
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
      name, department = line.strip.split(/\s+/)
      Employee.create!(name: name, department_id: Department.find_by(name: department).id)
    end
  end
end

Contractor.delete_all
Contractor.create!([
  {name: 'DEE'},
  {name: 'CRD'},
  {name: 'TSL'},
  {name: '金兴利'},
  {name: '周小姐'},
  {name: '兴劢'},
  {name: '权淦'},
  {name: '古太'}
])

class Record < ActiveRecord::Base
end

Record.delete_all

open('./db/record.txt', 'r:bom|utf-8') do |file|
  file.each_line do |line|
    unless line.strip.empty?
      type, origin, product, weight, count, user, participant, klass, date = line.strip.split(/\s+/)
      Record.create!({
          record_type: type.to_i,
          origin_id: Product.find_by(name: origin).try(:id),
          product_id: Product.find_by(name: product).try(:id),
          weight: weight.to_i,
          count: count.to_i,
          user_id: User.find_by(name: user).id,
          participant_id: klass.classify.constantize.find_by(name:participant).id,
          participant_type: klass,
          date: Date.parse(date)
      })
    end
  end
end