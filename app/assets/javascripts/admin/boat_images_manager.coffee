$ ->
  $('.boat-images-manager').each ->
    $manager = $(@)
    droppedFiles = null
    $regularImages = $('#regular_images')
    $uploadForm = $('#boat_images_upload_form')
    $editPopup = $('#edit_boat_image_popup')
    $captionInput = $('#boat_image_caption_input')

    $regularImages.on 'drag dragstart', ->
      false
    .on 'dragover dragenter', ->
      $(@).addClass('is-dragover')
      false
    .on 'dragleave dragend drop', ->
      $(@).removeClass('is-dragover')
      false
    .on 'drop', (e) ->
      droppedFiles = e.originalEvent.dataTransfer.files
      $uploadForm.trigger('submit')
      false

    $uploadForm.on 'submit', (e) ->
      if droppedFiles
        sendDroppedFilesViaAjax()
      false

    sendDroppedFilesViaAjax = ->
      if $regularImages.hasClass('is-uploading')
        return
      $regularImages.addClass('is-uploading')
      ajaxData = new FormData($uploadForm[0])
      inputName = $('input[type=file]', $uploadForm).attr('name')
      $.each droppedFiles, (i, file) ->
        ajaxData.append(inputName, file)
      $.ajax
        url: $uploadForm.attr('action'),
        type: $uploadForm.attr('method'),
        data: ajaxData,
        dataType: 'json',
        cache: false,
        contentType: false,
        processData: false,
        complete: ->
          $regularImages.removeClass('is-uploading')
        success: (data) ->
          displayUploadedImages(data)

    displayUploadedImages = (data) ->
      $.each data.images, (i, props) ->
        cardHtml = $('#boat_image_card_template').html()
        $card = $(cardHtml)
        $card.appendTo($regularImages)
        .find('.boat-image-card-logo img').attr('src', props.mini_url).end()
        .data('props', props)

    initBoatImagesSortable = ($sortableTargets) ->
      $sortableTargets.sortable
        opacity: 0.5,
        distance: 5,
        tolerance: 'pointer',
        items: '.boat-image-card',
        revert: true,
        scroll: false,
        connectWith: '.boat-image-cards',
        update: (e, ui) ->
          if @ == ui.item.parent()[0] # fix because update is firing twice when moving between different sortables
            updateDroppedImage(ui.item, $(@))
        receive: (e, ui) ->
          $sourceSortable = ui.sender
          $sortable = $(@)
          if ($layoutRow = $sortable.closest('.layout-row'))
            if $sortable.hasClass('layout-row-layout') || $sortable.hasClass('side-view-image')
              cancelDropIfSortableHasMany($sourceSortable, $sortable)
            else if $sortable.hasClass('layout-row-images')
              cancelDropIfLayoutEmpty($sourceSortable, $sortable)
            if $sortable.hasClass('layout-row-layout')
              cloneLayoutRow($layoutRow)
      .disableSelection()

    initBoatImagesSortable($('.boat-image-cards'))

    cancelDropIfSortableHasMany = ($sourceSortable, $sortable) ->
      cardsCount = $('.boat-image-card', $sortable).length
      if cardsCount > 1
        $sourceSortable.sortable('cancel')

    cancelDropIfLayoutEmpty = ($sourceSortable, $sortable) ->
      if !$sortable.prev().find('.boat-image-card').length
        $sourceSortable.sortable('cancel')

    cloneLayoutRow = (layoutRow) ->
      $('.boat-image-cards').sortable('destroy');
      $clone = layoutRow.clone()
      $clone.find('.boat-image-card').remove()
      $clone.appendTo(layoutRow.parent())
      initBoatImagesSortable($('.boat-image-cards'))

    updateDroppedImage = ($image, $sortable) ->
      updateDroppedImageLook($image, $sortable)
      params = {}
      params.image = $image.data('props').id
      params.prev = $image.prev('.boat-image-card').data('props')?.id
      params.next = $image.next('.boat-image-card').data('props')?.id
      if $sortable.hasClass('layout-row-images')
        layoutImage = $sortable.prev().find('.boat-image-card')
        params.layout_image = layoutImage.data('props').id
      if $sortable.hasClass('layout-row-layout')
        params.kind = 'layout'
      else if $sortable.hasClass('side-view-image')
        params.kind = 'side_view'
      else
        params.kind = 'regular'
      $.post $manager.data('move-url'), params

    updateDroppedImageLook = ($image, $sortable) ->
      imgProps = $image.data('props')
      imgSrc = if $sortable.hasClass('layout-row-layout') then imgProps.url else imgProps.thumb_url
      $image.find('.boat-image-card-logo img').attr('src', imgSrc)
      $image.find('.boat-image-card-mark').toggle($sortable.hasClass('layout-row-images'))

    $('.boat-image-card').click (e) ->
      $card = $(@)
      $el = $(e.target)
      if $el.hasClass('boat-image-card-edit')
        $editPopup.detach().appendTo(@)
        $captionInput.val($card.data('props').caption)
        $editPopup.data('card', $card)
        setTimeout (-> $editPopup.show()), 0
      else if $el.hasClass('boat-image-card-mark')
        $card.siblings('.boat-image-card').removeClass('is-while-marking')
        $layoutCard = $card.closest('.layout-row').find('.layout-row-layout .boat-image-card')
        $layoutCard.add($card).addClass('is-while-marking').data('marking-phase', 'mark')
        $layoutCard.find('.view-point-mark.is-selected').removeClass('is-selected')
        $layoutCard.find('boat-image-card-logo-img').off('mousemove.marking')
        imageId = $card.data('props').id
        $mark = $layoutCard.find('.view-point-mark').filter(-> $(@).data('image-id') == imageId)
        $mark.addClass('is-selected')
      else if $card.hasClass('is-while-marking')
        markingClick($card, e.pageX, e.pageY)
      false

    markingClick = ($layoutCard, pageX, pageY) ->
      $logo = $layoutCard.closest('.boat-image-card-logo')
      $mark = $layoutCard.find('.view-point-mark.is-selected')
      if $layoutCard.data('marking-phase') == 'mark'
        offset = $logo.offset()
        x = pageX - offset.left
        y = pageY - offset.top
        left = Math.round(Math.abs(x / $logo.width()) * 10000) / 100
        top = Math.round(Math.abs(y / $logo.height()) * 10000) / 100
        $mark.css(left: left+'%', top: top+'%')
        $layoutCard.data('mark-info', x: left, y: top)
        $layoutCard.data('marking-phase', 'rotate')
        $logo.on 'mousemove.marking', (e) ->
          rotX = e.pageX - offset.left
          rotY = e.pageY - offset.top
          fi = Math.atan2(rotY - y, rotX - x)
          alpha = Math.round(fi * (180/Math.PI) * 100)/100
          $mark.css(transform: 'rotate('+alpha+'deg)')
          $layoutCard.data('mark-info').rotate = alpha
      else if $layoutCard.data('marking-phase') == 'rotate'
        $layoutCard.data('marking-phase', 'mark')
        $logo.off 'mousemove.marking'
        params =
          image: $mark.data('image-id')
          mark_info: $layoutCard.data('mark-info')
        $.post $manager.data('update-mark-url'), params

    $('.esc', $editPopup).click -> $editPopup.hide(); false
    $('.save-btn', $editPopup).click ->
      $btn = $(@).prop('disabled', true)
      $card = $editPopup.data('card')
      cardProps = $card.data('props')
      newCaption = $captionInput.val()
      params =
        image: cardProps.id
        caption: newCaption
      $.post $manager.data('update-caption-url'), params, ->
        cardProps.caption = newCaption
        $('.boat-image-card-caption', $card).text(newCaption)
        $editPopup.hide()
      .always ->
        $btn.prop('disabled', false)
      false
    $captionInput.keydown (e) ->
      if e.keyCode == 13
        $('.save-btn', $editPopup).click()
