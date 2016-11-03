$ ->
  $('.boat-images-manager').each ->
    $manager = $(@)
    droppedFiles = null
    $regularImagesBox = $('.regular-boat-image-cards', @)

    $('#boat_images_manager_upload_form').on 'drag dragstart', ->
      false
    .on 'dragover dragenter', ->
      $(@).addClass('is-dragover')
      false
    .on 'dragleave dragend drop', ->
      $(@).removeClass('is-dragover')
      false
    .on 'drop', (e) ->
      droppedFiles = e.originalEvent.dataTransfer.files
      $(@).trigger('submit')
      false
    .on 'submit', (e) ->
      if droppedFiles
        sendDroppedFilesViaAjax(@)
      false

    # createCardsFromDroppedFiles = ->
    #      $.each evt.originalEvent.dataTransfer.files, (i, file) ->
    #      img = document.createElement('img')
    #      img.onload = ->
    #        window.URL.revokeObjectURL(@src)
    #      img.height = 100
    #      img.src = window.URL.createObjectURL(file)
    #      $someDiv.append(img)

    sendDroppedFilesViaAjax = (form) ->
      $form = $(form)
      if $form.hasClass('is-uploading')
        return
      $form.addClass('is-uploading')
      ajaxData = new FormData(form)
      inputName = $('input[type=file]', form).attr('name')
      $.each droppedFiles, (i, file) ->
        ajaxData.append(inputName, file)
      $.ajax
        url: $form.attr('action'),
        type: $form.attr('method'),
        data: ajaxData,
        dataType: 'json',
        cache: false,
        contentType: false,
        processData: false,
        complete: ->
          $form.removeClass('is-uploading')
        success: (data) ->
          displayUploadedImages(data)

    displayUploadedImages = (data) ->
      console.log(data)
      $.each data.images, (i, props) ->
        console.log(i, props)
        cardHtml = $('#regular_image_card_template').html()
        $card = $(cardHtml)
        $card.appendTo($regularImagesBox)
        .find('.regular-boat-image-card-logo').attr('src', props.mini_url).end()
        .data('props', props)
        console.log($regularImagesBox, $card)


    $regularImagesBox.sortable
      opacity: 0.5,
      distance: 5,
      tolerance: 'pointer',
      revert: true,
      scroll: false,
      update: (e, ui) ->
        params = {}
        params.image = ui.item.data('props')?.id
        params.prev = ui.item.prev().data('props')?.id
        params.next = ui.item.next().data('props')?.id
        $.post $manager.data('move-url'), params
    .disableSelection()
