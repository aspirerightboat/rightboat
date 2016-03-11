$ ->
  return unless $('#lead-graph').length > 0

  $(document).ready ->
    minYear = 2015
    maxYear = 2015
    chart = undefined
    viewType = ['annually', 'monthly', 'weekly']
    months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    weeks = ['1th', '2nd', '3rd', '4th', '5th', '6th']
    statuses = ['rejected', 'pending', 'approved', 'invoiced']
    colors = 
      'rejected':   'red'
      'pending':    'yellow'
      'approved':   'orange'
      'invoiced':   'green'
    currentView = 0
    yearsArray = []
    annuallData = {}

    getWeekOfMonth = (date) ->
      day = date.getDate()
      day -= if date.getDay() == 0 then 6 else date.getDay() - 1
      day += 7
      prefixes = weeks
      prefixes[0 | day / 7]

    setChart = (name, categories, data, color) ->
      len = chart.series.length
      chart.yAxis[0].options.stackLabels.enabled = true
      chart.xAxis[0].setCategories categories
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
      x.month = createTime.getMonth() + 1
      x.week = getWeekOfMonth(createTime)
      minYear = year if year < minYear
      maxYear = year if year > maxYear
      year

    year = minYear
    while year <= maxYear
      yearsArray.push(year)
      yearString = year.toString()
      annuallData[yearString] =
        categories: months
        series: _.map statuses, (status) ->
          name: status
          data: _.map months, (month) ->
            y: _.size(_.where leads, { year: year, month: month, status: status })
            drilldown:
              categories: weeks
              series: _.map statuses, (st) ->
                name: st
                data: _.map weeks, (week) ->
                  _.size(_.where leads, { year: year, month: month, week: week, status: st })
      year += 1

    chart = new (Highcharts.Chart)
      chart:
        renderTo: 'lead-graph'
        type: 'column'
      colors: _.map colors, (color) ->
        color
      title:
        text: viewType[currentView]
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
              drilldown = @drilldown
              if drilldown
                currentView += 1
                chart.setTitle
                  text: viewType[currentView]
                chart.yAxis[0].options.stackLabels.enabled = false
                setChart null, drilldown.categories, drilldown
              else
                window.location.reload true
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
      series: _.map statuses, (status) ->
        type: 'column'
        name: status
        data: _.map yearsArray, (year) ->
          y: _.size(_.where leads, { year: year, status: status })
          drilldown: annuallData[year.toString()]
        color: colors[status]
