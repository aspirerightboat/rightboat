$ ->
  $('[data-sortable-url]').each ->
    url = $(@).data('sortable-url')
    $itemsParent = $('tbody', @)
    ajax = null
    $itemsParent.sortable
      update: (event, ui) ->
        ajax.abort() if ajax
        ajax = $.ajax
          url: url
          type: 'post'
          data: $itemsParent.sortable('serialize', key: 'sorted_ids[]')
          error: -> $itemsParent.sortable('cancel')
    .disableSelection();
