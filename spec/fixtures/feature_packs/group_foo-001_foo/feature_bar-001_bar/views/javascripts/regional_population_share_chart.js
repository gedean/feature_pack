Highcharts.chart("percent-chart-container", {
  chart: {
    type: "pie",
    options3d: {
      enabled: true,
      alpha: 45,
      beta: 0,
    },
  },
  title: {
    text: gon.population_distribution_chart_title,
  },
  subtitle: {
    text: gon.population_distribution_chart_subtitle,
  },
  plotOptions: {
    pie: {
      allowPointSelect: true,
      cursor: "pointer",
      dataLabels: {
        enabled: true,
        format: "<b>{point.name}</b>: {point.percentage:.2f} %",
      },
    },
  },
  series: [
    {
      type: "pie",
      name: "Participação",
      data: gon.percent_chart_series,
    },
  ],
}).series[0].data[0].update({ color: "orange" });
