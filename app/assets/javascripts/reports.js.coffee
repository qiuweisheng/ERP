# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'page:change', ->
  $("#from_date").datepicker
    dateFormat: 'yy-mm-dd'
    showButtonPanel: true
    onClose: (date) -> $('#to_date').datepicker("option", "minDate", date)

  $("#to_date").datepicker
    dateFormat: 'yy-mm-dd'
    showButtonPanel: true
    onClose: (date) -> $('#from_date').datepicker("option", "maxDate", date)

  $("form input.xlsx").click (event)->
    event.preventDefault()
    parent = $(this).parent()
    url = parent.attr('action') + '.xlsx?' + parent.serialize() 
    window.open(url)
