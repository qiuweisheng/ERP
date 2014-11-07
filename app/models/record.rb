class Record < ActiveRecord::Base
  belongs_to :origin, class_name: 'Product'
  belongs_to :product
  belongs_to :user
  belongs_to :client, polymorphic: true

  validates :record_type, presence: true
  validates :origin_id, presence: true
  validates :product_id, presence: true
  validates :weight, presence: true, numericality: { greater_than_or_equal_to: 0.0 }
  validates :count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, presence: true
  validates :client_id, presence: true
  validates :client_type, presence: true
end
