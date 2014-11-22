class User < ActiveRecord::Base
  MIN_ID = 1
  MAX_ID = Rails.env == 'test' ? 10 : 9999
  PERM_SUPER     = 0
  PERM_ADMIN     = 1
  PERM_LEVEL_ONE = 2
  PERM_LEVEL_TWO = 3
  PERMISSION_TYPES = { 0 =>'超级用户', 1 => '管理员', 2 => '一级柜台', 3 => '二级柜台' }
  
  include State
  include SerialNumber
  has_serial_number

  has_secure_password

  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records

  validates :name, presence: { message: '名称必须填写'}
  validates :password, presence: { message: '密码必须填写'}
  validates :permission, presence: { message: '类型必须选择'}
  validates :permission, inclusion: { in: 0..3, message: "类型必须为：#{PERMISSION_TYPES.values.join('、')}" }
  validates_each :permission, on: :create do |record, attr, value|
    if value == 0 and record.class.where(attr => 0).count > 0
      record.errors.add(attr, '只能有一个超级用户')
    end
  end
  validates_each :permission, on: :update do |record, attr, value|
    unless record.class.find(record.id).send(attr) == value
      record.errors.add(attr, '不能修改权限')
    end
  end
end
