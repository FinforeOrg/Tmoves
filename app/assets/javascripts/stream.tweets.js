/*!
 * Finfore Stream Widget : Display newest Tweets and load more old tweets from services.
 * version: 0.10
 * @requires jQuery v1.3.2 or later
 *
 * options = {
      timestamp_new: String,
      timestamp_old: String,
      url: String,
      button: Element,
      delays: Number
   }
 */

;(function($) {

$.fn.liveTweet = function(options){

  if (!this.length) {
    console.log('liveTweet is disabled - no element selected');
    return this;
  }

  var load_new_tweet = false;
  var load_old_tweet = false;
  var stamp_old = options.timestamp_old;
  var stamp_new = options.timestamp_new;
  var $tweet_container = $(this);
  var $load_button = options.button;
  var auto_refresh;

  if (!options.delays) options.delays = 35000;

  function on_load_more_done(){
    load_old_tweet = false;
    if($load_button){
      $load_button.html("Load More");
      $load_button.css('color',"white");
    }
  }

  function load_more_success(response,_pathx){
    $tweet_container.append(response);
    $.el_loadmore = $(".more_tweets_info"+_pathx.toString());

    if(response && response != ""){
      if($.el_loadmore.attr("bottomstamp")){ stamp_old = $.el_loadmore.attr("bottomstamp"); }
      if(!stamp_new){
        stamp_new = $.el_loadmore.attr("topstamp");
        start_auto_refresh();
      }
      $.el_loadmore.remove();
    }
    on_load_more_done();
  }

  function random_numbers(){
     return Math.ceil(Math.random()*100000000);
  }

  function start_load_more(){
    var _pathx = random_numbers();
    var _dataObject =  { "before_at" : stamp_old, "pathx" : _pathx };
    if(!stamp_new) _dataObject = { "before_at" : stamp_old, "pathx" : _pathx, "first_load" : true }
    $.get(options.url, _dataObject, 
          function(response) {load_more_success(response,_pathx)}).error(on_load_more_done);
  }

  function reload_new_tweet_success(response,_pathNew){
    $tweet_container.find(".header").after(response);

    if($tweet_container.find(".new_tweet").length){
      $('.notification.information').find("span").html($tweet_container.find(".new_tweet").length);
      $('.notification.information').show();
    }

    $.el_new_load = $(".more_tweets_info"+_pathNew.toString());
              
    if(response && response != ""){
       if($.el_new_load.attr("topstamp")){ stamp_new = $.el_new_load.attr("topstamp"); }
       $.el_new_load.remove();
    }
    load_new_tweet = false;
  }

  function start_auto_refresh(){
     auto_refresh = setInterval(reload_new_tweet, options.delays);
  }

  var reload_new_tweet = function(){
    if(!load_new_tweet){
       load_new_tweet = true;
       var _pathNew = random_numbers();
       $.get(options.url, { "after_at" : stamp_new, "pathx" : _pathNew }, 
             function(response){reload_new_tweet_success(response,_pathNew)}).error(function(){load_new_tweet = false;});
    }
  };

  var reload_total_records = function(){
    $.get(options.total_record_url, {},
          function(response) {
             if(response && response != ""){
               var _total_page = $.formatNumber( response, {format:"#,000"} )
               $("span.total_records").html(" Total Records: "+_total_page);
             }
          });
  }
  
  if($load_button) {
    $load_button.live("click",function(){
      if(!load_old_tweet){
        load_old_tweet = true;
        $load_button.html("loading..");
        $load_button.css('color',"silver");
        start_load_more();
      }
    });
    if(!stamp_new){ $load_button.click(); }
  }

  $('.notification.information').live("click",function(){
     $new_tweets = $tweet_container.find(".new_tweet");
     $new_tweets.fadeIn();
     $new_tweets.removeClass("new_tweet");
     $('.notification.information').hide();
  });

  
  if(stamp_new){ start_auto_refresh(); }
  
  if(options.total_record_url){
    var refresh_total_page = setInterval(reload_total_records, options.delays);
  }
  

};

})(jQuery);
