# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

show_record_input_field = ->
  select_field = $('#record_record_type')
  
  if select_field.length
    switch parseInt select_field.val()
      # 发货、收货、客户退货
      when 0, 1, 9
        row_ids = ['#type_select','#participant','#product','#weight','#count','#date']
      # <包装>发货、<包装>收货
      when 2, 3
        row_ids = ['#type_select','#participant','#product','#weight','#count','#order_number','#client','#date']
      # <打磨>发货、<打磨>收货
      when 4, 5
        row_ids = ['#type_select','#participant','#product','#weight','#count','#order_number','#client','#employee','#date']
      # <日>盘点、<月>盘点
      when 6, 7
        row_ids = ['#type_select','#participant','#weight','#date']
      # 打磨分摊
      when 8
        row_ids = ['#type_select','#participant','#weight','#employee','#date']
      # 客户称差
      when 10
        row_ids = ['#type_select','#participant','#product','#weight','#date']
    $('#new_record tbody tr').hide()
    $(row_ids.join()).show()
  
    
  
$(document).on "page:change", ->
  show_record_input_field()
  $('#record_record_type').change ->
    show_record_input_field()
    $('#error_explanation').remove()
    $('.field_with_errors input').unwrap()