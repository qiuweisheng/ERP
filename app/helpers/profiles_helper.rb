module ProfilesHelper
  def name_of_profile(profile)
    case profile.key
      when 'month_check_date'
        '月盘点日'
      else
        ''
    end
  end
end
