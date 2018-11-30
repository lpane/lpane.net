// Current event ticker
var width = $('.ticker-text').width(),
    containerwidth = $('.ticker-container').width(),
    left = containerwidth;
$(document).ready(function(e){
	function tick() {
        if(--left < -width){
            left = containerwidth;
        }
        $(".ticker-text").css("margin-left", left + "px");
        setTimeout(tick, 20);
      }
      tick();
});
