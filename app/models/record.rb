class Record < ActiveRecord::Base
  PARTICIPANT_CLASS_NAMES = [:user, :employee, :client, :contractor]
  
  TYPE_DISPATCH          = 0
  TYPE_RECEIVE           = 1
  TYPE_PACKAGE_DISPATCH  = 2
  TYPE_PACKAGE_RECEIVE   = 3
  TYPE_POLISH_DISPATCH   = 4
  TYPE_POLISH_RECEIVE    = 5
  TYPE_DAY_CHECK         = 6
  TYPE_MONTH_CHECK       = 7
  TYPE_APPORTION         = 8
  TYPE_RETURN            = 9
  TYPE_WEIGHT_DIFFERENCE = 10
  
  
  RECORD_TYPES = { 
    TYPE_DISPATCH          => '发货',
    TYPE_RECEIVE           => '收货',
    TYPE_PACKAGE_DISPATCH  => '<包装>发货',
    TYPE_PACKAGE_RECEIVE   => '<包装>收货',
    TYPE_POLISH_DISPATCH   => '<打磨>发货',
    TYPE_POLISH_RECEIVE    => '<打磨>收货',
    TYPE_DAY_CHECK         => '<日>盘点', 
    TYPE_MONTH_CHECK       => '<月>盘点', 
    TYPE_APPORTION         => '打磨分摊',
    TYPE_RETURN            => '客户退货',
    TYPE_WEIGHT_DIFFERENCE => '客户称差' 
  }
  
  DISPATCH = [TYPE_DISPATCH, TYPE_PACKAGE_DISPATCH, TYPE_POLISH_DISPATCH]
  RECEIVE = [TYPE_RECEIVE, TYPE_PACKAGE_RECEIVE, TYPE_POLISH_RECEIVE]

  belongs_to :product
  belongs_to :user
  belongs_to :participant, polymorphic: true
  belongs_to :employee
  belongs_to :client

  validates :date_text, presence: { message: '请填写日期'}
  validates :record_type, presence: { message: '请选择记录类型'}
  validates :record_type, inclusion: { in: RECORD_TYPES.keys, message: "类型必须为：#{RECORD_TYPES.values.join('、')}" }
  validates :product_text, presence: { message: '请选择摘要'}, unless: Proc.new { |record| [TYPE_DAY_CHECK, TYPE_MONTH_CHECK, TYPE_APPORTION, TYPE_WEIGHT_DIFFERENCE].include? record.record_type }
  validates :weight, presence: { message: '请填写重量'}
  validates :count, numericality: { greater_than_or_equal_to: 0, message: '件数必须大于或等于0' }, allow_blank: true
  validates :user_id, presence: { message: '请选择柜台'}
  validates :participant_text, presence: { message: '请选择交收人'}
  with_options if: :is_package_type? do |r|
    r.validates :order_number, presence: { message: '请填写单号' }
    r.validates :order_number, uniqueness: {message: '单号已使用'}
    r.validates :client_text, presence: { message: '请选择客户' }
  end
  #validates :employee_text, presence: { message: '请选择生产人' }, if: :is_polish_type?
  def date_text
    date.try(:strftime, "%Y-%m-%d")
  end

  def date_text=(text)
    self.date = Date.parse(text) rescue nil
  end

  [:product, :participant, :employee, :client].each do |name|
    class_eval <<-END
      def #{name}_text
        #{name}.to_s
      end
      def #{name}_text=(text)
        self.#{name} = represent_to_object #{name.to_s.classify}, text
      end
    END
  end

  def participant_text=(text)
    serial_number = text.strip.split('-').first.to_i
    participant = nil
    PARTICIPANT_CLASS_NAMES.find do |name|
      klass = name.to_s.classify.constantize
      participant = represent_to_object(klass, text)
    end
    self.participant = participant if participant
  end

  protected
    def represent_to_object(klass, text)
      serial_number, name = text.strip.split('-')
      klass.where(serial_number: serial_number, name: name).first
    end
    
    def is_polish_type?
      [TYPE_POLISH_DISPATCH, TYPE_POLISH_RECEIVE].include? self.record_type
    end
    
    def is_package_type?
      [TYPE_PACKAGE_DISPATCH, TYPE_PACKAGE_RECEIVE].include? self.record_type
    end
    
    def is_polish_or_package_type?
      is_polish_type? or is_package_type?
    end

  # Class Methods
  class << self
    def participants(date=nil)
      date = Time.now.to_date unless date
      group = self.where('date <= ? AND participant_type != ?', date, User.name).group('participant_id')
                .collect  { |record| record.participant }
                .group_by { |p| p.class }
      [Employee, Contractor, Client]
        .map { |c| group[c] }
        .select { |p| p }
        .flatten
    end

    def users(date=nil)
      date = Time.now.to_date unless date
      self.where('date <= ?', date).group('user_id').collect do |record|
        record.user
      end
    end

    def employees(date=nil)
      date = Time.now.to_date unless date
      self.where('date <= ? AND participant_type = ?', date, Employee.name).collect do |record|
        result = [record.participant]
        result.push record.employee if record.employee
        result
      end.flatten.uniq
    end
    
    def clients(date=nil)
      date = Time.now.to_date unless date
      self.where('date <= ? AND participant_type = ?', date, Client.name).group('participant_id').collect do |record|
        record.participant
      end
    end
    
    def contractors(date=nil)
      date = Time.now.to_date unless date
      self.where('date <= ? AND participant_type = ?', date, Contractor.name).group('participant_id').collect do |record|
        record.participant
      end
    end
  end
  
  scope :of_type, lambda {|type| where("record_type = ?", type)}
  scope :of_types, lambda {|types|
    sql = types.map {"record_type = ?"}.join(" OR ")
    where(sql, *types)
  }
  scope :at_date, lambda {|date| where("date = ?", date)}
  scope :before_date, lambda {|date| where("date <= ?", date)}
  scope :between_date_exclusive, lambda {|begin_date, end_date| where('date > ? AND date < ?', begin_date, end_date)}
  scope :between_date, lambda {|begin_date, end_date| where('date >= ? AND date <= ?', begin_date, end_date)}
  scope :created_by_user, lambda {|user| where("user_id = ?", user)}
  scope :of_participant, lambda {|participant| where("participant_id = ? AND participant_type = ?", participant, participant.class.name)}
  scope :of_participant_type, lambda {|participant_class| where("participant_type = ?", participant_class.name)}
  scope :of_not_participant_type, lambda {|participant_class| where("participant_type != ?", participant_class.name)}
end
