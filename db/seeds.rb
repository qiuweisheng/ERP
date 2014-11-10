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
        name: '柜台1',
        password: 'z',
        permission: 3
    },
    {
        name: '柜台2',
        password: 'z',
        permission: 3
    }
])

Product.delete_all

Product.create([
    # p1
    { name: '金砂' },
    # p2
    { name: '猪' },
    # p3
    { name: '锁咀' },
    # p4
    { name: '耳迫' },
    # p5
    { name: '光珠手链' },
    # p6
    { name: '珠间筒颈链' }
])

Client.delete_all

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

Department.create([
    # d1
    { name: '车花' },
    # d2
    { name: '倒模' },
    { name: '开料' },
    { name: '空心双扣' },
    { name: '熔金' },
    { name: '闪沙' },
])

Employee.delete_all

d1 = Department.find_by(name: '车花').id
d2 = Department.find_by(name: '倒模').id

Employee.create([
    {
        name: '胡押金',
        department_id: d1
    },
    {
        name: '陈祖业',
        department_id: d1
    },
    {
        name: '黄金生',
        department_id: d1
    },
    {
        name: '王大锤',
        department_id: d2
    },
])

Contractor.delete_all

Contractor.create([
    { name: '新新星' }
])

# Record.delete_all
#
# Record.create([
#     { record_type: 2, origin_id:}
# ])