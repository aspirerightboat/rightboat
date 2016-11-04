$ ->
  $('.boat-images-manager').each ->
    $manager = $(@)
    droppedFiles = null
    $regularImages = $('#regular_images')
    $uploadForm = $('#boat_images_upload_form')

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

    # createCardsFromDroppedFiles = ->
    #      $.each evt.originalEvent.dataTransfer.files, (i, file) ->
    #      img = document.createElement('img')
    #      img.onload = ->
    #        window.URL.revokeObjectURL(@src)
    #      img.height = 100
    #      img.src = window.URL.createObjectURL(file)
    #      $someDiv.append(img)

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
        .find('.boat-image-card-logo').attr('src', props.mini_url).end()
        .data('props', props)

    $('.boat-image-cards').sortable
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
        if (layoutRow = $sortable.closest('.layout-row'))
          if $sortable.hasClass('layout-row-layout') || $sortable.hasClass('side-view-image')
            cancelDropIfSortableHasMany($sourceSortable, $sortable)
          else if $sortable.hasClass('layout-row-images')
            cancelDropIfLayoutEmpty($sourceSortable, $sortable)
    .disableSelection()

    cancelDropIfSortableHasMany = ($sourceSortable, $sortable) ->
      cardsCount = $('.boat-image-card', $sortable).length
      if cardsCount > 1
        $sourceSortable.sortable('cancel')

    cancelDropIfLayoutEmpty = ($sourceSortable, $sortable) ->
      if !$sortable.prev().find('.boat-image-card').length
        $sourceSortable.sortable('cancel')

    updateDroppedImage = ($image, $sortable) ->
      imgProps = $image.data('props')
      imgSrc = if $sortable.hasClass('layout-row-layout') then imgProps.url else imgProps.thumb_url
      $image.find('.boat-image-card-logo').attr('src', imgSrc)

      params = {}
      params.image = $image.data('props').id
      params.prev = $image.prev('.boat-image-card').data('props')?.id
      params.next = $image.next('.boat-image-card').data('props')?.id
      if $sortable.hasClass('layout-row-images')
        layoutImage = $sortable.prev().find('.boat-image-card')
        params.layout_image = layoutImage.data('props').id
      $.post $manager.data('move-url'), params
