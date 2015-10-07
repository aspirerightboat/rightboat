$ ->
  $('.register-broker-link').click ->
    $link = $(this)
    if !$link.hasClass('.inline-loading')
      $link.addClass('.inline-loading')
      $.getScript($(this).attr('href'))
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
  form.daytime_phone.value = if $item then $('input[name$="daytime_phone]"]', $item).val() else ''
  form.evening_phone.value = if $item then $('input[name$="evening_phone]"]', $item).val() else ''
  form.mobile.value = if $item then $('input[name$="mobile]"]', $item).val() else ''
  form.fax.value = if $item then $('input[name$="fax]"]', $item).val() else ''
  form.email.value = if $item then $('input[name$="email]"]', $item).val() else ''
  form.website.value = if $item then $('input[name$="website]"]', $item).val() else ''

updateNoDataText = () ->
  show = $('#offices_table tr').length <= 1
  $('#offices_table_block .no-data-text').toggle(show)
$ ->
  updateNoDataText()

  $('.business-info-form').simpleAjaxForm ($form) ->
    $form.prevAll('.alert').remove()
    $('<div class="alert alert-info">Settings was saved</div>').insertBefore($form).hide().show(200)

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
      $nameInput = $('input[name$="name]"]', $item)
      name = $nameInput.attr('name').replace('[name]', '[_destroy]')
      $nameInput.prepend('<input type="text" name="'+name+'" value="1">').addClass('hidden')
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
    $('input[name$="daytime_phone]"]', $item).val(form.daytime_phone.value)
    $('input[name$="evening_phone]"]', $item).val(form.evening_phone.value)
    $('input[name$="mobile]"]', $item).val(form.mobile.value)
    $('input[name$="fax]"]', $item).val(form.fax.value)
    $('input[name$="email]"]', $item).val(form.email.value)
    $('input[name$="website]"]', $item).val(form.website.value)
    $('.office-name', $item).text(form.name.value)
    $('.office-email', $item).text(form.email.value)
    #$('.office-address', $item).text(form.address.value)
    $('.office-dphone', $item).text(form.daytime_phone.value)
    updateNoDataText()
    $popup.modal('hide')