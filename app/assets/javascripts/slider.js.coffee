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

lengthRates =
  'm': 1
  'ft': 3.28084

$ ->
  priceValues = [5000, 10000, 15000, 20000, 25000, 30000, 35000, 40000, 45000, 50000, 60000,
                 70000, 80000, 90000, 100000, 125000, 150000, 175000, 200000, 250000, 300000, 350000, 400000, 450000,
                 500000, 600000, 700000, 800000, 900000, 1000000, 2000000, 3000000, 4000000, 5000000, 10000000]
  lengthValuesFt = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800, 900, 1000]
  lengthValuesM = [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45, 50, 55, 60, 65, 70, 75, 80, 90, 100, 110, 120, 130, 140, 150, 200, 250, 300]
  yearValues = getYearsArray()

  convertValue = (field, value, fromUnit, toUnit) ->
    switch field
      when 'price' then convertPrice(value, fromUnit, toUnit)
      when 'length' then convertLength(value, fromUnit, toUnit)
      else value

  convertPrice = (value, fromUnit, toUnit) ->
    (Number(value) * ( window.currencyRates[toUnit] / window.currencyRates[fromUnit] )).toFixed(2)

  convertLength = (value, fromUnit, toUnit) ->
    (Number(value) * ( lengthRates[toUnit] / lengthRates[fromUnit] )).toFixed(2)

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

  getValues = ($slider, unit) ->
    field = $slider.data('input')
    min = $slider.data('min') || 0
    max = $slider.data('max') || 1000000000

    if field == 'length'
      if unit == 'm'
        values = lengthValuesM
      else
        values = lengthValuesFt
        min = min * 3.28084 if min
        max = max * 3.28084 if max
    else
      values = eval(field + 'Values')

    values.filter (x) -> (x >= min && x <= max)

  defaultUnit = (field) ->
    if field == 'length'
      'ft'
    else if field == 'price'
      'GBP'

  initSlider = ($slider, fromUnit=null) ->
    field = $slider.data('input')
    unless unit = $slider.data('unit')
      unit = defaultUnit(field)
      $slider.data('unit', unit)
    fromUnit = unit unless fromUnit
    values = getValues($slider, unit)

    len = values.length
    iValues = []
    for i in [0, 1]
      if originvalue = $slider.data('value' + i)
        cValue = convertValue(field, originvalue, fromUnit, unit)
      else
        cValue = if i == 0 then values[0] else values[len - 1]
      $slider.data('value' + i, cValue)
      iValues[i] = findNearest(values, cValue) || (if i == 0 then 0 else len - 1)

    $slider.slider
      range: true
      min: 0
      max: len - 1
      values: [ iValues[0], iValues[1] ]
      slide: ( event, ui ) ->
        value = ui.value
        handleIndex = $(ui.handle).data('uiSliderHandleIndex')
        bEdge = (value == 0) || (value == len - 1)
        minOrMax = if handleIndex == 0 then 'min' else 'max'
        $slider.data('value' + handleIndex, values[value])
        updateSlider($slider, field, values[value], minOrMax, bEdge)

    updateSlider($slider, field, values[iValues[0]], 'min', iValues[0] == 0)
    updateSlider($slider, field, values[iValues[1]], 'max', iValues[1] == len - 1)

  window.reinitSlider = ($slider, oldUnit=null, unit=null) ->
    $slider.slider('destroy')
    $slider.data('unit', unit)
    initSlider($slider, oldUnit)

  $( '.slider' ).each ->
    initSlider($(this))

  $('select[name="length_unit"]').change (e)=>
    $target = $(e.currentTarget)
    oldUnit = e.removed.id
    unit = $target.val()
    $('select[name="length_unit"]').select2('val', unit)
    $('[data-input="length"]').each ->
      reinitSlider($(this), oldUnit, unit)
    $('[data-attr-name="loa"]').each (_, el)=>
      $boat = $(el).closest('[data-boat-ref]')
      if length = $boat.data('length')
        l = convertLength(Number(length), oldUnit, unit)
        $boat.find('[data-attr-name="loa"]').html('' + l + ' ' + unit)

  $('select[name="currency"]').change (e)=>
    $target = $(e.currentTarget)
    currency = $target.find('option:selected').text()
    oldUnit = e.removed.id
    unit = e.added.id
    $('select[name="currency"]').select2('val', $target.val())
    $('[data-input="price"]').each ->
      reinitSlider($(this), oldUnit, unit)
    $('[data-attr-name="price"]').each (_, el)=>
      $boat = $(el).closest('[data-boat-ref]')
      if price = $boat.data('price')
        p = convertPrice(Number(price), oldUnit, unit)
        $boat.find('[data-attr-name="price"]').html(currency + ' ' + $.numberWithCommas(p))

  $('.toggle-adv-search').click (e)->
    e.preventDefault()

    $('#search-hub-form, #top-navbar').slideUp
      duration: 200
      complete: ->
        $('#advanced-search').slideDown
          duration: 200

  $('#advanced-search .close').click (e) ->
    e.preventDefault()

    $('#advanced-search').slideUp
      duration: 200
      complete: ->
        $('#search-hub-form, #top-navbar').slideDown
          duration: 200

  $('#layout_mode').change ->
    $('*[data-layout-mode]').attr('data-layout-mode', @value)
    Cookies.set('layout_mode', @value)

  $('#search_order').change ->
    params = $.queryParams()
    params.order = @value
    params.page = 1
    window.location.search = $.param(params)


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