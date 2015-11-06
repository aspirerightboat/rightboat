loadPreview = ($el) ->
  $el.find('input[type="file"]').change (e) ->
    $this = $(this)
    reader = new FileReader
    reader.onload = ->
      img = new Image
      img.src = reader.result
      window.$this = $this
      $($this.parents('.row')[0]).find('img').attr('src', img.src)
    reader.readAsDataURL(this.files[0])

$(document).ready ->

  $('.rb-datepicker').datetimepicker
    formatTime: ''
    format: 'Y-m-d'
    timepicker: false

  $('[name="boat[sell_request_type]"]').change (e) ->
    $this = $(this)
    $parent = $this.parents('.form-group')
    $parent.find('label').removeClass('btn-black')
    $parent.find('input:checked').parent().find('label').addClass('btn-black')

  $('.preview-wrap > div').each ->
    loadPreview($(this));

  $('.preview-wrap').bind 'cocoon:after-insert', (e, insertedItem) ->
    loadPreview(insertedItem)