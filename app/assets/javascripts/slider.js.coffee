$ ->
  $(document).ready ->
    convertCurrency = (value) ->
      value = Number(value)
      currency = $('form:visible select[name="currency"]').val()
      rate = window.currencyRates[currency]
      rate * value

    convertLength = (value) ->
      value = Number(value)
      unit = $('form:visible select[name="length_unit"]').val()
      if unit == 'ft'
        return value * 3.28084
      else
        return value

    convertValue = (v, $item) =>
      convertFuncName = $item.data('convert')
      return v unless convertFuncName
      eval(convertFuncName + "(" + v + ")");

    changeSliderValue = ($slider, handleIndex=0) ->
      value = $slider.slider('values', handleIndex)
      selector = if handleIndex == 0 then 'min' else 'max'
      if value == $slider.data(selector)
        html = ''
      else
        value = Math.floor(convertValue(value, $slider))
        html = value + ' ' + ($slider.data('unit') || '')

      $sliderContainer = $slider.parent()

      $sliderContainer.find('.' + selector + '-label')
      .html(html)
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(' + handleIndex + ')')
          collision: 'flip none'
          offset: "0, 10"

      updateValues($slider)
      changePriceIncrement($slider)

    alignSliderLabelPosition = ($item) ->
      for i in [0, 1]
        changeSliderValue($item, i)

    updateValues = ($slider) ->
      input_name = $slider.data('input')
      if input_name && input_name.length
        min = $slider.data('min')
        max = $slider.data('max')
        min_v = $slider.slider('values', 0)
        max_v = $slider.slider('values', 1)
        min_v = if min == min_v then '' else Math.floor(convertValue(min_v, $slider))
        max_v = if max == max_v then '' else Math.floor(convertValue(max_v, $slider))
        max_v = '' if max == max_v
        $('input[name="' + input_name + '_min"]').val(min_v)
        $('input[name="' + input_name + '_max"]').val(max_v)

    changeLengthIncrement = ($slider) ->
      return unless $slider.attr('id') is 'length-slider'
      min = $slider.data('min')
      max = $slider.data('max')
      diff = parseInt(max) - parseInt(min)

      step = if $slider.data('unit') == 'ft'
        if diff > 6.096 then 6.096 else 3.048
      else
        if diff > 10 then 10 else 5

      $slider.slider
        step: step

    changePriceIncrement = ($slider) ->
      return unless $slider.attr('id') is 'price-slider'
      max = parseInt($slider.slider('values', 0))
      step = if max < 1000000
        50000
      else if max < 3000000
        100000
      else
        500000

      $slider.slider
        step: step

    $( '.slider' ).each ->
      $this = $(this)
      v1 = $this.data('value1')
      v2 = $this.data('value2')

      $this.slider
        range: true
        min: $this.data('min')
        max: $this.data('max')
        values: [ v1, v2 ]
        slide: ( event, ui ) ->
          delay = ->
            changeSliderValue($this, $(ui.handle).data('uiSliderHandleIndex'))
          setTimeout(delay, 5)

      changeLengthIncrement($this)
      changePriceIncrement($this)

    $('select[name="length_unit"]').change (e)=>
      unit = $(e.currentTarget).val()
      $('select[name="length_unit"]').select2('val', unit)
      $('[data-slide-name="length"]').each ->
        $slider = $(this)
        $slider.data('unit', unit)
        alignSliderLabelPosition($slider)
        changeLengthIncrement($slider)
      $('[data-attr-name="loa"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        l = Number(convertLength($boat.data('length')).toFixed(2))
        $boat.find('[data-attr-name="loa"]').html('' + l + ' ' + unit)

    $('select[name="currency"]').change (e)=>
      $el = $(e.currentTarget)
      currency = $el.find('option:selected').text()
      $('select[name="currency"]').select2('val', $el.val())
      $('[data-slide-name="price"]').each ->
        $slider = $(this)
        alignSliderLabelPosition($slider)
      $('[data-attr-name="price"]').each (_, el)=>
        $boat = $(el).closest('[data-boat-ref]')
        if price = $boat.data('price')
          p = Number(convertCurrency(price).toFixed(2))
          $boat.find('[data-attr-name="price"]').html(currency + ' ' + $.numberWithCommas(p))

    setupSliderLabelPosition = ->
      $('#advanced-search .slider, #home-search .slider').each ->
        alignSliderLabelPosition($(this))

    $('.toggle-adv-search').click (e)->
      e.preventDefault()

      $('#home-search-form, #normal-navbar').slideUp
        duration: 200
        progress: setupSliderLabelPosition
        complete: ->
          $('#advanced-search').slideDown
            duration: 200
            progress: setupSliderLabelPosition
            complete: setupSliderLabelPosition

    $('#advanced-search .close').click (e) ->
      e.preventDefault()

      $('#advanced-search').slideUp
        duration: 200
        progress: setupSliderLabelPosition
        complete: ->
          $('#home-search-form, #normal-navbar').slideDown
            duration: 200
            progress: setupSliderLabelPosition
            complete: setupSliderLabelPosition

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
      $backLink.attr('href', href + '&advanced=true')

    if /&advanced/.test location.href
      $('.toggle-adv-search').click()