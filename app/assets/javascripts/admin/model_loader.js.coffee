window.syncModel = (manufacturer, $modelSelect) ->
  value = $modelSelect.val()
  $modelSelect.attr('disabled', 'disabled')
  if manufacturer && manufacturer.length
    $.ajax
      type: "GET"
      url: '/api/manufacturers/' + manufacturer + "/models"
      dataType: "JSON"
      data:
        manufacturer: manufacturer
    .success (options) ->
      $modelSelect.empty()
      $('<option>').attr('value', '').text('Any').appendTo($modelSelect)
      $.each options, ->
        $('<option>').attr('value', this[0]).text(this[1]).appendTo($modelSelect)
      if value
        $modelSelect.val(value)
      if $modelSelect.hasClass('select-general')
        $modelSelect.select2
          minimumResultsForSearch: Infinity
    .always ->
      $modelSelect.removeAttr('disabled')

$.fn.loadModelsOfManufacturer = (selector) ->
  onChange = ->
    syncModel(@value, $(selector))
  @.change(onChange).change()

$ ->
  $('#boat_manufacturer_id').loadModelsOfManufacturer('#boat_model_id')
  $('#q_manufacturer_id').loadModelsOfManufacturer('#q_model_id')
  $('#buyer_guide_manufacturer_id').loadModelsOfManufacturer('#buyer_guide_model_id')
  $('#finance_manufacturer_id').loadModelsOfManufacturer('#finance_model_id')
  $('#insurance_manufacturer_id').loadModelsOfManufacturer('#insurance_model_id')
