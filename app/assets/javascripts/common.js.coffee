set_layout = ->
  $sidebar = $('#sidebar')
  if $sidebar.length isnt 0
    $sidebar.css height: $(window).height() - $('#top_nav').outerHeight(true)
    $('#content').css 'margin-left': $sidebar.width()

set_ui_widget = ->
  $('.date_picker input[type="text"], input.date_picker').datepicker
    dateFormat: 'yy-mm-dd'
    showButtonPanel: true

  $('.autocomplete input[type="text"]').each (index, element) ->
    $element = $(element)
    $element.data data: $.parseJSON $('div.data', $element.closest('td')).text()
    $element.autocomplete
      delay: 100
      source: (request, response) ->
        matcher = RegExp '^' + $.ui.autocomplete.escapeRegex(request.term), 'i'
        response $.grep($element.data('data'), (item) -> matcher.test item)

  $('a.button, input[type=submit]').button()

update_balance_value = ->
  $balance_value = $('#balance_value')
  if $balance_value.length
    $balance_value.load('/reports/current_user_balance')
    # setTimeout(update_balance_value, 1000)
    
hide_notice_message = ->
  setTimeout (-> 
    $('#notice, #alert').hide('blind')
  ), 2000

$(document).on "page:change", ->
  set_layout()
  $(window).resize set_layout
  set_ui_widget()
  update_balance_value()
  hide_notice_message()
