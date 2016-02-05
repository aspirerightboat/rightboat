#= require twitter/bootstrap/tooltip
#= require twitter/bootstrap/popover

$ ->
  if ($buttons = $('.merge-record')).length
    path = window.location.pathname.replace(/\/$/, '')
    collection = null
    fetched = false

    togglePopup = ($button) ->
      content = ''
      $.each collection, ->
        unless @id == $button.data('id')
          link = '<a data-method="post" href="' + $button.data('url') + '?to=' + @id + '">' + @name + '</a>'
          content += link

      $button.popover('destroy')
      $button.popover
        content: content
        html: true
        placement: 'bottom'
        trigger: 'manual'
        title: "Select target"

      popoverId = $button.attr('aria-describedby')
      if popoverId && popoverId.length
        if $('#' + popoverId).is(':visible')
          return $button.popover('hide')
      $buttons.popover('hide')
      $button.popover('show')

    $buttons.click (e)->
      e.preventDefault()
      $this = $(this)
      if $this.next('.popover:visible').length > 0
        $this.popover('hide')
        return false

      if !fetched || /admin\/models/.test(path)
        $.ajax
          url: path + '/all'
          method: 'Get'
          data: { id: $this.data('id') }
          dataType: 'JSON'
        .success (response)->
          fetched = true
          scope = path.substring(path.lastIndexOf('/') + 1);
          collection = response[scope]
          togglePopup($this)
        .error ->
          alert("Sorry, unexpected error occured. You can't use merge feature.")
          return false
      else
        togglePopup($this)
