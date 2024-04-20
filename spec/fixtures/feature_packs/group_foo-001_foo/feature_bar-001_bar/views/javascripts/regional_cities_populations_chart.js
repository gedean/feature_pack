Highcharts.chart("population-distribution-chart", {
  tooltip: {
    enabled: false,
  },
  chart: {
    type: "column",
    inverted: true,
  },
  title: {
    text: gon.population_distribution_chart.title,
  },
  subtitle: {
    text: gon.population_distribution_chart.subtitle,
  },
  xAxis: {
    type: "category",
    categories: gon.population_distribution_chart.categories,
  },
  series: [gon.population_distribution_chart.ranking_population],
})
// .series[0].data[0].update({
//   color: "orange",
//   dataLabels: { enabled: true },
// });
