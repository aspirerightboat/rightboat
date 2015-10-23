String.prototype.capitalize = ->
  this.charAt(0).toUpperCase() + this.slice(1)

getLocation = (href) ->
  loc = document.createElement('a')
  loc.href = href
  return loc

getYearsArray = ->
  currentYear = new Date().getFullYear()
  years = []
  startYear = currentYear - 30

  while (startYear <= currentYear)
    years.push(startYear++)
  years

$ ->
  $(document).ready ->
    priceValues = [5000, 10000, 15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 60000,
                   70000, 80000, 90000, 100000, 125000, 150000, 175000, 200000, 250000, 300000, 350000, 400000, 450000,
                   500000, 600000, 700000, 800000, 900000, 1000000, 2000000, 3000000, 4000000, 5000000, 10000000]
    lengthValuesFt = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 85, 95, 105, 115, 125, 135, 145, 200, 250, 300, 400, 500]
    lengthValuesM = [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100, 110, 120, 130, 140]
    yearValues = getYearsArray()

    convertPrice = (value, unit) ->
      parseInt(Number(value) * window.currencyRates[unit])

    convertLength = (value, unit) ->
      value = Number(value)
      value = value * 3.28084 if unit == 'ft'
      parseInt(value)

    convertYear = (value, unit) ->
      value

    updateSlider = ($slider, field, value, minOrMax, bEdge=false) ->
      $input = $slider.parents('form').find('input[name="' + field + '_' + minOrMax + '"]')
      if bEdge
        html = if $slider.parents('#advanced-search-wrapper').length > 0 then minOrMax.capitalize() else ''
        $input.val('')
      else
        $input.val(value)
        html = if field == 'price' then $.numberWithCommas(value) else value
        html += ' ' + ($slider.data('unit') || '') if field == 'length'

      $slider.parent().find('.' + minOrMax + '-label').html(html)

    findNearest = (values, value) ->
      nearest = null
      diff = null
      i = 0

      while i < values.length
        if values[i] <= value or values[i] >= value
          newDiff = Math.abs(value - (values[i]))
          if diff == null or newDiff < diff
            nearest = i
            diff = newDiff
        i++
      nearest

    getValues = (field, unit) ->
      if field == 'length'
        if unit == 'm' then lengthValuesM else lengthValuesFt
      else
        eval(field + 'Values')

    onChangeSlide = ($slider, field, value, unit, handleIndex, bEdge=false) ->
      minOrMax = if handleIndex == 0 then 'min' else 'max'
      updateSlider($slider, field, value, minOrMax, bEdge)

    $( '.slider' ).each ->
      $this = $(this)
      field = $(this).data('slide-name')
      unit = $this.data('unit')
      values = getValues(field, unit)
      len = values.length
      value1 = findNearest(values, eval('convert' + field.capitalize() + '(' + $this.data('value1') + ', "' + unit + '")')) || 0
      value2 = findNearest(values, eval('convert' + field.capitalize() + '(' + $this.data('value2') + ', "' + unit + '")')) || len - 1

      $this.slider
        range: true
        min: 0
        max: len - 1
        values: [ value1, value2 ]
        slide: ( event, ui ) ->
          value = ui.value
          unit = $this.data('unit')
          values = getValues(field, unit)
          len = values.length
          handleIndex = $(ui.handle).data('uiSliderHandleIndex')
          bEdge = (value == 0) || (value == len - 1)
          onChangeSlide($this, field, values[value], unit, handleIndex, bEdge)

      updateSlider($this, field, values[value1], 'min', value1 == 0)
      updateSlider($this, field, values[value2], 'max', value2 == len - 1)

    $('select[name="length_unit"]').change (e)=>
      $target = $(e.currentTarget)
      unit = $target.val()
      $('select[name="length_unit"]').select2('val', unit)
      $target.parents('form').find('[data-slide-name="length"]').each ->
        $slider = $(this)
        oldUnit = $slider.data('unit')
        oldValues = getValues('length', oldUnit)
        $slider.data('unit', unit)
        newValues = getValues('length', unit)
        for i in [0, 1]
          oldValue = oldValues[$slider.slider('values', i)]
          oldValueM = if oldUnit == 'ft' then oldValue / 3.28084 else oldValue
          newValue = findNearest(newValues, convertLength(oldValueM, unit))
          bEdge = (newValue == 0) || (newValue == newValues.length - 1)
          onChangeSlide($slider, 'length', newValues[newValue], unit, i, bEdge)
      $('[data-attr-name="loa"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        l = Number(convertLength($boat.data('length'), unit).toFixed(2))
        $boat.find('[data-attr-name="loa"]').html('' + l + ' ' + unit)

    $('select[name="currency"]').change (e)=>
      $target = $(e.currentTarget)
      currency = $target.find('option:selected').text()
      oldUnit = e.removed.id
      unit = e.added.id
      oldValues = getValues('price', oldUnit)
      newValues = getValues('price', unit)
      $('select[name="currency"]').select2('val', $target.val())
      $target.parents('form').find('[data-slide-name="price"]').each ->
        $slider = $(this)
        $slider.data('unit', unit)
        for i in [0, 1]
          oldValue = oldValues[$slider.slider('values', i)]
          oldValuePound = oldValue / window.currencyRates[oldUnit]
          newValue = findNearest(newValues, convertPrice(oldValuePound, unit))
          bEdge = (newValue == 0) || (newValue == newValues.length - 1)
          onChangeSlide($slider, 'price', newValues[newValue], unit, i, bEdge)
      $('[data-attr-name="price"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        if price = $boat.data('price')
          p = Number(convertPrice(price, unit).toFixed(2))
          $boat.find('[data-attr-name="price"]').html(currency + ' ' + $.numberWithCommas(p))

    $('.toggle-adv-search').click (e)->
      e.preventDefault()

      $('#home-search-form, #top-navbar').slideUp
        duration: 200
        complete: ->
          $('#advanced-search').slideDown
            duration: 200

    $('#advanced-search .close').click (e) ->
      e.preventDefault()

      $('#advanced-search').slideUp
        duration: 200
        complete: ->
          $('#home-search-form, #top-navbar').slideDown
            duration: 200

    $('#view-mode, #sort-field, select#currency, select#length_unit').change ->
      value = $(this).val().toLowerCase()
      id = $(this).attr('id')
      if id == 'currency'
        value = value.toUpperCase()
      else if id == 'view-mode'
        $('*[data-view-layout]').attr('data-view-layout', value)
      else if id == 'sort-field'
        # TODO: need to reset pagination with ajax
        params = $.queryParams()
        params.order = value
        window.location.search = $.param(params)

      param = {}
      param[id] = value
      $.ajax
        url: '/session-settings'
        method: 'PUT'
        dataType: 'JSON'
        data: param

    if /\/search\?(.*)?&button=/.test location.href
      $backLink = $('.return-prev')
      href = $backLink.attr('href')
      if /\/search\?(.*)?&button=/.test href
        $backLink.attr('href', href + '&advanced=true')
      else
        loc = getLocation(href)
        if loc.pathname == '/'
          $backLink.attr('href', href + '?advanced=true')

    if /advanced=/.test location.href
      $('.toggle-adv-search').click()