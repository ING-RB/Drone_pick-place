$(function () {
    $('[data-toggle="lt_popover"]').popover({
        title: 'Interactive Example',
        content: function() {
            var cmd = $(this).attr('data-examplename');
            var content = '<span>In live scripts, tasks like this one let you interactively explore parameters and generate MATLAB code. To use the tasks in this example, <a class="no-matlab" href="matlab:' + cmd + '">open the live script</a>.</span>';
            return content;
        }
    })
    $(window).trigger('popover_added');
});
