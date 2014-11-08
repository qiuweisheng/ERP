class Employee < ActiveRecord::Base
  has_many :transactions, as: :participant, class_name: 'Record'
  has_many :records
  belongs_to :department

  validates :name, presence: true
  validates :department_id, presence: true

  MIN_ID = 10001
  MAX_ID = Rails.env == 'test' ? 10010 : 19999

  include SerialNumber
  has_serial_number
end
