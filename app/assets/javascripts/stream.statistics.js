/*!
 * Finfore Stream Widget : Display Google Chart from services
 * version: 0.10
 * @requires jQuery v1.3.2 or later
 *
 * options = {
     title: String,
     api: google,
     url: String,
     parameters: Object,
     description: String,
     displayLegend: Boolean (default: true)
   }
 */

;(function($) {

function prepare_chart($container,options,chart_type){
  var chart;
  var dataTable;
  
  if(!options.displayLegend){
    options.displayLegend = 'none';
  }

  if(!options.colors){ options.colors = []; }
  if(!options.series){ options.series = {}; }

  var load_data_success = function(data){
     /*$(data.rows).each(function(obj) {
       data.rows[obj].c[0].v = new Date(data.rows[obj].c[0].v);
     });*/

     dataTable = new google.visualization.DataTable(data);
     if(chart_type == "line"){
       chart = new google.visualization.LineChart($container[0]);
     }else if(chart_type == "area"){
       chart = new google.visualization.AreaChart($container[0]);
     }
     
     chart_params = {title: options.title, 
					      legend: options.displayLegend, 
					      colors: options.colors, 
					      series: options.series,
					      vAxes: options.vAxes}
     chart.draw(dataTable, chart_params);
     $("#block-table > ul > li").last().show();
   };

   $.get(options.url,options.parameters,load_data_success,"json");

}

$.fn.stickChart = function(options){
  var $container = $(this);

  if(!options.displayLegend){
    options.displayLegend = 'none';
  }

  function load_data_success(data){
    var dataTable = new options.api.visualization.DataTable(data);
    var chart = new options.api.visualization.ColumnChart($container[0]);
    if(!options.hAxis){ options.hAxis = null }
    chart_params = {title: options.title, hAxis: options.hAxis,
					     legend: options.displayLegend, 
					     vAxes: options.vAxes}
    chart.draw(dataTable, chart_params);  
  }

  $.get(options.url,options.parameters,load_data_success,"json");
};

$.fn.lineChart = function(options){
  prepare_chart($(this),options,"line");
}

$.fn.areaChart = function(options){
   prepare_chart($(this),options,"area");
}

$.fn.comboChart = function(options){
  var $container = $(this);

  if(!options.displayLegend){
    options.displayLegend = 'none';
  }else{
    options.displayLegend = 'right';
  }
  
  if(!options.colors){ options.colors = []; }
  if(!options.series){ options.series = {}; }

  function load_data_success(data){
    _title = "";
    var dataTable = new options.api.visualization.DataTable(data);
    var chart = new options.api.visualization.ComboChart($container[0]);
    chart.draw(dataTable, { title: options.title, 
								    legend: options.displayLegend,  
								    colors: options.colors, 
								    series: options.series,
								    seriesType: options.seriesType,
								    vAxes: options.vAxes}								    
								   );  
  }

  $.get(options.url,options.parameters,load_data_success,"json");
}

$.fn.timeLineChart = function(options){
   var $container = $(this);

   if(!options.displayLegend){ options.displayLegend = true; }
   

   function load_data_success(data){
     $(data.rows).each(function(obj) {
       data.rows[obj].c[0].v = new Date(data.rows[obj].c[0].v);
     });

     var dataTable = new google.visualization.DataTable(data);
     var chart = new google.visualization.AnnotatedTimeLine($container[0]);
     chart.draw(dataTable, {allowRedraw: true, legendPosition:'newRow', displayZoomButtons: options.displayLegend});
     $container.prepend("<b>"+options.title+"</b>");
     $("#block-table > ul > li").last().show();
   }

   $.get(options.url,options.parameters,load_data_success,"json");
};

})(jQuery);
