$ ->
  $.fn.loadModelsOfManufacturer = (selector)->
    onChange = =>
      manufacturer = $(this).val()
      $(selector).attr('disabled', 'disabled')
      if manufacturer && manufacturer.length
        $.ajax
          type: "GET"
          url: '/api/manufacturers/' + manufacturer + "/models"
          dataType: "JSON"
          data:
            manufacturer: manufacturer
        .success (options)->
          $(selector).children().detach()
          $.each options, ->
            $option = $('<option>').attr('value', this[0]).html(this[1])
            $(selector).append($option)
        .always ->
          $(selector).removeAttr('disabled')

    onChange()
    $(this).change onChange

$(document).ready ->
  $('select#boat_manufacturer_id').loadModelsOfManufacturer('select#boat_model_id')
  $('select#q_manufacturer_id').loadModelsOfManufacturer('select#q_model_id')
  $('select#buyer_guide_manufacturer_id').loadModelsOfManufacturer('select#buyer_guide_model_id')
