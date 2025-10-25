$(document).ready(function(){
  var params = isCustomDocInIframe() ? parseParams3P() : docPageParams;  
  params = populateAllParams(params);
  loadCustomDoc(params);
});

function isCustomDocInIframe() {
    return typeof populateContent === 'function';
}

function populateAllParams(params) {
  var allParams = {};
  $.extend(allParams, params);
  allParams.url = window.location.href;
  return allParams;
}

function loadCustomDoc(allParams) {
  handledTocChanged(allParams);
  if (isDemosXml()) {
      document.getElementById('example_content').style.display = 'block';
      handleDemosXml(allParams);
  } else {
      document.getElementById('html_content').style.display = 'block';
  }
  populateTOC(allParams);
}

function isDemosXml() {
    var page = window.location.pathname.split("/").pop();
    return page === 'demos.xml';
}

function handleDemosXml(allParams) {
    let docroot = _getDocroot();
    let styleSheet = getDemosXMLStyleSheet(allParams);
    let demosXmlUrl = new URL(document.location.href);
    demosXmlUrl.searchParams.set('template', 'false');
      
    var stylesheetparams = getStyleSheetParams(allParams);
    var localizedStrings = getLocalizedStrings();
    var allStyleSheetparams = {};
    $.extend(allStyleSheetparams, stylesheetparams);
    $.extend(allStyleSheetparams, localizedStrings);
    SaxonJS.transform({
        stylesheetLocation: styleSheet,
        sourceLocation: demosXmlUrl.toString(),
        stylesheetParams: allStyleSheetparams          
    });
}

function handleCustomDocContent() {
    const iframeElt = document.getElementById("doc_center_content");
    var links = iframeElt.contentDocument.documentElement.getElementsByTagName("a");
    addHrefTargets(links);
    var timeout = false;
    updateContentSize();
    addEventListener("resize", evt => {
        // Debounce calls to updateContentSize. Only
        // call updateContentSize when we haven't received
        // a resize event in the last 100 milliseconds.
        clearTimeout(timeout);
        timeout = setTimeout(updateContentSize, 100);
    });
}

function updateContentSize() {
    // Update the size of the iframe based on the content.
    // This prevents the iframe from displaying with a scrollbar.
    const iframeElt = document.getElementById("doc_center_content");
    var contentHeight = iframeElt.contentDocument.body.scrollHeight;
    var newHeight = 10 + contentHeight;
    iframeElt.style.height = "" + newHeight + "px";
}

function addHrefTargets(links) {
    var curPage = document.location;
    for (let link of links) {
        var href = link.getAttribute('href');
        if (!href || href.startsWith('#')) {
            continue;
        }

        const hrefURL = new URL(link.href);
        if (hrefURL.protocol.toLowerCase() === 'matlab:') {
            link.addEventListener("click", evt => {
                evt.preventDefault();
                let href = evt.target.href;
                let matlabCommand = getMatlabCommand(href);
                showMatlabDialog(matlabCommand);            
            });
        } else if (hrefURL.host != curPage.host) {
            // This is an external link. Open it in a new browser window.
            link.setAttribute("target", "_blank");
        } else {
            link.setAttribute("target", "_parent");
        }
    }
}


function handledTocChanged(allParams) {
    var docpage = getDocPage(allParams);
    // Set up an observer to expand the TOC when it changes.
    var target = document.getElementById('3ptoc');
    // Create an observer instance linked to the callback function
    var observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
            expandToc(docpage);
            if (isCustomDocInIframe()) {
                var aTags = document.getElementById('3ptoc').getElementsByTagName('a');
                handleDocLinksClick3P(aTags);
            }
        });
    });
    observer.observe(target, { childList: true });
}

function _getDocroot() {
  var docroot = _getSessionStorageValue('docroot');
  if (docroot && docroot.length > 0) {
    return docroot;
  }
  var href = window.location.href;
  // Match on the first occurance of 'help'.
  var regexp = /^(.*?\/help\/)(.*)/;
  var match = regexp.exec(href);
  docroot = match[1];  
  _setSessionStorageValue('docroot', docroot);
  return docroot;
}

function _getSessionStorageValue(key) {
    var value;
    try {
        value = window.sessionStorage.getItem(key);
    } catch (e) {
        value = null;
    }
    return value;
}

function _setSessionStorageValue(key, value) {
  window.sessionStorage.setItem(key, value);
}

function populateTOC(allData) {
  var styleSheetLocation = getTocStyleSheet(allData);    
  var stylesheetparams = getStyleSheetParams(allData);
  var sourcelocation = getTocSource(allData);

  var localizedStrings = getLocalizedStrings();
  var allStyleSheetparams = {};
  $.extend(allStyleSheetparams, stylesheetparams);
  $.extend(allStyleSheetparams, localizedStrings);

  doSaxonTransform(styleSheetLocation, sourcelocation, allStyleSheetparams);
}

function getDocPage(allData) {
  return allData.pagetype === 'example' ? allData.examplepage : allData.page;
}

function getTocSource(allData) {
  var dir;
  var file;
  if (allData.pagetype === 'example') {
    dir = allData.exampledir;
    file = 'demos.xml?template=false';
  } else {
    dir = allData.helpdir;
    file = 'helptoc.xml';
  }
  if (dir.charAt(dir.length -1) != '/') {
    dir = dir + '/';
  }
  return new URL(file, dir).toString();
}

function getTocStyleSheet(allData) {
  var docroot = _getDocroot();
  var styleSheetFile;
  if (allData.pagetype === 'example') {
    styleSheetFile = '3pdemostoc-sef.json';
  } else {
    styleSheetFile = '3ptoc-sef.json';
  }
  return new URL('customdoc/includes/shared/scripts/' + styleSheetFile, docroot).toString();
}

function getDemosXMLStyleSheet(allData) {
  var contentStyleSheetURL = new URL('customdoc/includes/shared/scripts/3pdemos-sef.json', _getDocroot());
  return contentStyleSheetURL.toString();
}

function _getStyleSheetParam(allData, identifier) {
    if (allData[identifier]) {
        return allData[identifier];
    } else {
        return '';
    }
}

function getStyleSheetParams(allData) {
  var stylesheetparams = {};
  stylesheetparams.docroot = _getDocroot();
  var exampledir = _getStyleSheetParam(allData, 'exampledir');
  stylesheetparams.exampledir = exampledir;
  stylesheetparams.demosroot = exampledir;
  stylesheetparams.helpdir = _getStyleSheetParam(allData, 'helpdir');
  stylesheetparams.languageDir = _getStyleSheetParam(allData, 'languageDir');
  stylesheetparams.docpage = _getStyleSheetParam(allData, 'page');
  stylesheetparams.matlabres = _getDocroot() + 'customdoc/includes';
  return stylesheetparams;
}

function getLocalizedStrings() {
  var localizedStrings = {};
  localizedStrings.mfile = getLocalizedString("3p_examples_mfile");
  localizedStrings.mfiledesc = getLocalizedString("3p_examples_mfiledesc");
  localizedStrings.mgui = getLocalizedString("3p_examples_mgui");
  localizedStrings.mguidesc = getLocalizedString("3p_examples_mguidesc");
  localizedStrings.model = getLocalizedString("3p_examples_model");
  localizedStrings.modeldesc = getLocalizedString("3p_examples_modeldesc");
  localizedStrings.productlink = getLocalizedString("3p_examples_productlink");
  localizedStrings.uses = getLocalizedString("3p_examples_uses");
  localizedStrings.video = getLocalizedString("3p_examples_video");
  localizedStrings.videodesc = getLocalizedString("3p_examples_videodesc");
  return localizedStrings;
}

function doSaxonTransform(stylesheetlocation, sourcelocation, stylesheetparams) {
    SaxonJS.transform({
        stylesheetLocation: stylesheetlocation,
        sourceLocation: sourcelocation,
        stylesheetParams: stylesheetparams
    });
}

function expandToc(page) {
   // Remove the query string parameters inorder to match against the TOC ids.
   var hasQS = page.indexOf('?');
   if (hasQS > 0) {
     page = page.substring(0, hasQS);
   }
   page = page.replace(/([;&,\.\+\*\~':"\!\^#$%@\[\]\(\)=>\|\/])/g, '\\$1');
   toc = $("#3ptoc");   
   // Clear the current page highlight.
   toc.find("li.current_page").removeClass('current_page');
   var current = toc.find('[id="' + page + '"]');
   // Add the current page highlight.
   current.addClass('current_page');
   if (current.hasClass("toc_collapsed")) {
     current.removeClass("toc_collapsed");
     current.addClass("toc_expanded");
   }
   var tocParents = current.parents();
   tocParents.removeClass("toc_collapsed");
   tocParents.addClass("toc_expanded");
}
