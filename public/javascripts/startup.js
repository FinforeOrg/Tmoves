$(function()
{
	//$("select").combobox();

	$(":checkbox").wrap("<div class=\"checkbox\"></div>").parent().dgStyle();
	$(":radio").wrap("<div class=\"radio\"></div>").parent().dgStyle();

	// Search box:
	$("#search").css("background", "white url(\"/images/search.png\") 95% center no-repeat").focus(function()
	{
		var self = $(this);

		if(!self.val().length)
			$("#search-tag").hide();
	})
	.blur(function()
	{
		var self = $(this);

		if(!self.val().length)
			$("#search-tag").show();
	});

	$("#search-tag").click(function()
	{
		$("#search").focus();
	});

	// Table/form selector:
	var type = "table";

	$("#type-selector a#type-" + type).append("<img src=\"/images/marker-current-black.png\" />").find("img").css({"position": "absolute", "top": "29px", "left": "12px"});

	$("#type-selector a").click(function()
	{
		$("#type-selector img").remove();

		$(this).append("<img src=\"/images/marker-current-black.png\" />").find("img").css({"position": "absolute", "top": "29px", "left": "12px"});

		var id = $(this).attr("id");
		type = id.substr(5);

		if(type == "table")
		{
			$("#block-form").addClass("hidden");
			$("#block-table").removeClass("hidden");
		}
		else if(type == "form")
		{
			$("#block-table").addClass("hidden");
			$("#block-form").removeClass("hidden");
		}
	});

	// Textarea character limiter:
	/*
	$("#block-form textarea").keydown(function(event)
	{
		var code = (event.keyCode || event.which);

		var count = 500 - this.value.length;

		if(code == 8)
			count += 1;
		else
			count -= 1;

		if(count < 0)
		{
			event.preventDefault();
			return false;
		}

		$("#char-counter").text(count);
	});*/
});