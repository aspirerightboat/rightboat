$ ->
  $('.select-array').selectize
    delimiter: ',',
    persist: false,
    create: (input) ->
      value: input,
      text: input
