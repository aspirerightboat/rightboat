$ ->
  if $('.multiselectable').length

    $('.boat-thumb.thumbnail.multiselectable .tick').on 'click', (e) ->
      e.stopPropagation()
      e.preventDefault()
      $(@).parents('.boat-thumb.thumbnail.multiselectable').toggleClass('selected')
      toggleBottomBar()

    $('.boat-thumb.thumbnail.multiselectable').on 'click', (e) ->
      if $('.multiselectable.selected').length > 0 # in selected mode
        e.preventDefault()
        $(@).toggleClass('selected')
        toggleBottomBar()

    $('.boat-thumb .caption').click ->
      if $('.multiselectable.selected').length == 0
        window.location = $(@).data('url')

    toggleBottomBar = () ->
      if $('.boat-thumb.thumbnail.selected').length > 0
        $('#multiselected-request-for-details #number-selected').text(word_with_number('boat', $('.multiselectable.selected').length) + ' selected')
        $('#multiselected-request-for-details').animate
          bottom: '0px'
      else
        $('#multiselected-request-for-details').animate
          bottom: '-55px'

    word_with_number = (word, number) ->
      if number == 1
        return(number + ' ' + word)
      else
        return(number + ' ' + word + 's')
