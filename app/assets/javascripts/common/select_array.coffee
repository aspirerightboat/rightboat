$ ->

  initSelect = ->
    $('.select-array').select2
      tags: true
      tokenSeparators: [',', ' ']

  $(document).on 'click', 'a.button.has_many_add', initSelect
  $(document).on 'ready page:load', initSelect