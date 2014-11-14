class ReportsController < ApplicationController
  def day
    date = Date.parse('2014-11-12')
    user = User.find_by(name: '001游玲')
    user.records.where(date: date).group()
  end
end
