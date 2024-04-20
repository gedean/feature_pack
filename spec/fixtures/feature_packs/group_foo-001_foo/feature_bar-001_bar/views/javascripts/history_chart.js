Highcharts.chart('history-chart-container', {
  chart: {
    type: 'line'
  },
  title: {
    text: gon.history_chart.title
  },
  subtitle: {
    text: gon.history_chart.subtitle
  },
  xAxis: {
    type: 'category',
    categories: gon.history_chart.categories
  },
  yAxis: {
    title: {
      text: 'Número de Habitantes',
    }
  },
  series: [
    gon.history_chart.population,
    gon.history_chart.absolute_difference,
    gon.history_chart.percentage_difference
  ]
});
