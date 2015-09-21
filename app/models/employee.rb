class Employee < ActiveRecord::Base
  MIN_ID = 31
  MAX_ID = 80 #Rails.env == 'test' ? 10000 : 1000
  
  include State
  include SerialNumber
  has_serial_number

  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records
  belongs_to :department

  validates :name, presence: { message: '请输入组长名称'}
  validates :name, uniqueness: {message: '名称已使用,请重新填写组长名称'}
  validates :department_id, presence: { message: '请输入部门名称'}
  validates :colleague_number, presence: { message: '请输入部门人数(大于0的整数)' }
  validates :colleague_number, numericality: { greater_than: 0, message: '请输入部门人数(大于0的整数)' }
end
