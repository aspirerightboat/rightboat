$ ->
  console.log('init .select-array')
  $('.select-array').selectize
    delimiter: ',',
    persist: false,
    create: (input) ->
      console.log('create')
      value: input,
      text: input
