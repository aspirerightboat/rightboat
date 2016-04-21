$ ->
  if $('#multiselected-request-for-details').length
    $('.boat-thumb.thumbnail').on 'click', (e) ->
      $(@).toggleClass('selected')
      if $('.boat-thumb.thumbnail.selected').length
        $('#multiselected-request-for-details').animate
          bottom: '0px'
      else
        $('#multiselected-request-for-details').animate
          bottom: '-55px'
