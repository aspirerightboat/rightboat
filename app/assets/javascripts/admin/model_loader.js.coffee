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

$ ->
  $.fn.loadModelsOfManufacturer = (selector) ->
    onChange = =>
      syncModel($(this).val(), $(selector))

    onChange()
    $(this).change onChange

$(document).ready ->
  $('select#boat_manufacturer_id').loadModelsOfManufacturer('select#boat_model_id')
  $('select#q_manufacturer_id').loadModelsOfManufacturer('select#q_model_id')
  $('select#buyer_guide_manufacturer_id').loadModelsOfManufacturer('select#buyer_guide_model_id')
  $('select#finance_manufacturer_id').loadModelsOfManufacturer('select#finance_model_id')
  $('select#insurance_manufacturer_id').loadModelsOfManufacturer('select#insurance_model_id')
