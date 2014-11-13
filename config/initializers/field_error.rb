ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag =~ /<label/
    html_tag
  else
    "<div class=\"field_with_errors\">#{html_tag}</div>".html_safe
  end
end