$ ->
  $('input.overridable-field, select.overridable-field').each ->
    $field = $(@)
    $reset = $('<button type="button">Reset</button>').appendTo($field.parent())
    rawValue = $field.data('raw-value')+''
    selectize = $field.data('selectize')
    isCheckbox = $field.is('[type=checkbox]')
    isSelect = $field.is('select')

    $reset.attr('title', 'Imported value: ' + ($field.data('raw-text') || rawValue || '[empty]'))
    $reset.click ->
      if selectize
        selectize.setValue(rawValue)
      else if isCheckbox
        $field.prop('checked', rawValue == '1').change()
      else
        $field.val(rawValue).change()
      false

    valueChanged = ->
      val = if isCheckbox then (if $field[0].checked then '1' else '0') else $field.val()
      changed = if $field.attr('type') == 'number'
                  val != rawValue && parseFloat(val) != parseFloat(rawValue)
                else
                  val != rawValue
      $reset.toggle(changed)

    if selectize
      selectize.on('change', valueChanged)
    else if $field.attr('type') == 'checkbox' || isSelect
      $field.change(valueChanged)
    else if $field.attr('type').match(/text|number/)
      $field.keyup(valueChanged).mouseup(valueChanged).change(valueChanged)
    valueChanged()
