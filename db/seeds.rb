# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.delete_all

User.create([
    {
        name: '0',
        password: 'z',
        permission: 3
    },
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

product_name_array = []
create_product_para = []
f = File.open("./db/product.txt")
f.each_line { |line|
  product_name = line
  product_name_array<<product_name
  create_product_para<<{name: product_name}
}
Product.create({name: '0'})
Product.create(create_product_para)


Client.delete_all

Client.create({name: '0'})
Client.create([
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

Department.create({name: '0'})
Department.create([
    # d1
    { name: '车花' },
    # d2
    { name: '倒模' },
    { name: '开料' },
    { name: '空心双扣' },
    { name: '熔金' },
    { name: '闪沙' },
    { name: '手厄' },
    { name: '手工链' },
    { name: '手环' },
    { name: '手环开料' },
    { name: '手环闪沙' },
    { name: '手啤' },
    { name: '珍粟' },
    { name: '执模' },
    { name: '珠链' },
])

Employee.delete_all

d1 = Department.find_by(name: '车花').id
d2 = Department.find_by(name: '倒模').id


Employee.create({name: '0',
                 department_id: d1
                })
Employee.create([
    {
        name: '曾灵',
        department_id: d1
    },
    {
        name: '陈海洪',
        department_id: d1
    },
    {
        name: '陈海华',
        department_id: d1
    },
    {
        name: '陈丽菊',
        department_id: d2
    },
    {
        name: '陈丽菊',
        department_id: d2
    },
    {
        name: '陈万全',
        department_id: d2
    },
    {
        name: '陈学文',
        department_id: d2
    },
    {
        name: '邓美玲',
        department_id: d2
    },
    {
        name: '冯惠通',
        department_id: d2
    },
    {
        name: '高开轼',
        department_id: d2
    },
    {
        name: '洪伟强',
        department_id: d2
    },
    {
        name: '胡押金',
        department_id: d2
    },
    {
        name: '兰文杰',
        department_id: d2
    },
    {
        name: '李冠刚',
        department_id: d2
    },
    {
        name: '李日升',
        department_id: d2
    },
    {
        name: '连建珍',
        department_id: d2
    },
    {
        name: '林日兴',
        department_id: d2
    },
    {
        name: '刘双龙',
        department_id: d2
    },
    {
        name: '邱巧会',
        department_id: d2
    },
    {
        name: '危建芳',
        department_id: d2
    },
    {
        name: '吴锡文',
        department_id: d2
    },
    {
        name: '伍坎良',
        department_id: d2
    },
    {
        name: '伍妹',
        department_id: d2
    },
    {
        name: '谢家发',
        department_id: d2
    },
    {
        name: '杨务春',
        department_id: d2
    },
    {
        name: '余汉金',
        department_id: d2
    },
])

Contractor.create({name: '0'})
Contractor.create([
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

create_record_para = []
f = File.open("./db/record.txt")
f.each_line { |line|
  v1,v2,v3,v4,v5,v6,v7,v8,v9=line.split("\t")
  participant_class = v8.strip.classify.constantize
  create_record_para << {record_type: v1.strip.to_i,
                        origin_id: Product.find_by(name: product_name_array[0]).id,
                        product_id: Product.find_by(name: product_name_array[0]).id,
                        weight: v4.strip.to_i,
                        count: v5.strip.to_i,
                        user_id: User.find_by(name: v6.strip).id,
                        participant_id: participant_class.find_by(name: v7.strip).id,
                        participant_type: v8.strip,
                        date: Date.parse(v9)
                        }
}
p create_record_para
Record.create!(create_record_para)

