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
		$('tbody tr').hide()
		$(row_ids.join()).show()
		$('tbody tr:hidden input').val('')
		$('tbody tr input').removeAttr('shortcut')
		$('tbody tr select').attr('shortcut', 'ctrl+1')
		$('tbody tr:visible input').each((index, item) ->
			$(item).attr('shortcut', 'ctrl+' + (index + 2))
		)
	
handle_key_down = (event) ->
	if event.ctrlKey
		if event.which > 48 && event.which < 58
			shortcut = 'ctrl+' + (event.which - 48)
			$('tbody tr [shortcut="' + shortcut + '"]').focus().click()

handle_keyboard = (event) ->
	console.log event.which
	if event.which != 13 && event.which != 37 && event.which != 39
		return
	event.preventDefault()
	if event.which == 13 || event.which == 39
		next_row = $(this).closest("tr").nextAll(":visible")
	else if event.which == 37
		next_row = $(this).closest("tr").prevAll(":visible")
	if next_row.length == 0 
		if event.which == 13
			$("form#new_record input[type=submit]").click()
		return
	$("input, select", next_row[0]).focus().select()

handle_all_print_box = (event) ->
	if $(this).is(":checked")
		val = true
	else
		val = false
	$("input[name=print]").prop("checked", val)

print_records = (event) ->
	event.preventDefault()
	ids = $.map($('input[name=print]:checked'), (e) ->
		$(e).val()
	)
	if ids.length == 0
		alert("请选择需要打印的记录")
		return
	qs = $.param({ids: ids})
	url = $(this).attr('href') + "?" + qs
	win = window.open("", "_blank")
	$.get(url, (data) ->
		win.document.write(data)
		win.document.close()
		win.focus()
		win.print()
		win.close()
	)
	return false

$(document).on "page:change", ->
	$("form#new_record select").focus()
	$(document).keydown(handle_key_down)
	show_record_input_field()

	$('#record_record_type').change ->
		show_record_input_field()
		$('#error_explanation').remove()
		$('.field_with_errors input').unwrap()

	$('#weight input').keyup ->
		text = ''
		if /^\d+$/.test($(this).val())
			value = parseInt($(this).val()) / 26.717
			text = '' + value.toFixed(4) + '克'
		$('#weight .gram').html(text)

	$("form#new_record input").keydown(handle_keyboard)
	$("form#new_record select").keydown(handle_keyboard)
	$("input[name=all_print]").change(handle_all_print_box)
	$("#print_records").click(print_records)

