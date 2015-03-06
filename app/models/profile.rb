class Profile < ActiveRecord::Base
  INTEGER_TYPE = "Integer"
  DATE_TYPE = "Date"

  validates :value, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 31, message: '该值必须为1-31的数字'}, if: lambda {|profile| profile.value_type == INTEGER_TYPE}
  
  class << self
    def Profile.create_if_needed(key, type)
      profile = where("key = ?", key).first
      unless profile
        profile = new(key: key, value: "", value_type: type)
        profile.save(validate: false)
      end
      profile
    end
  end
end
