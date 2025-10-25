function parseParams3P() {
  var params = {};
    var qs = window.location.search;
    if (qs && qs.length > 0) {
        var paramsArray = qs.replace(/^\?/,"").split("&");
        for (var i = 0; i < paramsArray.length; i++) {
            var nameValPair = paramsArray[i].split("=");
            var name = nameValPair[0];
            var value = nameValPair.length > 1 ? decodeURIComponent(nameValPair[1].replace(/\+/g," ")) : "";
            params[name] = value;
        }
    }
    return params;
}

function populateContent(allData) {
  var loadContentId;
  var hideContentId;

  if (isMainExamplePage(allData)) {
    loadContentId = "example_content";
    hideContentId = "doc_center_content";
    document.getElementById(hideContentId).style.display = "none";
    document.getElementById(loadContentId).style.display = "block";

    var styleSheetLocation = getContentStyleSheet(allData);    
    var stylesheetparams = getStyleSheetParams(allData);
    var sourcelocation = getSourceLocaton(allData);

    var localizedStrings = getLocalizedStrings();
    var allStyleSheetparams = {};
    $.extend(allStyleSheetparams, stylesheetparams);
    $.extend(allStyleSheetparams, localizedStrings);

    var examplepage = allData.examplepage;
    if (examplepage && examplepage.indexOf("demos.xml#") > -1) {
      var n = examplepage.lastIndexOf("#");
      var sectionparams = {};
      sectionparams.section = decodeURIComponent(examplepage.substring(n+1));
      $.extend(allStyleSheetparams, sectionparams);
    }
    doSaxonTransform(styleSheetLocation, sourcelocation, allStyleSheetparams);
  } else {
    loadContentId = "doc_center_content";
    hideContentId = "example_content";
    document.getElementById(hideContentId).style.display = "none";

    var page = getPageLocation(allData);
    var contentFrame = document.getElementById(loadContentId);
    contentFrame.src = page;

    iframeURLChanged(contentFrame, function (newURL) {
        // Get the page from the URL, matching characters 
        // after the last slash. 
        var page = newURL.match(/([^\/]*)$/);
        if (page) {
          expandToc(page[0]);
          contentFrame.contentWindow.scrollTo(0,0);
          window.scrollTo(0,0);
        }
    });
  }
}

function getPageLocation(allData) {
  var current_page;
  var current_dir;
  var page;
  if (allData.pagetype == "doc") {
    current_page = allData.page;
    current_dir = allData.helpdir;
  } else {
    current_page = allData.examplepage;
    current_dir = allData.exampledir;
  }
  if (allData.pageexists == "true") {
    var targetParts = current_page.split("#");
    page = current_dir + "/" + targetParts[0];
    if (page.indexOf("?") > -1) {
      page += "&";
    } else {
      page += "?";
    }
    page += "3pcontent=true";
    if (targetParts.length > 1) {
      page += "#" + targetParts[1];
    }
  } else {
    page = "3pblank.html";
  }  
  return page;
}

function isMainExamplePage(allData) {
  return ((allData.pagetype && allData.pagetype == "example") && 
          (allData.exampledir && allData.exampledir !== "") && 
          (allData.examplepage && allData.examplepage.indexOf("demos.xml") > -1));
}


function handledOnload() {
  updateLinksFromSessionStorage();
  updateContentSize(); 
  handleContextMenu();
  var aTags = document.getElementById("doc_center_content").contentDocument.documentElement.getElementsByTagName("a");
  handleDocLinksClick3P(aTags);
  var iframeElement = document.getElementById('doc_center_content');
  handleContextMenu3P(iframeElement);     
}                 

function updateLinksFromSessionStorage() {
  var docLandingPage = getSessionStorageItem("landing_page_url");
  if (docLandingPage && docLandingPage.length > 0) {
    var webDocParam = "webdocurl";
    var landingPageATags = $(".doc_landing_page");              
    landingPageATags.each(function(index) {
      var currentHref = $(this).attr("href");
      if (currentHref.indexOf(webDocParam) !== -1) {
        // nothing to add
        return;
      } 
      // preserve any old qs params
      var hasQuery = currentHref.indexOf('?');
      var currentQuery = (hasQuery >= 0 ? currentHref.substring(hasQuery + 1) : null);
      var newQuery = (currentQuery ? "?" + currentQuery + "&" + webDocParam : "?" + webDocParam);
        $(this).attr("href", docLandingPage + newQuery);
    });
    handleDocLinksClick3P(landingPageATags);
  } 
  var searchPage = getSessionStorageItem("search_page_url");
  if (searchPage && searchPage.length > 0) {
    $("#docsearch_form").attr('action', searchPage);
  }
}

function updateContentSize() {
  var contentFrame = document.getElementById("doc_center_content");
  var contentDoc = contentFrame.contentWindow.document;
  var contentHeight = contentDoc.body.scrollHeight;
  var newHeight = parseInt(contentHeight,10) + 10;
  contentFrame.style.height = "" + newHeight + "px";
  // var contentWidth = contentDoc.body.scrollWidth;
  // var newWidth = parseInt(contentWidth, 10) + 10;
  // contentFrame.style.width = "" + newWidth + "px";
  $(contentFrame).show();
  var title = contentDoc.title;
  if (title.length > 0) {
    document.title = title;
  }
}

function iframeURLChanged(iframe, callback) {
    var lastDispatched = null;
    var dispatchURLChanged = function () {
        var newHref = iframe.contentWindow.location.href;
        if (newHref !== lastDispatched) {
            callback(newHref);
            lastDispatched = newHref;
        }
    };
    var unloadHandler = function () {
        // Timeout needed because the URL changes immediately after
        // the unload event is dispatched.
        setTimeout(dispatchURLChanged, 0);
    };
    function attachUnloadHandler() {
        // Remove the unloadHandler in case it was already attached.
        iframe.contentWindow.removeEventListener("unload", unloadHandler);
        iframe.contentWindow.addEventListener("unload", unloadHandler);
    }
    iframe.addEventListener("load", function () {
        attachUnloadHandler();
        // Just in case the change wasn't dispatched during the unload event.
        dispatchURLChanged();
    });
    attachUnloadHandler();
}

function loadThirdPartyDoc() {
      const promise = getThirdPartyDocList();
      promise.done(function(customDocList) {
        if( $.isArray(customDocList) &&  customDocList.length ) {
            // sort the list by displayname
            customDocList.sort( function( a, b ) {
              a = a.displayname.toLowerCase();
              b = b.displayname.toLowerCase();
              return a < b ? -1 : a > b ? 1 : 0;
            });

            const compiledTocTmpl = JST.thirdPartyTocTmpl({thirdpartytbxes: customDocList});
            document.getElementById('third_party_toc').innerHTML = compiledTocTmpl;
            const compiledDocTmpl = JST.thirdPartyDocTmpl({thirdpartytbxes: customDocList});
            document.getElementById('third_party_doc_links').innerHTML = compiledDocTmpl;
        }
      }).fail(function(error) {
          // Handle failure in some way. Currently, a blank page is displayed.
      });
}

function getThirdPartyDocList() {
  const deferred = $.Deferred();

  $.get('/help/search/customdoclist',{},function(response) {
    deferred.resolve(response);
  }).error(function(){
    deferred.reject();
  });

  return deferred.promise();
}
