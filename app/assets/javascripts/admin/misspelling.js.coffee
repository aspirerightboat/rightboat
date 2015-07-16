#= require twitter/bootstrap/tooltip
#= require twitter/bootstrap/popover

$(document).ready ->
  if ($buttons = $('.merge-record')).length
    path = window.location.pathname.replace(/\/$/, '')
    collection = null

    $buttons.attr('disabled', 'disabled')

    $.ajax
      url: path + '/all'
      method: 'Get'
      dataType: 'JSON'
    .success (response)->
      scope = path.substring(path.lastIndexOf('/') + 1);
      collection = response[scope]
      $buttons.removeAttr('disabled')

      $buttons.each ->
        $this = $(this)
        actionUrl = $this.data('url')

        content = ''
        $.each collection, ->
          unless @id == $this.data('id')
            link = '<a data-method="post" href="' + actionUrl + '?to=' + @id + '">' + @name + '</a>'
            content += link

        $this.popover('destroy')
        $this.popover
          content: content
          html: true
          placement: 'bottom'
          trigger: 'manual'
          title: "Select target"

      $buttons.click (e)->
        e.preventDefault()
        popoverId = $(this).attr('aria-describedby')
        if popoverId && popoverId.length
          if $('#' + popoverId).is(':visible')
            return $(this).popover('hide')
        $buttons.popover('hide')
        $(this).popover('show')

    .error ->
      alert("Sorry, expexpected error occured. You can't use merge feature.")
