
$(document).ready ->
  $('[data-sortable-url] tbody').activeAdminSortable()


$.fn.activeAdminSortable = ->
  ajax = null
  @sortable
    update: (event, ui) ->
      $container = ui.item.closest('[data-sortable-url]')
      url = $container.data('sortable-url')

      ajax.abort() if ajax
      ajax = $.ajax
        url: url
        type: 'post'
        data: $container.find('tbody').sortable('serialize', key: 'sorted_ids[]')
        error: () ->
          $container.find('tbody').sortable('cancel')

  @disableSelection();
