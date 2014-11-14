class Record < ActiveRecord::Base
  PARTICIPANT_CLASS_NAMES = [:user, :employee, :client, :contractor]
  RECORD_TYPES = { 0 => '收货', 1 => '发货',  2 => '日盘点', 3 => '月盘点', 4 => '补差额' }

  belongs_to :origin, class_name: 'Product'
  belongs_to :product
  belongs_to :user
  belongs_to :participant, polymorphic: true
  belongs_to :employee
  belongs_to :client

  validates :date_text, presence: { message: '日期必须填写'}
  validates :type_text, presence: { message: '类型必须填写'}
  validates :type_text, inclusion: { in: 0..4, message: "类型必须为：#{RECORD_TYPES.values.join('、')}" }
  validates :origin_text, presence: { message: '原料必须填写'}
  validates :product_text, presence: { message: '成品必须填写'}
  validates :weight, presence: { message: '重量必须填写'}
  validates :weight, numericality: { greater_than_or_equal_to: 0.0, message: '重量必须大于或等于0.0' }
  validates :count, presence: { message: '件数必须填写'}
  validates :count, numericality: { greater_than_or_equal_to: 0, message: '件数必须大于或等于0' }
  validates :user_text, presence: { message: '柜台必须填写'}
  validates :participant_text, presence: { message: '收发人必须填写'}
  validates :participant_type, presence: { message: '收发人类型必须填写'}

  def date_text
    date.try(:strftime, "%Y-%m-%d")
  end

  def date_text=(text)
    self.date = Date.parse(text) rescue nil
  end

  def type_text
    unless RECORD_TYPES[record_type]
      return ''
    end
    "#{record_type}-#{RECORD_TYPES[record_type]}"
  end

  def type_text=(text)
    value, name = text.strip.split('-')
    value = value.to_i
    self.record_type = RECORD_TYPES[value] == name ? value : nil
  end

  [:origin, :product, :user, :participant, :employee, :client].each do |name|
    class_eval <<-END
      def #{name}_text
        #{name}.to_s
      end
    END
  end

  [:origin, :product, :user, :participant, :employee, :client].each do |name|
    class_eval <<-END
      def #{name}_text=(text)
        self.#{name} = represent_to_object #{name.to_s.classify}, text
      end
    END
  end

  def origin_text=(text)
    self.origin = represent_to_object Product, text
  end

  def participant=(text)
    serial_number = text.strip.split('-').first.to_i
    class_name = PARTICIPANT_CLASS_NAMES.find do |name|
      klass = name.classify.constantize
      (klass::MIN_ID..klass::MAX_ID).include? serial_number
    end
    self.participant = represent_to_object class_name.classify.constantize, text
  end

  protected
    def represent_to_object(klass, text)
      serial_number, name = text.strip.split('-')
      klass.where(serial_number: serial_number, name: name).first
    end
end
