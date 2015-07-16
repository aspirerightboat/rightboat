$ ->
  $(document).ready ->
    window.alignSliderLabelPosition = ($item) ->
      $sliderContainer = $item.parent()

      $sliderContainer.find('.min-label')
      .html($item.slider('values', 0) + ' ' + ($item.data('unit') || ''))
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(0)')
          collision: 'flip none'
          offset: '0, 10'

      $sliderContainer.find('.max-label')
      .html($item.slider('values', 1) + ' ' + ($item.data('unit') || ''))
      .position
          my: 'center top'
          at: 'center bottom'
          of: $sliderContainer.find('.ui-slider-handle:eq(1)')
          collision: 'flip none'
          offset: '0, 10'

    $( '.slider' ).each ->
      $sliderContainer = $(this).parent()
      $this = $(this)
      min = $this.data('min')
      max = $this.data('max')

      $this.slider
        range: true
        min: min
        max: max
        values: [ $this.data('value1'), $this.data('value2') ]
        slide: ( event, ui ) ->
          delay = ->
            handleIndex = $(ui.handle).data('uiSliderHandleIndex')
            label = if handleIndex == 0 then '.min-label' else '.max-label'
            $sliderContainer.find(label)
            .html(ui.value + ' ' + ($this.data('unit') || ''))
            .position
              my: 'center top'
              at: 'center bottom'
              of: ui.handle
              collision: 'flip none'
              offset: "0, 10"
            input_name = $this.data('input')
            if input_name && input_name.length
              min_v = $this.slider('values', 0)
              max_v = $this.slider('values', 1)
              min_v = '' if min == min_v
              max_v = '' if max == max_v
              $('input[name="' + input_name + '_min"]').val(min_v)
              $('input[name="' + input_name + '_max"]').val(max_v)

          setTimeout(delay, 5)

      alignSliderLabelPosition($this)

    $('#length_unit').change ->
      $('#length-slider').data('unit', $(this).val())
      alignSliderLabelPosition($('#length-slider'))
