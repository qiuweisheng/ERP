module ReportsHelper
  def data_with_precision(num)
    if num != nil && (num.class==BigDecimal || num.class==Float || num.class==Fixnum)
      n = get_data_precision
      if n < 0
        n = 0
      end
      if n > 6
        n = 6
      end
      r = "%.#{n}f" % [num]
    else
      num
    end
  end
end
