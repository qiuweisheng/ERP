# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

set_layout = ->
  $sidebar = $('#sidebar')
  if $sidebar.length isnt 0
    $sidebar.css height: $(window).height() - $('#top_nav').outerHeight(true)
    $('#content').css 'margin-left': $sidebar.width()

$(document).on "ready page:change", ->
  # Set sidebar height and content margin
  set_layout()
  $(window).resize set_layout

  $('.date_picker input[type="text"]').datepicker
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

  $('#record_origin_text').autocomplete
    delay: 200
    source: (request, response) ->
      matcher = RegExp '^' + $.ui.autocomplete.escapeRegex(request.term), 'i'
      response $.grep($('#record_product_text').data('data'), (item) -> matcher.test item)

  $('a.button, input[type=submit]').button()
