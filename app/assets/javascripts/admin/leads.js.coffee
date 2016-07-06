$ ->

  $(document).on 'ready page:load', ->
    $('.delete-lead').click (e)->
      e.stopPropagation()
      e.preventDefault()
      formInputs = { reason: 'textarea' }
      ActiveAdmin.modal_dialog 'Pleas input reason', formInputs, (inputs) =>
        $(@).trigger 'confirm:complete', inputs

    $('.delete-lead').on 'confirm:complete', (e, inputs) ->
      $form = $('#dialog_confirm')
      if inputs.reason.trim() != ''
        $form.prepend('<input type="hidden" name="authenticity_token" value="' + $('[name="csrf-token"]').attr('content') + '">')
        $form.attr('action', $(e.currentTarget).attr('href')).attr('method', 'post')
        $form.submit()

  return unless $('#lead-graph').length > 0

  $(document).ready ->
    minYear = 2015
    maxYear = 2015
    chart = undefined
    months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    weeks = ['1st', '2nd', '3rd', '4th', '5th', '6th']
    statuses = ['rejected', 'pending', 'approved', 'invoiced']
    colors = 
      'rejected':   'red'
      'pending':    'yellow'
      'approved':   'orange'
      'invoiced':   'green'
    yearsArray = []

    getWeekOfMonth = (date) ->
      day = date.getDate()
      day -= if date.getDay() == 0 then 6 else date.getDay() - 1
      day += 7
      prefixes = weeks
      prefixes[0 | day / 7]

    setChart = (data) ->
      len = chart.series.length
      chart.xAxis[0].setCategories data.categories
      i = 0
      while i < len
        chart.series[0].remove()
        i++
      if data.series
        i = 0
        while i < data.series.length
          chart.addSeries
            name: data.series[i].name
            data: data.series[i].data
          i++
      return

    _.map leads, (x) ->
      createTime = new Date(x.created_at)
      year = createTime.getFullYear()
      x.year = year
      x.month = months[createTime.getMonth()]
      x.week = getWeekOfMonth(createTime)
      minYear = year if year < minYear
      maxYear = year if year > maxYear
      year

    year = minYear
    while year <= maxYear
      yearsArray.push(year)
      year += 1

    drilldown =
      annual:
        categories: yearsArray
        name: 'Annual'
        series: _.map statuses, (st1) ->
          type: 'column'
          name: st1
          color: colors[st1]
          data: _.map yearsArray, (year) ->
            name: year.toString()
            y: _.size(_.where leads, { year: year, status: st1 })

    _.map yearsArray, (year) ->
      yearData = _.where leads, { year: year }
      drilldown[year.toString()] =
        categories: months
        series: _.map statuses, (status) ->
          name: status
          data: _.map months, (month) ->
            name: month + ', ' + year
            y: _.size(_.where yearData, { month: month, status: status })

      _.map months, (month) ->
        monthData = _.where yearData, { month: month }
        drilldown[year.toString()][month] =
          categories: weeks
          series: _.map statuses, (status) ->
            name: status
            data: _.map weeks, (week) ->
              _.size(_.where monthData, { week: week, status: status })

    chart = new (Highcharts.Chart)
      chart:
        renderTo: 'lead-graph'
        type: 'column'
      colors: _.map colors, (color) ->
        color
      title:
        text: 'Annual'
      subtitle:
        text: ''
      xAxis:
        categories: yearsArray
      yAxis:
        allowDecimals: false
        title:
          text: ''
        stackLabels:
          enabled: true
          style:
            fontWeight: 'bold'
            color: Highcharts.theme and Highcharts.theme.textColor or 'gray'
          formatter: ->
            @y
        labels:
          formatter: ->
            @value
          style:
            color: '#006633'
      legend:
        enabled: false
      plotOptions: column:
        stacking: 'normal'
        cursor: 'pointer'
        point:
          events:
            click: ->
              if name = @name
                splitted = name.split(', ')
                chart.setTitle
                  text: name

                if splitted.length > 1
                  year = splitted[1]
                  month = splitted[0]
                  $backButton.data('year', year).text('Back to ' + year)
                  setChart drilldown[year][month]
                else
                  year = splitted[0]
                  $backButton.data('year', null).text('Back to Annual')
                  setChart drilldown[year]

                $backButton.show()
              return
        dataLabels:
          enabled: false
          color: 'white'
          style:
            fontWeight: 'normal'
          formatter: ->
            @y + ' '
      tooltip: formatter: ->
        series = @series.chart.series
        total = 0
        x = @point.x
        i = 0
        while i < series.length
          total += series[i].data[x].y
          i++
        s = @series.name + ' : ' + @y + '<br/>'
        s += 'Total: ' + total
        if @point.drilldown
          s += '<br/>Click for detail'
        s
      series: drilldown.annual.series

    $backButton = $('<button id="back-btn" style="display: none;">Back</button>').appendTo $('#lead-graph')
    $backButton.click ->
      if year = $(this).data('year')
        $backButton.data('year', null).text('Back to Annual')
        chart.setTitle
          text: year
        setChart drilldown[year]
      else
        $backButton.data('year', null).text('Back').hide()
        chart.setTitle
          text: 'Annual'
        setChart drilldown['annual']
    return
