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
        name: '柜台1',
        password: 'z',
        permission: 3
    }
])

Product.delete_all

Product.create([
    { name: '金砂' },
    { name: '猪' },
    { name: '锁咀' },
    { name: '耳迫' },
    { name: '光珠手链' },
    { name: '珠间筒颈链' }
])

Client.delete_all

Client.create([
    { name: '王老板' },
    { name: '陈老板' },
    { name: '张老板' },
    { name: '周老板' },
    { name: '李老板' },
])

Employee.delete_all

Employee.create([
    { name: '胡押金' },
    { name: '陈祖业' },
    { name: '黄金生' },
    { name: '王大锤' },
])
