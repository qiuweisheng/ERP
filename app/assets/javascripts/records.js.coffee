# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "ready page:change", ->
  $('.date_picker input[type="text"]').datepicker
    dateFormat: 'yy-mm-dd'
    showButtonPanel: true

  $('.autocomplete input[type="text"]').each (index, element) ->
    $element = $(element)
    $element.data data: $.parseJSON $('div.data', $element.closest('td')).text()
    $element.autocomplete
      delay: 200
      source: (request, response) ->
        matcher = RegExp '^' + $.ui.autocomplete.escapeRegex(request.term), 'i'
        response $.grep($element.data('data'), (item) -> matcher.test item)

  $('#record_origin_text').autocomplete
    delay: 200
    source: (request, response) ->
      matcher = RegExp '^' + $.ui.autocomplete.escapeRegex(request.term), 'i'
      response $.grep($('#record_product_text').data('data'), (item) -> matcher.test item)

  $('a.button, input[type=submit]').button()
