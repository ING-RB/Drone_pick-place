//New offcanvas.js

function fixStuff() {
  
  //Variables

    //Widths
    var windowWidth = window.innerWidth;
    var scrollWidth = window.innerWidth-$('.section_header').width();
    var contentWidth = 'calc(100vw - ' + scrollWidth + 'px)';

    //Heights
    var windowHeight = window.innerHeight;
    var headerHeight = $("#header_desktop").outerHeight() + $("#header_mobile").outerHeight();
    var sectionBannerHeight = $(".section_header").outerHeight();
    var bodyHeight = $("#responsive_offcanvas").outerHeight();
    var contentHeight = $(".offcanvas_content_container").outerHeight();
    
    // Height Calcs
    var fullHeaderHeight = headerHeight + sectionBannerHeight;
    var windowHeightSticky = windowHeight - sectionBannerHeight;    
    var leftnavHeight = windowHeight - fullHeaderHeight;    

    //Scroll Position
    var scroll = Math.max(window.pageYOffset, document.documentElement.scrollTop, document.body.scrollTop);

    //Dynamics
    var revleftnavHeight = leftnavHeight + scroll;

  //Set Off-Canvas Nav default height  
  $('.sidebar-offcanvas').css('height', leftnavHeight);  

  if (scroll > headerHeight) {
    $("#responsive_offcanvas").addClass("locked");
    $('.sidebar-offcanvas').css('height', windowHeightSticky);
    $('.sidebar-offcanvas').css('position', 'fixed');
    $('.sidebar-offcanvas').css('top', sectionBannerHeight);
  } else {
    $("#responsive_offcanvas").removeClass("locked");
    $('.sidebar-offcanvas').css('position', 'absolute');
    $('.sidebar-offcanvas').css('height', revleftnavHeight);
    $('.sidebar-offcanvas').css('top', '');
  } 

  //Reset if JS doesn't catch the scroll-to-top because of performance issues
  if ($(window).scrollTop() == 0) {
    $('.sidebar-offcanvas').css('height', leftnavHeight);  
    $('.sidebar-offcanvas').css('top', ''); 
    $('.sidebar-offcanvas').css('position', 'absolute');
  }  

  //For Mobile: Calculate the width of the scrollbar, and adjust the content width accordingly
  if (windowWidth < 768) {
    contentWidth = 'calc(100vw - ' + (scrollWidth + 32) + 'px)';
    $('.offcanvas_content_container').css('padding-right',scrollWidth);
    $('.sticky_header_container').css('width',contentWidth);
    $('.content_container').css('width',contentWidth);
    $('.cta_container_mobile').css('width',contentWidth);
    $('.body_trail_container').css('width',contentWidth);
    $('#footer').css('width',contentWidth); 
  } else {
    $('.offcanvas_content_container').css('padding-right',0);
    $('.sticky_header_container').css('width','auto');
    $('.content_container').css('width','auto');
    $('.cta_container_mobile').css('width','auto');
    $('.body_trail_container').css('width','auto');
    $('#footer').css('width','auto');     
  }  
}


$(document).ready( function() {
  fixStuff();
});


$(window).scroll(function() {
  fixStuff();

});  

$(window).on('resize orientationchange', function () {
  fixStuff();
}); 


(function() {

  $(document).ready(function () {

    if ($('.row-offcanvas').hasClass('active')) {
      $('#nav_list_wrapper a').removeAttr('aria-hidden');
      $('#nav_list_wrapper a').removeAttr('tabindex');
      
      $('#responsive_offcanvas').addClass('offcanvas_active');
    } else {
      $('#nav_list_wrapper a').attr('aria-hidden', 'true');
      $('#nav_list_wrapper a').attr('tabindex', '-1');            
    }

    $('[data-toggle=offcanvas]').click(function () {
      $('.row-offcanvas').toggleClass('active');
      $('#nav_toggle').toggleClass('active');
      $('#responsive_offcanvas').toggleClass('offcanvas_active');
      $('#responsive_offcanvas').removeClass('no_animate');
      setCookie('MW_toc_visible', $('.row-offcanvas').hasClass('active'), getRootPath());

      if ($('.row-offcanvas').hasClass('active')) {
        $('#nav_list_wrapper a').removeAttr('aria-hidden');
        $('#nav_list_wrapper a').removeAttr('tabindex');
      } else {
        $('#nav_list_wrapper a').attr('aria-hidden', 'true');
        $('#nav_list_wrapper a').attr('tabindex', '-1');
      }

      setTimeout(fixStuff, 700)
    });
  });

  if (!isMobileWidth() && isTocOpen()) {
    $('#responsive_offcanvas').addClass('no_animate');
    $('.row-offcanvas').addClass('active');
    $('#nav_toggle').addClass('active');
  }

  function isTocOpen() {
    var tocCookie = getCookie('MW_toc_visible');
    return tocCookie === null || tocCookie === 'true';
  }

  function getCookie(name) {
    var cookies = document.cookie.split(';');
    for (var i = 0; i < cookies.length; i++) {
      var cookie = cookies[i].replace(/^\s+|\s+$/g, '');
      if (cookie.indexOf(name) === 0) {
        return cookie.substring(name.length + 1, cookie.length);
      }
    }
    return null;
  }

  function setCookie(name, value, path) {
    var date = new Date();
    date.setTime(date.getTime() + (7 * 24 * 60 * 60 * 1000));
    var expiresDate = date.toGMTString();
    document.cookie = name + "=" + value
      + "; expires=" + expiresDate
      + "; path=" + path ;
    }

  // Get the root path. This function returns the top level by default. 
  function getRootPath() {
    var pathname = $(location).attr('pathname');
    var pathArray = pathname.split("/");
    var rootPath = "/" + pathArray[1];
    return rootPath;
    }

  function isMobileWidth () {
    return $(window).width() < 768;
  }
})();





//Fixes for Polyspace Help Browser: No position:sticky support
var userAgent = navigator.userAgent;

if ((userAgent).includes("Chrome/43")) {
  $("<style>\n.content_container { padding-top:108px; }\n.section_header { position:fixed; }\n.sticky_header_container { width:100% !important; position:fixed; }\n.sidebar-offcanvas { position:fixed; top:52px; bottom:0; }\n</style>" ).appendTo( "head" );
}