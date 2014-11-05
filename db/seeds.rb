# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.delete_all

User.create(
    name: '老板',
    password: 'z',
    permission: 0
)

User.create(
    name: '经理',
    password: 'z',
    permission: 1
)

User.create(
    name: '收发部',
    password: 'z',
    permission: 2
)

User.create(
    name: '柜台',
    password: 'z',
    permission: 3
)

