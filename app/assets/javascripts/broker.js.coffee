$ ->
  $('.register-broker-link').click ->
    $link = $(@)
    if !$link.hasClass('.inline-loading')
      $link.addClass('.inline-loading')
      $.getScript($(@).data('url'))
      .always -> $link.removeClass('.inline-loading')
    false

$.fn.initRegisterBrokerPopup = ->
  $('.select-title', @).initTitleSelect()
  @.simpleAjaxForm()

openOfficePopup = ($item) ->
  $popup = $('#office_form_popup').displayPopup().data('office-item', $item)
  form = $('form', $popup)[0]
  form.name.value = if $item then $('input[name$="name]"]', $item).val() else ''
  form.contact_name.value = if $item then $('input[name$="contact_name]"]', $item).val() else ''
  $(form.daytime_phone_code).val(if $item then $('input[name$="daytime_phone]"]', $item).val().split('-')[0] else '').trigger('change')
  form.daytime_phone.value = if $item then $('input[name$="daytime_phone]"]', $item).val().split('-')[1] || '' else ''
  $(form.evening_phone_code).val(if $item then $('input[name$="evening_phone]"]', $item).val().split('-')[0] else '').trigger('change')
  form.evening_phone.value = if $item then $('input[name$="evening_phone]"]', $item).val().split('-')[1] || '' else ''
  $(form.mobile_code).val(if $item then $('input[name$="mobile]"]', $item).val().split('-')[0] else '').trigger('change')
  form.mobile.value = if $item then $('input[name$="mobile]"]', $item).val().split('-')[1] || '' else ''
  form.fax.value = if $item then $('input[name$="fax]"]', $item).val() else ''
  form.email.value = if $item then $('input[name$="email]"]', $item).val() else ''
  form.website.value = if $item then $('input[name$="website]"]', $item).val() else ''
  form.line1.value = if $item then $('input[name$="line1]"]', $item).val() else ''
  form.line2.value = if $item then $('input[name$="line2]"]', $item).val() else ''
  form.county.value = if $item then $('input[name$="county]"]', $item).val() else ''
  form.town_city.value = if $item then $('input[name$="town_city]"]', $item).val() else ''
  form.zip.value = if $item then $('input[name$="zip]"]', $item).val() else ''
  $(form.country_id).val(if $item then $('input[name$="country_id]"]', $item).val() else '').trigger('change')

  form.line1.value = if $item then $('input[name$="website]"]', $item).val() else ''

updateNoDataText = () ->
  show = $('#offices_table tr').length <= 1
  $('#offices_table_block .no-data-text').toggle(show)
$ ->
  updateNoDataText()

  $('.business-info-form').simpleAjaxForm ($form) ->
    $('.alert', $form).remove()
    $('<div class="alert alert-info">Settings were saved</div>').prependTo($form).hide().show(200)

  $('.add-office-btn').click ->
    openOfficePopup(null)
  $(document).on 'click', '.edt-office-btn', -> openOfficePopup($(@).closest('.office-item'))
  $(document).on 'click', '.del-office-btn', ->
    $item = $(@).closest('.office-item')
    if $item.hasClass('new-item')
      $item.hide 200, ->
        $(@).remove()
        updateNoDataText()
    else
      $idInput = $('input[name$="id]"]', $item)
      name = $idInput.attr('name').replace('[id]', '[_destroy]')
      $idInput.after('<input type="hidden" name="'+name+'" value="1">')
      $item.hide(200)
      updateNoDataText()
  $('.upd-office-btn').click ->
    $popup = $(@).closest('.modal')
    $item = $popup.data('office-item')
    if !$item
      item = $('#office_template').html()
      $item = $(item.replace(/\{\{I}}/g, +new Date()))
      $item.appendTo('#offices_table').addClass('new-item')
    form = $(@).closest('form')[0]
    $('input[name$="name]"]', $item).val(form.name.value)
    $('input[name$="contact_name]"]', $item).val(form.contact_name.value)
    dphone = form.daytime_phone_code.value + '-' + form.daytime_phone.value
    $('input[name$="daytime_phone]"]', $item).val(dphone)
    $('input[name$="evening_phone]"]', $item).val(form.evening_phone_code.value + '-' + form.evening_phone.value)
    $('input[name$="mobile]"]', $item).val(form.mobile_code.value + '-' + form.mobile.value)
    $('input[name$="fax]"]', $item).val(form.fax.value)
    $('input[name$="email]"]', $item).val(form.email.value)
    $('input[name$="website]"]', $item).val(form.website.value)
    $('input[name$="line1]"]', $item).val(form.line1.value)
    $('input[name$="line2]"]', $item).val(form.line2.value)
    $('input[name$="county]"]', $item).val(form.county.value)
    $('input[name$="town_city]"]', $item).val(form.town_city.value)
    $('input[name$="zip]"]', $item).val(form.zip.value)
    $('input[name$="country_id]"]', $item).val(form.country_id.value)
    $('.office-name', $item).text(form.name.value)
    $('.office-email', $item).text(form.email.value)
    country_name = if form.country_id.selectedIndex > 0 then form.country_id.options[form.country_id.selectedIndex].innerHTML else ''
    address_arr = [form.line1.value, form.line2.value, form.town_city.value, form.county.value, form.zip.value, country_name]
    address_str = $.grep(address_arr, (n) -> n).join(', ')
    $('.office-address', $item).text(address_str)
    dphone_str = if dphone then '+(' + dphone.split('-')[0] + ') ' + (dphone.split('-')[1] || '')
    $('.office-dphone', $item).text(dphone_str)
    updateNoDataText()
    $popup.modal('hide')