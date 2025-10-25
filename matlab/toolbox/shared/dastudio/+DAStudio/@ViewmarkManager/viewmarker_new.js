
// Copyright 2014 MathWorks, Inc.

// DO NOT CHANGE THIS!
// CLIENT DATA HAS BEEN SAVED THAT RELIES ON THIS BEING EXACTLY
// "_N_E_W_L_I_N_E_"
// "_S_I_N_G_L_E_Q_U_O_T_E_"
var NEWLINE_STANDIN = "_N_E_W_L_I_N_E_";
var NEWLINE_STANDIN_REGEX = new RegExp(NEWLINE_STANDIN, "g");
var SINGLE_QUOTE_STANDIN = "_S_I_N_G_L_E_Q_U_O_T_E_";
var SINGLE_QUOTE_STANDIN_REGEX = new RegExp(SINGLE_QUOTE_STANDIN, "g");
// SERIOUSLY, DON'T CHANGE IT!

var VIEWBOX_X_WIDTH = 700;
var VIEWBOX_Y_WIDTH = 365;
var SVG_ASPECT_RATIO = VIEWBOX_Y_WIDTH/VIEWBOX_X_WIDTH;
var DIV_ASPECT_RATIO = SVG_ASPECT_RATIO;

var viewmarkHeight= 0;
var viewportHeight = 0;

var singleFadeHandle;

function svgClicked() {
    div = document.getElementsByClassName('Viewmarkerframe')[0];
    window.clearInterval(singleFadeHandle);
    div.style.opacity = 1;
}

function scrolled() {
}

function sizeDivsToAspectRatio(className) {
    var divs = document.getElementsByClassName(className);
    var firstWidth = 0;
    for (var i = 0; i < divs.length; ++i) {
        var boundingRect = divs[i].getBoundingClientRect();
        if (boundingRect.width > 0) {
            // The divs may not have exactly the same width.
            // Using the width of the first div ensures they end up with uniform height.
            firstWidth = boundingRect.width;
            break;
        }
    }
    
    for (var i = 0; i < divs.length; ++i) {
        divs[i].style.height = (firstWidth * DIV_ASPECT_RATIO - 25).toFixed(0) + 'px';
    }
    
    viewmarkHeight = firstWidth * DIV_ASPECT_RATIO;
}

function handleSvgLoaded(ev) {
    sizeSingleSvgToFrame(this);
}

function loadSvgs(beginIndex, endIndex) {
    var svgs = document.getElementsByClassName("svg_image");
    for (var i = beginIndex; i < endIndex; ++i) {
        var svg = svgs[i];
		
        var svgSrc = svg.getAttribute("src");
        svg.setAttribute("src", svgPath[i]);
        svg.addEventListener("load", handleSvgLoaded);
    }
}

function sizeSingleSvgToFrame(svgIFrame) {
    try {
        var svgIFrameRect = svgIFrame.getBoundingClientRect();
        var svg = svgIFrame.contentDocument.getElementsByTagName('svg')[0];

        var svgWidth = (svgIFrameRect.width).toFixed(2);
        if (svgWidth > 0) {
            svg.setAttribute('width', svgWidth);
            svg.setAttribute('height','100%');
        }
    } catch (e) {
        // Swallowing exceptions so that one SVG failing to load doesn't doom the whole page.
    }
}

function sizeAllSvgsToFrames(beginIndex, endIndex) {
    var svgFrames = document.getElementsByClassName("svgframe");
    for (var i = beginIndex; i < endIndex; ++i) {
        var svgIFrame = svgFrames[i].getElementsByTagName('iframe')[0];
        sizeSingleSvgToFrame(svgIFrame);
    }
}

function getUpdateCommand(viewMarkerId, newValue, field, modelname) {
   if (field=='name')
      command = "slprivate('slsfviewmark', '" + 'global' + "', 'modifyname',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='annotation')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'modifyannotation',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='delete')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'delete',  '" + viewMarkerId +  "') "
   else if (field=='close')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'closeUI')"
   else if (field=='printout')
      command = "disp('" + newValue + "');";

   return command;
}

function getByClass(className, target) {
	return getAllByClass(className, target)[0];
}

function getAllByClass(className, target) {
	var target = target || document;
	return target.getElementsByClassName(className);
}

function hasClass(div, className) {
    var findClassRegex = new RegExp("(?:\\s|^)" + className + "(?:\\s|$)");
    return div.className.search(findClassRegex) !== -1;
}

function addClass(div, className) {
    if (!hasClass(div, className)) {
	div.className += " " + className;
    }
}

function removeClass(div, className) {
    var findClassRegex = new RegExp("(?:\\s|^)" + className + "(?:\\s|$)", "g");
    if (hasClass(div, className)) {
        div.className = div.className.replace(findClassRegex, "");
    }
}

function activate(ev) {
    removeClass(ev.target, "inactive");
    addClass(ev.target, "active");
    svgClicked();
}

function deactivate(ev){
    removeClass(ev.target, "active");
    addClass(ev.target, "inactive");
}

function updateViewMarker(viewMarkerId, newValue, field) {
    var MATLAB_COMMAND_PREFIX = "matlab:";

    // getUpdateCommand is assumed to have been defined before this is called
    var updateNameCommand = MATLAB_COMMAND_PREFIX + getUpdateCommand(viewMarkerId, newValue, field, DEFAULT_ANCHOR_ID);  

    // viewMarketQtBridge is exposed by QtWebBrowser2::slotAddViewMarkerQtBridgeToJS
    // updateViewMarker is defined as a signal on ViewMarkerQtBridge in QtWebBrowser.hpp.
    // The slot is handled by QtWebBrowser2::handleLinkClicked(QString).
    // DEPRECATED :: TO BE REPLACED when .click() functionality is available.
    try {
        viewMarkerQtBridge.updateViewMarker(updateNameCommand);
        return true;
    } catch(ex) {
        console.log(ex);
        // TODO: somehow alert that we can't update?
        // Presently just silently fails.
    }
    
    return false;
}

function getViewMarkerId(viewmarkerFrame) {
    return (getByClass("viewMarkerId", viewmarkerFrame)).value;
}

var lastNewName = "";
function update(ev) {
    var newName = ev.target.value;  // it's tempting to call .trim(), but .trim() doesn't always handle i18n well
    if (lastNewName === newName) {
        return;
    }
    lastNewName = newName;

    var viewMarkerFrame = ev.target.parentElement.parentElement;
    var viewMarkerId    = getViewMarkerId(viewMarkerFrame);
    
    if (updateViewMarker(viewMarkerId, encodeSingleQuote(newName), "name")) {
        ev.target.title = newName;
    } else {
        ev.target.title = "UPDATE ERROR";
    }
}

function showEditor(ev) {
    svgClicked();
    addClass(document.body, "lockControls");
    
    var viewMarkerFrame = ev.target.parentElement;
    var glass           = getByClass("glass", viewMarkerFrame);
    var editPane        = getByClass("editPane", viewMarkerFrame);
    var textArea        = editPane.getElementsByTagName("textarea")[0];
    
    textArea.value = glass.title;
    editPane.style.display = "block";
    
    textArea.focus();
}

function hideEditor(ev) {
    removeClass(document.body, "lockControls");
    var editPane = ev.target.parentElement;
    editPane.style.display = "none";
}

function deleteViewMark(ev) {
    svgClicked();
    addClass(document.body, "lockControls");

    var viewMarkerFrame = ev.target.parentElement;
    var viewMarkerId = getViewMarkerId(viewMarkerFrame);
    
    updateViewMarker(viewMarkerId, " ", "delete");
    
    var SLIDE_OUT_STEP = 50;  // pixels
    var parentViewMarker = ev.target.parentElement;

    slideOut(parentViewMarker, SLIDE_OUT_STEP, function(div) {
      div.parentElement.removeChild(div);
    });

    deleteAndClose = window.setTimeout(function() {
	updateViewMarker("", " ", "close");
    }, 400);
}

function encodeNewlines(string) {
    return string.replace(/\n/g, NEWLINE_STANDIN);
}

function decodeNewlines(string) {
    return string.replace(NEWLINE_STANDIN_REGEX, "\n");
}

function encodeSingleQuote(string) {
    return string.replace(/'/g, SINGLE_QUOTE_STANDIN);
}

function decodeSingleQuote(string) {
    return string.replace(SINGLE_QUOTE_STANDIN_REGEX, "'");
}

function saveViewMarkerAnnotation(ev) {
    var editPane = ev.target.parentElement;
    var viewMarkerFrame = editPane.parentElement;
    var textArea = editPane.getElementsByTagName("textarea")[0];
    
    var viewMarkerId = getViewMarkerId(viewMarkerFrame);
    var newAnnotation = textArea.value;
    
    // MATLAB errors if there is a newline in the string we send it.
    // Replace \n with the NEWLINE_STANDIN.
    var newlineEncodedNewAnnotation = encodeSingleQuote(encodeNewlines(newAnnotation));
    var glass = getByClass("glass", viewMarkerFrame);
    if (updateViewMarker(viewMarkerId, newlineEncodedNewAnnotation, "annotation")) {
        glass.title = newAnnotation;
    } else {
        glass.title = "UPDATE ERROR";
    }
    
    // TODO: alert if fails
}

function stopEvent(ev) {
    ev.preventDefault();
    return false;
}

function textAreaOnPasteCallback(ev) {
    var textArea = ev.target;
    var copiedData = ev.clipboardData.getData("text/plain");
		
    if (copiedData.length > textArea.maxLength) {
        var warningDescLenPane = getByClass("warningDescLen");
        warningDescLenPane.style.display = "block";
    }
}

function handleLayout() {
    sizeDivsToAspectRatio("viewmarkerframe_inner");
}

function slideOut(div, step, onComplete) {
    var viewportWidth = document.body.clientWidth;
    div.style.position = "relative";
    div.style.left = "0px";

    var slideHandle = window.setInterval(function() {
        var left = parseInt(div.style.left);
        if (left > viewportWidth) {
            window.clearInterval(slideHandle);
            onComplete(div);
            return;
        }

        left += step;
        div.style.left = left + "px";
    }, 30);
}

function handleWindowResize() {
    var OPACITY_STEP     = -0.1;

    handleLayout();
    sizeAllSvgsToFrames(0, 1);
    viewportHeight = document.body.clientHeight;
    pageHeight = document.documentElement.offsetHeight;

    div = document.getElementsByClassName('Viewmarkerframe')[0];
}

window.onload = function() {
    handleLayout();
		
    // Show the page.
    var pageHider = document.getElementById("hidePage");
    pageHider.id = "";

    var labels = document.getElementsByClassName("nameLabel");
    for (var i = 0; i < labels.length; ++i) {
        var label = labels[i];
        label.addEventListener("click", activate);
        label.addEventListener("blur", deactivate);
        label.addEventListener("keyup", update);
        label.addEventListener("change", update);
        label.title = label.value;  // add name as tool tip
        label.addEventListener("dragstart", stopEvent);
    }
    
    var editButtons = document.getElementsByClassName("editButton");
    for (var i = 0; i < editButtons.length; ++i) {
        var editButton = editButtons[i];
        editButton.addEventListener("click", showEditor);
    }
    
    var deleteButtons = document.getElementsByClassName("deleteButton");
    for (var i = 0; i < deleteButtons.length; ++i) {
        var deleteButton = deleteButtons[i];
        deleteButton.addEventListener("click", deleteViewMark);
    }

    var closeButtons = document.getElementsByClassName("closeButton");
    for (var i = 0; i < closeButtons.length; ++i) {
        var closeButton = closeButtons[i];
        closeButton.addEventListener("click", hideEditor);
    }
    
    var saveButtons = document.getElementsByClassName("saveButton");
    for (var i = 0; i < saveButtons.length; ++i) {
        var saveButton = saveButtons[i];
        saveButton.addEventListener("click", saveViewMarkerAnnotation);
    }
    
    var anchors = document.getElementsByTagName("a");
    for (var i = 0; i < anchors.length; ++i) {
        anchors[i].addEventListener("dragstart", stopEvent);
    }

    var textAreas = document.getElementsByTagName("textarea");
    for (var i = 0; i < textAreas.length; ++i) {
        textAreas[i].addEventListener("dragstart", stopEvent);
        textAreas[i].addEventListener("paste", textAreaOnPasteCallback);
        textAreas[i].addEventListener("keyup", saveViewMarkerAnnotation);
        textAreas[i].addEventListener("change", saveViewMarkerAnnotation);
    }
    
    var glasses = getAllByClass("glass");
    for (var i = 0; i < glasses.length; ++i) {
        glasses[i].title = decodeNewlines(glasses[i].title);
    }
    
    loadSvgs(0, 1);

    window.onresize = handleWindowResize;    
    
    var OPACITY_STEP = -0.01;
    
    div = document.getElementsByClassName('Viewmarkerframe')[0];
    opacity = 1;
    
    setTimeout(function () {
	singleFadeHandle = window.setInterval(function() {
	    if (opacity < 0) {
	        window.clearInterval(singleFadeHandle);
		updateViewMarker("", " ", "close");
	        return;
	    }
	    opacity += OPACITY_STEP;
	    div.style.opacity = opacity;
	}, 15);
    }, 250);
}
