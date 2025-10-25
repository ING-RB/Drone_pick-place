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

var VIEWBOX_X_WIDTH = 570;
var VIEWBOX_Y_WIDTH = 365;
var SVG_ASPECT_RATIO = VIEWBOX_Y_WIDTH / VIEWBOX_X_WIDTH;

var SCROLL_RESPONSE_DELAY_MS = 200;

// this specifies how much percentage of width each viewmark has when there are x (x=1,2,3,4,5,6)
// viewmarks per row on the manager UI
var RATIO_SET = [];
RATIO_SET[1] = "80%";
RATIO_SET[2] = "46%";
RATIO_SET[3] = "32%";
RATIO_SET[4] = "23%";
RATIO_SET[5] = "19%";
RATIO_SET[6] = "15%";

var ratioIndex = 0;

var numberPerRow   = 3;
var viewmarkHeight = 0;
var viewportHeight = 0;
var pageLoaded     = false;

var onloadSVGResizeBegin = 0;
var onloadSVGResizeEnd   = 0;

var idForDelete = 0;
var groupForDelete = '';
var collapsedViewmarks = 0;

var groups;
var groupStates;

var canvases;
var rowPerViewPort;
var viewmarksPerViewport;

var showSpinnerHandle = null;
var totalChecked = 0;
var totalChecked_global = 0;
var totalChecked_model = 0;
var manageMode = 0;
var globalview = 1;
var windowYOffset = 0;
var windowYOffsetModel = 0;
var hiddenViewmarkWidth = 0;

function mouseUpForCloseUI() {
	if(manageMode) {
		return;
	}
		
    if (this === event.target) {
        updateViewMarker("", " ", "closeUI");
    }
}

function responsivelyLoadSVGs() {
    if (!globalview) {
        return;
    }

    var begin_target = Math.max(Math.floor((window.pageYOffset/document.documentElement.offsetHeight) * (canvases.length - collapsedViewmarks)) - numberPerRow, 0);
    var end_target   = Math.min(begin_target + viewmarksPerViewport + 2*numberPerRow, canvases.length - collapsedViewmarks);

    var sum = 0;
    var totalWithCollapsed = 0;

    for(var i_grp=0; i_grp<groupStates.length; i_grp++) {
        var groupState = groupStates[i_grp];
        var begin_i = groupState.beginIndx;
        var end_i   = groupState.endIndx

        if (groupState.expanded) {
            for(var k = Math.max(begin_i, begin_target)+totalWithCollapsed; k <= Math.min(end_i, end_target)+totalWithCollapsed; k++) {
                loadSvgSingle(k);
                sum+=1;
            }                
            begin_target += sum;
            sum=0;
            
        } else {
            totalWithCollapsed += (end_i - begin_i)+1;
        }

        if (begin_target >= end_target) {
            break;
        }
    }
}

var delayedExec = function(after, fn) {
    var timer;
    return function() {

        timer && clearTimeout(timer);
        timer = setTimeout(fn, after);
    };
};

var scrolled = delayedExec(SCROLL_RESPONSE_DELAY_MS, function() {

    if (pageLoaded) {
        responsivelyLoadSVGs();
    }
    else {
        var currentViewportHeight = document.body.clientHeight;

        if (viewportHeight !=0 && currentViewportHeight == viewportHeight) {
            pageLoaded = true;
        }
    }
});

function imageClicked(ev) {
    if (!manageMode) {
        showSpinnerHandle = window.setTimeout(function() {
            var spinner = getByClass("spinner");
            removeClass(spinner, "spinner_msg");
            spinner.style.display = 'block';

            var spinner_title = getByClass("spinner_title", spinner);
            spinner_title.style.display = "none";
	    
            var spinnerwarning = getByClass("spinner_warning", spinner);
            spinnerwarning.style.display = 'none';
            
        }, 400);        

        var id = this.parentElement.parentElement.id;
        if (globalview) {
            updateViewMarker(id, 'global', 'open');
            updateViewMarker(id, 'global', 'markavailable');
        }else{
            updateViewMarker(id, 'model', 'open');
            updateViewMarker(id, 'model', 'markavailable');
        }
    }else{
        var frame = ev.target.parentElement.parentElement.parentElement;
        var checkbox = getByClass("selectCheckbox", frame);
        alterCheckBoxStates(checkbox, frame, checkbox.checked?false:true);
        if (checkbox.checked) {
            checkbox.checked = false;
        }else{
            checkbox.checked = true;
        }
    }
}

function cancelSpinner(id) {
    var spinner = getByClass("spinner");
    addClass(spinner, "spinner_msg");
    removeClass(spinner, "spinner_image");

    var spinner_title = getByClass("spinner_title", spinner);
    spinner_title.style.display = "block";

    var spinnertext = getByClass("spinner_text", spinner);
    spinnertext.style.display = 'none';

    var spinnerwarning = getByClass("spinner_warning", spinner);
    spinnerwarning.style.display = 'block';

    var viewmark = document.getElementById(id);    // add a class for bad state
    viewmark.style.background = "rgba(153,153,153, 1)";

    var imgFrame = getByClass("imgframe", viewmark);
    imgFrame.style.opacity = "0.3";

    idForDelete = id;
    spinner.style.display = 'block';
    
    updateViewMarker(id, '', 'markunavailable');

    showSpinnerHandle && window.clearTimeout(showSpinnerHandle);
}

function handleSvgLoaded(ev) {
    sizeSingleSvgToFrame(this);
}

function sizeSingleSvgToFrame(svgIFrame) {
    try {
        var svg = svgIFrame.contentDocument.getElementsByTagName('svg')[0];

        var parent = svgIFrame.parentElement;
        var parentRect = parent.getBoundingClientRect();

        if (parentRect.width > 0) {
            svgIFrame.width = Math.floor(parentRect.width);
            svgIFrame.height = Math.floor(parentRect.height);
            svg.setAttribute('width', parentRect.width);
            svg.setAttribute('height', parentRect.height);
        }
    } catch (e) {
        // Swallowing exceptions so that one SVG failing to load doesn't doom the whole page.
    }
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

    if (firstWidth === 0) {
        firstWidth = getHiddenViewmarkWidth();
    }

    if (firstWidth > 0) {
        for (var i = 0; i < divs.length; ++i) {
            divs[i].style.height = (firstWidth * SVG_ASPECT_RATIO).toFixed(0) + 'px';
        }

        viewmarkHeight = firstWidth * SVG_ASPECT_RATIO;
    }
}

function loadSvgs(beginIndex, endIndex) {
    for (var i = beginIndex; i < endIndex; ++i) {
        loadSvgSingle(i);
    }
}

function loadSvgSingle(index) {
    var canvas = canvases[index];
    if (canvas!=undefined && !canvas.imageLoaded) {
        var iframe = canvas.parentNode.querySelector("iframe");
        iframe.onload = function() {
            var img = canvas.parentNode.querySelector("img");
            img.onload = function() {
                var cxt = canvas.getContext("2d");
                var canvasRect = canvas.getBoundingClientRect();
                canvas.width = canvasRect.width;
                canvas.height = canvasRect.height;  
                cxt.drawImage(img, 0, 0, canvas.width, canvas.height);
            };
            if (canvas.imagePath) {
                img.src = canvas.imagePath;
            }  
        };
	
        if (canvas.imagePath) {
            iframe.src = canvas.imagePath;
        }
        canvas.imageLoaded = true;
    }
}

function getUpdateCommand(viewMarkerId, newValue, field, modelname) {
   if (field=='open')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'open', '" + viewMarkerId  +  "', '" + newValue + "'); "
   else if (field=='name')
      command = "slprivate('slsfviewmark', '" + 'global' + "', 'modifyname',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='name_model')
      command = "slprivate('slsfviewmark', '" + 'model' + "', 'modifyname',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='annotation')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'modifyannotation',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='annotation_model')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'modifyannotation_model',  '" + viewMarkerId +  "', '" + newValue + "') "
   else if (field=='delete')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'delete',  '" + viewMarkerId +  "') "
   else if (field=='copy')
      command = "slprivate('slsfviewmark', '" + newValue + "', 'copy',  '" + viewMarkerId +  "') "
   else if (field=='delete_model')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'delete_model',  '" + viewMarkerId +  "') "
   else if (field=='markunavailable')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'markunavailable', '" + viewMarkerId  +  "'); "
   else if (field=='markavailable')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'markavailable', '" + viewMarkerId  +  "'); "
   else if (field=='closeUI')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'closeUI') "
   else if (field=='deletegroup')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'deletegroup',  '" + viewMarkerId +  "') "
   else if (field=='deletegroup_model')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'deletegroup_model',  '" + viewMarkerId +  "') "
   else if (field=='resetxml')
      command = "slprivate('slsfviewmark', '" + modelname + "', 'resetxml') "
   else if (field=='drag_drop_update')
      command = "slprivate('slsfviewmark', '" + viewMarkerId + "', 'drag_drop_update', '" + newValue +  "', 'global') "
   else if (field=='drag_drop_update_model')
      command = "slprivate('slsfviewmark', '" + viewMarkerId + "', 'drag_drop_update', '" + newValue +  "', 'model') "
   else if (field=='printout')
      command = "disp('" + newValue + "');";

   return command;
}

function jump(anchorId) {
    var model = document.getElementById(anchorId);
    if (model) {
        var titleBar_width = getByClass('titlebar').offsetHeight;
        var controlPanel_width = getByClass('controlpanel').offsetHeight;
        window.scrollTo(0, model.offsetTop - titleBar_width - controlPanel_width);
    }else{
        pageLoaded = true;
    }
}

function jump_model_space(anchorId) {
    var cm = getByClass('currentmdl_viewmark');

    var allModels = getAllByClass('viewmarkerframe_mdlname_model', cm);

    var theModel = null;
    for (i=0; i<allModels.length; i++) {
        if (allModels[i].id == anchorId) {
            theModel = allModels[i];
            break;
        }
    }
	
    if (theModel) {
        var titleBar_width = getByClass('titlebar').offsetHeight;
        var controlPanel_width = getByClass('controlpanel').offsetHeight;
        window.scrollTo(0, theModel.offsetTop - titleBar_width - controlPanel_width);
    }
}

function getByClass(className, target) {
    return getAllByClass(className, target)[0];
}

function getAllByClass(className, target) {
    target = target || document;
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
       div.className = div.className.replace(findClassRegex, " ");
       div.className = div.className.trim();
    }
}

function activate(ev) {
    removeClass(ev.target, "inactive");
    addClass(ev.target, "active");
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
function updateName(ev) {
    var newName = ev.target.value;  // it's tempting to call .trim(), but .trim() doesn't always handle i18n well
    if (lastNewName === newName) {
        return;
    }
    lastNewName = newName;

    var viewMarkerFrame = ev.target.parentElement.parentElement;
    var viewMarkerId    = getViewMarkerId(viewMarkerFrame);
    
    if (globalview) {
        if (updateViewMarker(viewMarkerId, encodeSingleQuote(newName), "name")) {
            ev.target.title = newName;
        } else {
            ev.target.title = "UPDATE ERROR";
        }
    }else{
        if (updateViewMarker(viewMarkerId, encodeSingleQuote(newName), "name_model")) {
            ev.target.title = newName;
        } else {
            ev.target.title = "UPDATE ERROR";
        }
    }
}

function showEditor(ev) {
    addClass(document.body, "lockControls");
    
    var viewMarkerFrame = ev.target.parentElement;
    var glass           = getByClass("glass", viewMarkerFrame);
    var editPane        = getByClass("editPane", viewMarkerFrame);
    var textArea        = editPane.getElementsByTagName("textarea")[0];
    
    textArea.value = decodeNewlines(decodeSingleQuote(glass.dataset.tooltip));
    editPane.style.display = "block";
    
    textArea.focus();
}

function hideEditor(ev) {
    removeClass(document.body, "lockControls");
    var editPane = ev.target.parentElement;
    editPane.style.display = "none";
}

function hideDialog(ev) {
    removeClass(document.body, "lockControls");
    var editPane = ev.target.parentElement.parentElement;
    editPane.style.display = "none";
}

function deleteViewMark(ev) {
    var viewMarkerFrame = ev.target.parentElement;
    var viewMarkerId = getViewMarkerId(viewMarkerFrame);
    var checkbox = getByClass("selectCheckbox", viewMarkerFrame);
    var checked = false;

    if (checkbox.checked) {
        checked = true;
    }
    
    updateViewMarker(viewMarkerId, " ", "delete");

    var outer = viewMarkerFrame.parentElement;
    var groupId = outer.previousElementSibling.id;  // get the id of modle name div
    var remainingChildren = outer.getElementsByClassName('viewmarkerframe');

    updateGroupIndex(groupId);
    lenSvg--;

    var SLIDE_OUT_STEP = 100;  // pixels
    slideOut(viewMarkerFrame, SLIDE_OUT_STEP, function(div) {
      div.parentElement.removeChild(div);
      responsivelyLoadSVGs();
    });

    removeModelNameIfNeeded = window.setTimeout(function() {
        var modelname = outer.previousElementSibling;
        if (remainingChildren.length==0) {
            modelname.parentElement.removeChild(modelname);
            deleteGroupState(groupId);
        }	
    }, 500);

    if (checked) {
        totalChecked--;
        totalChecked_global--;

        var multiSelDeleteButton = getByClass("multiSelDeleteButton");
        var copyVMButton = getByClass("copyVMButton");

        if (totalChecked==0) {
            multiSelDeleteButton.style.display = "none";
            copyVMButton.style.display = "none";
        }
    }
}

function deleteViewMark_model(ev) {
    var viewMarkerFrame = ev.target.parentElement;
    var viewMarkerId = getViewMarkerId(viewMarkerFrame);
    var checkbox = getByClass("selectCheckbox", viewMarkerFrame);
    var checked = false;

    if (checkbox.checked) {
        checked = true;
    }
        
    updateViewMarker(viewMarkerId, " ", "delete_model");

    var SLIDE_OUT_STEP = 100;  // pixels
    slideOut(viewMarkerFrame, SLIDE_OUT_STEP, function(div) {
      div.parentElement.removeChild(div);
    });
    
    var outer = viewMarkerFrame.parentElement;
    var remainingChildren = outer.getElementsByClassName('viewmarkerframe');

    removeModelNameIfNeeded = window.setTimeout(function() {
        var outers_model = getAllByClass('viewmarkerframe_outer_model');

    	for (i=0; i<outers_model.length; i++) {
            var outer_model = outers_model[i];
            var modelname = outer_model.previousElementSibling;
            var remainingChildren = outer_model.getElementsByClassName('viewmarkerframe');
            if (modelname.className.indexOf('viewmarkerframe_mdlname_model') >= 0 && remainingChildren.length==0) {
                modelname.parentElement.removeChild(modelname);
                var mdl_vm_cat = getByClass('currentmdl_viewmark');
                var mdl_vm_outer = getAllByClass('viewmarkerframe_outer_model', mdl_vm_cat)[0];
                if (mdl_vm_outer) {
                    mdl_vm_cat.removeChild(mdl_vm_outer);
                }
            }	
    	}
    }, 750);

    lenSvgModel--;

    if (checked) {
        totalChecked--;
        totalChecked_model--;

        var multiSelDeleteButton = getByClass("multiSelDeleteButton");

        if (totalChecked==0) {
            multiSelDeleteButton.style.display = "none";
        }
    }
}

function multiSelDeleteButtonCallback(ev) {
    var checkboxes = getAllByClass("selectCheckbox");
    var len = checkboxes.length;
    for (i=len-1; i>=0; i--) {
        var checkbox = checkboxes[i];
        if (checkbox.checked) {
            var viewMarkerFrame = checkbox.parentElement;
            var viewMarkerId = getViewMarkerId(viewMarkerFrame);

            totalChecked--;

            if (viewMarkerFrame.parentElement.parentElement.className == 'global_viewmarks') {
                updateViewMarker(viewMarkerId, " ", "delete");
                var groupId = viewMarkerFrame.parentElement.previousElementSibling.id;
                updateGroupIndex(groupId);
                lenSvg--;
                totalChecked_global--;
            }else{
                updateViewMarker(viewMarkerId, " ", "delete_model");
                totalChecked_model--;
                lenSvgModel--;
            }
			
            var SLIDE_OUT_STEP = 100;  // pixels
            slideOut(viewMarkerFrame, SLIDE_OUT_STEP, function(div) {
              div.parentElement.removeChild(div);
              responsivelyLoadSVGs();
            });
            len--;
        }
    }
 
    var multiSelDeleteButton = getByClass("multiSelDeleteButton");
    var copyVMButton = getByClass("copyVMButton");
    multiSelDeleteButton.style.display = "none";
    copyVMButton.style.display = "none";

    removeModelNameIfNeeded = window.setTimeout(function() {
        var outers = getAllByClass('viewmarkerframe_outer');
        var outers_model = getAllByClass('viewmarkerframe_outer_model');

        for (i=0; i<outers.length; i++) {
             var outer = outers[i];
             var modelname = outer.previousElementSibling;
             var remainingChildren = outer.getElementsByClassName('viewmarkerframe');
             if (modelname.className == 'viewmarkerframe_mdlname' && remainingChildren.length==0) {
                 modelname.parentElement.removeChild(modelname);
                 deleteGroupState(modelname.id);
                 responsivelyLoadSVGs();
             }	
        }

    	for (i=0; i<outers_model.length; i++) {
            var outer_model = outers_model[i];
            var modelname = outer_model.previousElementSibling;
            var remainingChildren = outer_model.getElementsByClassName('viewmarkerframe');
            if (modelname.className.indexOf('viewmarkerframe_mdlname_model') >= 0 && remainingChildren.length==0) {
                modelname.parentElement.removeChild(modelname);
                var mdl_vm_cat = getByClass('currentmdl_viewmark');
                var mdl_vm_outer = getAllByClass('viewmarkerframe_outer_model', mdl_vm_cat)[0];
                if (mdl_vm_outer) {
                    mdl_vm_cat.removeChild(mdl_vm_outer);
                }
            }	
    	}
    }, 500);

}

function showDeleteGroupConfirmation(ev) {
    addClass(document.body, "lockControls");

    var viewMarkerFrame        = ev.target.parentElement.parentElement.parentElement;
    var deleteGroupConfirmationPane = getByClass("deleteGroupConfirmationPane", viewMarkerFrame);   
    groupForDelete = ev.target.parentElement.getAttribute('id');
    
    var tgt = ev.target;
    var dlgText = getByClass('deleteGroupConfirmationPaneContent', deleteGroupConfirmationPane);

    if (tgt.className == 'deletegroup') {
        dlgText.innerText = deleteGrpConfirmationMsg;
    }else if (tgt.className == 'multiSelDeleteButton') {
        dlgText.innerText = deleteMultiSelConfirmationMsg;
    }

    deleteGroupConfirmationPane.style.display = "block";    
    ev.cancelBubble = true;
}

function deleteGroupViewMark(ev) { // clean up var declaration
    var i;
    var nextElement;
    var frames;
    var framesLen;
		
    var dlgText = getByClass('deleteGroupConfirmationPaneContent', ev.target.parentElement.parentElement);
    if (dlgText.innerText == deleteMultiSelConfirmationMsg) {
        hideDialog(ev);
        multiSelDeleteButtonCallback(ev);
        return;
    }

    if (!globalview) {
        deleteGroupViewMark_model(ev);
        return;
    }

    var deletedGroupIndex;

	for (i=0; i<groups.length; i++) {
        group = groups[i];
        if (groups[i].getAttribute('id') != groupForDelete) {
            continue;
        }
        deletedGroupIndex = i;
        // groupStates[i].expanded = false;
        nextElement = groups[i].nextElementSibling;
        frames = nextElement.getElementsByClassName('viewmarkerframe');
        framesLen = frames.length;
        // collapsedViewmarks = collapsedViewmarks + framesLen;

        updateViewMarker(groupForDelete, " ", "deletegroup");
        
        var groupToRemove = group.nextElementSibling;
        var checkboxes = getAllByClass("selectCheckBox", groupToRemove);
        for (j=0; j<checkboxes.length; j++) {
            if (checkboxes[j].checked) {
                totalChecked--;
                totalChecked_global--;
            }
        }

        var SLIDE_OUT_STEP = 100;  // pixels
        slideOut(groupToRemove, SLIDE_OUT_STEP, function(div) {
            div.parentElement.removeChild(div);
            responsivelyLoadSVGs();
        });

        break;
    }

    var multiSelDeleteButton = getByClass("multiSelDeleteButton");
    var copyVMButton = getByClass("copyVMButton");

    if (totalChecked==0) {
        multiSelDeleteButton.style.display = "none";
        copyVMButton.style.display = "none";
    }

    hideDialog(ev);

    // loadSvgAfterCollapsing(group);

    parentOfMdlName = group.parentElement;
    parentOfMdlName.removeChild(group);
    for (var j=groupStates[i].beginIndx; j<=groupStates[i].endIndx; j++) {
        // svgs.splice(j, 1);
    }

    // update the groupStates index
    for (var k = deletedGroupIndex + 1; k < groupStates.length; k++ ) {
        groupStates[k].beginIndx -= framesLen;
        groupStates[k].endIndx -= framesLen;
    }

    groupStates.splice(i, 1);
    // collapsedViewmarks = collapsedViewmarks - framesLen;
    pageHeight = document.documentElement.offsetHeight;
    updateViewMarker("", " ", "resetxml");
    document.body.className = "";
}

function deleteGroupViewMark_model(ev) {
    var groups = document.getElementsByClassName('viewmarkerframe_mdlname_model');    
    var group = [];
    var i;
    var nextElement;
    var frames;
    var framesLen;

    for (i=0; i<groups.length; i++) {
        group = groups[i];
        if (groups[i].getAttribute('id') != groupForDelete) {
            continue;
        }

        nextElement = groups[i].nextElementSibling;
        frames = nextElement.getElementsByClassName('viewmarkerframe');
        framesLen = frames.length;
        collapsedViewmarks = collapsedViewmarks + framesLen;

        updateViewMarker(groupForDelete, " ", "deletegroup_model");

        var groupToRemove = group.nextElementSibling;
        var checkboxes = getAllByClass("selectCheckBox", groupToRemove);
        for (j=0; j<checkboxes.length; j++) {
            if (checkboxes[j].checked) {
                totalChecked--;
                totalChecked_model--;
            }
        }

        var SLIDE_OUT_STEP = 100;  // pixels
        slideOut(groupToRemove, SLIDE_OUT_STEP, function(div) {
            div.parentElement.removeChild(div);
        });

        window.setTimeout(function() {
        }, 1000);

        break;
    }

    var multiSelDeleteButton = getByClass("multiSelDeleteButton");

    if (totalChecked==0) {
        multiSelDeleteButton.style.display = "none";
    }

    hideDialog(ev);

    // loadSvgAfterCollapsing(group);

    parentOfMdlName = group.parentElement;
    parentOfMdlName.removeChild(group);
}

function stopDeleteGroupViewMark(ev) {
    hideDialog(ev);
    document.body.className = "";
}

function OKButtonForUnavailableCallback(ev) {
    hideDialog(ev);
    
    updateViewMarker(idForDelete, " ", "delete");

    var SLIDE_OUT_STEP = 100;  // pixels
    var parentViewMarker = document.getElementById(idForDelete);
    slideOut(parentViewMarker, SLIDE_OUT_STEP, function(div) {
      div.parentElement.removeChild(div);
    });

    idForDelete = 0;    

    var outer = parentViewMarker.parentElement;
    var remainingChildren = outer.getElementsByClassName('viewmarkerframe');

    removeModelNameIfNeeded = window.setTimeout(function() {
        var modelname = outer.previousElementSibling;
        if (remainingChildren.length==0) {
            modelname.parentElement.removeChild(modelname);
        }	
    }, 500);
}

function CancelButtonForUnavailableCallback(ev) {
    hideDialog(ev);
}

function OKButtonForWarningDescLenCallback(ev) {
    hideDialog(ev);
}

function GlobalViewmarkButtonCallback(ev) {

    // update the hidden viewmark width before hide the viewmarks
    updateHiddenViewmarkWidth();

    var global = getByClass("global_viewmarks");   /* smaller scope search */
    var model = getByClass("currentmdl_viewmark");   /* smaller scope search */

    windowYOffsetModel = window.pageYOffset;

    global.style.display = 'block';
    model.style.display = 'none';

    window.scrollTo(0, windowYOffset);

    var global_button = document.getElementById('globalVMButton');
    var model_button = document.getElementById('modelVMButton');
	if (manageMode) {
		global_button.style.backgroundColor = '#444444';
	}else{
		global_button.style.backgroundColor = '#6E6E6E';
	}
    global_button.style.cursor = 'default';
    global_button.style.fontWeight = '900';
    model_button.style.backgroundColor = '#4A4A4A';
    model_button.style.cursor = 'pointer';
    model_button.style.fontWeight = 'normal';
	model_button.style.borderLeft = '1px solid #7B7B7B';
	model_button.style.borderTop = '1px solid #7B7B7B';
	model_button.style.borderBottom = '1px solid #7B7B7B';
    global_button.disabled=true;
    model_button.disabled=false;

    var copy_button = getByClass('copyVMButton');
    var delete_button = getByClass('multiSelDeleteButton');

	if (totalChecked > 0 && totalChecked_global>0) {
		copy_button.style.display = 'inline-block';
		delete_button.style.display = 'inline-block';
	} else {
		copy_button.style.display = 'none';
		delete_button.style.display = 'none';
	}

    globalview = 1;
	global_button.style.border = 'none';
}

function ModelViewmarkButtonCallback(ev) {

    // update the hidden viewmark width before hide the viewmarks
    updateHiddenViewmarkWidth();

    var global = getByClass("global_viewmarks");   /* smaller scope search */
    var model = getByClass("currentmdl_viewmark");   /* smaller scope search */

    windowYOffset = window.pageYOffset;

    global.style.display = 'none';
    model.style.display = 'block';

    var global_button = document.getElementById('globalVMButton');
    var model_button = document.getElementById('modelVMButton');
	if (manageMode) {
		model_button.style.backgroundColor = '#444444';
    }else{
		model_button.style.backgroundColor = '#6E6E6E';
	}
    model_button.style.cursor = 'default';
    model_button.style.fontWeight = '900';
	model_button.style.border = 'none';
    global_button.style.backgroundColor = '#4A4A4A';
    global_button.style.cursor = 'pointer';
    global_button.style.cursor = 'default';
    global_button.style.fontWeight = 'normal';
    global_button.disabled=false;
    model_button.disabled=true;

	if (lenSvgModel != 0) {
        handleLayout();  // could optimize further
	}

    window.scrollTo(0, windowYOffsetModel);

    for (i=lenSvg; i<lenSvg + lenSvgModel; i++) {
        loadSvgSingle(i);
    }

    globalview = 0;
	
    if (manageMode) {
        global_button.style.borderRight = '1px solid #7B7B7B';
        global_button.style.borderBottom = '1px solid #7B7B7B';		
        global_button.style.borderTop = 'none';
        global_button.style.borderLeft = 'none';
    }

    var copy_button = getByClass('copyVMButton');
	copy_button.style.display = 'none';

    var delete_button = getByClass('multiSelDeleteButton');
    if (totalChecked > 0 && totalChecked_model > 0) {
        delete_button.style.display = 'inline-block';
    } else {
        delete_button.style.display = 'none';
    }
}

// draw image in case with image and canvas parameters to be called in loop
function drawImageInCanvas(canvasObj,imgObj) {
    var cxt = canvasObj.getContext("2d");
    cxt.drawImage(imgObj, 0, 0, canvasObj.width, canvasObj.height);
}

function CopyViewmarkButtonCallback(ev) {
    if(!globalview) {
        return;
    }
    
    var checkboxes = getAllByClass("selectCheckbox");
    for (i=checkboxes.length-1; i>=0; i--) {
        var checkbox = checkboxes[i];
        if (checkbox.checked) {
            var categoryDiv = checkbox.parentElement.parentElement.parentElement;

            if (categoryDiv.className.indexOf('currentmdl_viewmark')>=0) {
                continue;
            }

            lenSvgModel++;
            var viewMarkerFrame = checkbox.parentElement;
            var viewMarkerId = getViewMarkerId(viewMarkerFrame);

            var prev = viewMarkerFrame.parentElement.previousElementSibling;
            var mdlName = getByClass('viewmarkerframe_mdlname_text', prev);
            updateViewMarker(viewMarkerId, mdlName.innerText, "copy");

            watermark_value++;
            newId = watermark_value;
            var newNode = viewMarkerFrame.cloneNode(true);
            newNode.id = newId;

            var vid = getByClass("viewMarkerId", newNode);
            vid.value = newId;

            var checkbox = getByClass("selectCheckbox", newNode);
            checkbox.checked = false;
            newNode.style.border = "1px solid #7ab7ff";
            newNode.style.boxShadow = "0 0 10px 4px #55a1ff";

            var mdl_vm_cat = getByClass('currentmdl_viewmark');
            var mdl_vm_outer = getAllByClass('viewmarkerframe_outer_model', mdl_vm_cat);
            var mdl_vm_outer_name = getAllByClass('viewmarkerframe_mdlname_model', mdl_vm_cat);

			var groupExisted = false;
            for (j = 0; j < mdl_vm_outer.length; j++) {
                var this_outer_name = mdl_vm_outer_name[j];
                var this_outer = mdl_vm_outer[j];

                if (this_outer_name.id == viewMarkerFrame.parentElement.previousElementSibling.id) {
               		groupExisted = true;
                    var children_count = this_outer.childElementCount;
                    firstchild = this_outer.firstChild;

                    if (children_count === 0) {
                        this_outer.appendChild(newNode);
                    }else{
                        this_outer.insertBefore(newNode, this_outer.children[0]);
                    }
		    
		            // update the DragObj attribute of the newNode so that it can be dragable in the new set
                    var dragObjId = this_outer.getAttribute('DropObj');
                    newNode.setAttribute('DragObj', dragObjId);
		    		    
                    var editButton_model = getByClass("editButton", newNode);
                    removeClass(editButton_model, "editButton");
                    removeClass(editButton_model, "editButtonMoveOver");
                    addClass(editButton_model, "editButton_model");
                    addClass(editButton_model, "editButtonMoveOver_model");
                    editButton_model.addEventListener("click", showEditor);

                    var deleteButton_model = getByClass("deleteButton", newNode);
                    removeClass(editButton_model, "deleteButton");
                    addClass(editButton_model, "deleteButton_model");
                    deleteButton_model.addEventListener("click", deleteViewMark_model);

                    var closeButton = getByClass("closeButton", newNode);
                    closeButton.addEventListener("click", hideEditor);

                    var canvas = getByClass('canvas_image', newNode);
                    var iframe = canvas.parentNode.querySelector("iframe");
                    var img = canvas.parentNode.querySelector("img");

                    var imgframe = getByClass('imgframe', newNode);
                    imgframe.addEventListener("click", imageClicked);

                    var thecheckbox = getByClass("selectCheckbox", newNode);
                    thecheckbox.addEventListener("click", checkboxClickCallback);

                    var label = getByClass('nameLabel', newNode);
                    label.addEventListener("click", activate);
                    label.addEventListener("blur", deactivate);
                    label.addEventListener("keyup", updateName);
                    label.addEventListener("change", updateName);
                    label.title = label.value;
                    label.addEventListener("dragstart", stopEvent);

                    var textAreas = newNode.getElementsByTagName("textarea");
                    textAreas[0].addEventListener("dragstart", stopEvent);
                    textAreas[0].addEventListener("paste", textAreaOnPasteCallback);
                    textAreas[0].addEventListener("keyup", saveViewMarkerAnnotation);
                    textAreas[0].addEventListener("change", saveViewMarkerAnnotation);

                    img.onload = function() {
                        drawImageInCanvas(this.canvasObj,this);
                    };
                    img.canvasObj = canvas;

                    totalChecked--;
                    totalChecked_global--;
                    break;
                }
            }

            if (!groupExisted) {
                var outer = viewMarkerFrame.parentElement;
                var outer_name = outer.previousElementSibling;
                var new_outer = outer.cloneNode();
                removeClass(new_outer, 'viewmarkerframe_outer');
                addClass(new_outer,    'viewmarkerframe_outer_model');
                var new_outer_name = outer_name.cloneNode(true);
                removeClass(new_outer_name, 'viewmarkerframe_mdlname');
                addClass(new_outer_name,    'viewmarkerframe_mdlname_model');

                mdl_vm_cat.insertBefore(new_outer, mdl_vm_outer_name[0]);
                mdl_vm_cat.insertBefore(new_outer_name, new_outer);
                new_outer.appendChild(newNode);
		
                // update the DragObj attribute for the new outer and new node
                var cDrag = DragDrops.length;
                DragDrops[cDrag] = [];
                DragDrops[cDrag].push(new_outer);
                new_outer.setAttribute('DropObj', cDrag);
                newNode.setAttribute('DragObj', cDrag);
		
                var modelName = getByClass("modelGroupIcon", new_outer_name);
                modelName.addEventListener("click", toggleViewMarkerOuterFrame);

                var deletegroup = getByClass("deletegroup", new_outer_name);
                deletegroup.addEventListener("click", showDeleteGroupConfirmation);

                var modelNameText = getByClass("viewmarkerframe_mdlname_text", new_outer_name);
                modelNameText.addEventListener("dblclick", toggleViewMarkerOuterFrame);

                var editButton_model = getByClass("editButton", newNode);
                removeClass(editButton_model, "editButton");
                removeClass(editButton_model, "editButtonMoveOver");
                addClass(editButton_model, "editButton_model");
                addClass(editButton_model, "editButtonMoveOver_model");
                editButton_model.addEventListener("click", showEditor);

                var deleteButton_model = getByClass("deleteButton", newNode);
                removeClass(editButton_model, "deleteButton");
                addClass(editButton_model, "deleteButton_model");
                deleteButton_model.addEventListener("click", deleteViewMark_model);

                var closeButton = getByClass("closeButton", newNode);
                closeButton.addEventListener("click", hideEditor);

                var canvas = getByClass('canvas_image', newNode);
                var iframe = canvas.parentNode.querySelector("iframe");
                var img = canvas.parentNode.querySelector("img");

                var imgframe = getByClass('imgframe', newNode);
                imgframe.addEventListener("click", imageClicked);

                var thecheckbox = getByClass("selectCheckbox", newNode);
                thecheckbox.addEventListener("click", checkboxClickCallback);
				
                var label = getByClass('nameLabel', newNode);
                label.addEventListener("click", activate);
                label.addEventListener("blur", deactivate);
                label.addEventListener("keyup", updateName);
                label.addEventListener("change", updateName);
                label.title = label.value;
                label.addEventListener("dragstart", stopEvent);

                var textAreas = newNode.getElementsByTagName("textarea");
                textAreas[0].addEventListener("dragstart", stopEvent);
                textAreas[0].addEventListener("paste", textAreaOnPasteCallback);
                textAreas[0].addEventListener("keyup", saveViewMarkerAnnotation);
                textAreas[0].addEventListener("change", saveViewMarkerAnnotation);

                img.onload = function() {
                    drawImageInCanvas(this.canvasObj,this);
                };
                img.canvasObj = canvas;
		
                totalChecked--;
                totalChecked_global--;
            }

            var introModel = getByClass('intro_model');
            if (introModel) {
                introModel.style.display = 'none';
            }

            var frame = checkboxes[i].parentElement;
            frame.style.border = "1px solid #2B1B17";
            frame.style.boxShadow = "2px 2px 2px #666362";

            var checkbox = getByClass("selectCheckbox", frame);
            checkbox.checked = false;
        }
    }

    var multiSelDeleteButton = getByClass("multiSelDeleteButton");
    var copyVMButton = getByClass("copyVMButton");
    multiSelDeleteButton.style.display = "none";
    copyVMButton.style.display = "none";

    ModelViewmarkButtonCallback();
    jump_model_space(mdlName.innerText);
}

function manageModeButtonCallback(ev) {
    var manageModeButton = document.getElementById('manageModeButton');
    var checkboxes = getAllByClass("selectCheckbox");
    var multiSelDeleteButton = getByClass("multiSelDeleteButton");
    var copyVMButton = getByClass("copyVMButton");
    var outermost = getByClass('outermost');
    var global_button = document.getElementById('globalVMButton');
    var model_button = document.getElementById('modelVMButton');
    var controlpanel_left = document.getElementsByClassName('controlpanel_left')[0];

    if (manageModeButton.innerText == manageButtonText) {
        manageMode = 1;
        if (totalChecked>0) {
            multiSelDeleteButton.style.display = "inline-block";
            if (globalview) {
                copyVMButton.style.display = "inline-block";
            }
        }

        manageModeButton.innerText = manageButton2Text;
        for (var i = 0; i < checkboxes.length; ++i) {
            checkboxes[i].style.display = 'block';
        }
	    outermost.style.background = 'rgba(48,48,48,0.90)';

		if (globalview) {
			global_button.style.backgroundColor = '#444444';
		}else{
			model_button.style.backgroundColor = '#444444';
			if (manageMode) {
				global_button.style.borderRight = '1px solid #7B7B7B';
				global_button.style.borderBottom = '1px solid #7B7B7B';		
				global_button.style.borderTop = 'none';
				global_button.style.borderLeft = 'none';
			}
		}
		controlpanel_left.style.backgroundColor = '#444444';
    }else{
        manageMode = 0;
        totalChecked = 0;
        totalChecked_global = 0;
        totalChecked_model = 0;		
        multiSelDeleteButton.style.display = "none";
        copyVMButton.style.display = "none";

        manageModeButton.innerText = manageButtonText;
        for (var i = 0; i < checkboxes.length; ++i) {
            checkboxes[i].style.display = 'none';
            checkboxes[i].checked = false;
            var frame = checkboxes[i].parentElement;
            // frame.style.border = "1px solid #2B1B17";
            // frame.style.boxShadow = "2px 2px 2px #666362";
            frame.style.border = "";
            frame.style.boxShadow = "";
            if(!hasClass(frame,'unHighlightViewmark')) {
                addClass(frame,'unHighlightViewmark');
            }
        }
	    outermost.style.background = 'rgba(48,48,48,0.70)';
		
		if (globalview) {
			global_button.style.backgroundColor = '#6E6E6E	';
		}else{
			model_button.style.backgroundColor = '#6E6E6E';
		}
		controlpanel_left.style.backgroundColor = '#6E6E6E';		
    }    
}

function checkboxClickCallback(ev) {
    var checkbox = ev.target;
    var frame = checkbox.parentElement;
    var toCheck;
    alterCheckBoxStates(checkbox, frame, checkbox.checked);
}

function alterCheckBoxStates(checkbox, frame, toCheck) {
    var multiSelDeleteButton = getByClass("multiSelDeleteButton");
    var copyVMButton = getByClass("copyVMButton");
    var global_clicked = true;
    if (frame.parentElement.className.indexOf('viewmarkerframe_outer_model')>=0) {
        global_clicked = false;
    }

    if (toCheck) {
        totalChecked++;

        if (global_clicked) {
            totalChecked_global++;
        }else{
            totalChecked_model++;
        }

        multiSelDeleteButton.style.display = "inline-block";
        if (globalview) {
            copyVMButton.style.display = "inline-block";
        }
        frame.style.border = "1px solid #7ab7ff";
        frame.style.boxShadow = "0 0 10px 4px #55a1ff";
    }else{
        totalChecked--;

        if (global_clicked) {
            totalChecked_global--;
        }else{
            totalChecked_model--;
        }

        if (totalChecked==0) {
            multiSelDeleteButton.style.display = "none";
        }
		
        if (totalChecked_global==0) {
            copyVMButton.style.display = "none";
        }
        frame.style.border = "";
        frame.style.boxShadow = "";
    }
}

function showDeleteViewMark(ev) {
    document.body.className = "lockControls";

    var viewMarkerFrame        = ev.target.parentElement;
    var glass                  = getByClass("glass", viewMarkerFrame);
    var deleteConfirmationPane = getByClass("deleteConfirmationPane", viewMarkerFrame);

    deleteConfirmationPane.style.display = "block";    
}

function hideDeleteViewMark(ev) {
    document.body.className = "lockControls";

    var viewMarkerFrame        = ev.target.parentElement;
    var glass                  = getByClass("glass", viewMarkerFrame); 
    var deleteConfirmationPane = getByClass("deleteConfirmationPane", viewMarkerFrame);

    deleteConfirmationPane.style.display = "none";    
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

    if (globalview) {
        if (updateViewMarker(viewMarkerId, newlineEncodedNewAnnotation, "annotation")) {
            glass.dataset.tooltip = newAnnotation;
        } else {
            glass.dataset.tooltip = "UPDATE ERROR";
        }
    }else{
        if (updateViewMarker(viewMarkerId, newlineEncodedNewAnnotation, "annotation_model")) {
            glass.dataset.tooltip = newAnnotation;
        } else {
            glass.dataset.tooltip = "UPDATE ERROR";
        }
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

function adjustFrameRatioForScreen() {
    var frames = document.getElementsByClassName("viewmarkerframe");
    var zoomRatio = window.outerWidth / window.innerWidth;
    for (var i = 0; i < frames.length; ++i) {
        frames[i].style.width = parseFloat(RATIO_SET[ratioIndex]) * zoomRatio + '%';
        // frames[i].style.width = RATIO_SET[ratioIndex];
    }

    // adjust the size of all the checkbox
    var checkboxes = document.getElementsByTagName('input');
    for (var i = 0; i < checkboxes.length; i++) {
        if(checkboxes[i].type == 'checkbox') {
            if(zoomRatio > 1) {
                checkboxes[i].style.webkitTransform = 'scale(' + zoomRatio + ')';
                checkboxes[i].style.left = 5*zoomRatio + 'px';
            } else {
                checkboxes[i].style.webkitTransform = 'scale(1)';
                checkboxes[i].style.left = '5px';
            }
        }
    }
}

function handleLayout() {
    adjustFrameRatioForScreen();
    sizeDivsToAspectRatio("viewmarkerframe_inner");
    jump(DEFAULT_ANCHOR_ID);
}

function fadeViewMarkerGlow(div) {
    // Should match viewmarker.css .viewmarkerframe_new !!
    var HIGHLIGHT_OPACITY = 1;
    var HIGHLIGHT_PARAMS = "0 0 10px 4px";
    var HIGHLIGHT_RED    = 85;
    var HIGHLIGHT_GREEN  = 161;
    var HIGHLIGHT_BLUE   = 255;
    var OPACITY_STEP     = -0.1;

    var opacity = HIGHLIGHT_OPACITY;
    var fadeHandle = window.setInterval(function() {
        if (opacity < 0.1) {
            window.clearInterval(fadeHandle);
            removeClass(div, "viewmarkerframe_new");
            div.style.boxShadow = "";
            return;
        }
        opacity += OPACITY_STEP;
        var boxShadow = HIGHLIGHT_PARAMS + " rgba(" + HIGHLIGHT_RED + ", " + HIGHLIGHT_GREEN + ", " + HIGHLIGHT_BLUE + ", " + opacity + ")";
        div.style.boxShadow = boxShadow;
    }, 80);
}

function slideIn(div, stepRight, stepLeft, overShootBy, onComplete) {
    div.style.left = parseInt(window.getComputedStyle(div).left) + "px";

    var step = stepRight;
    var slideHandle = window.setInterval(function() {
        var left = parseInt(div.style.left);
        if (left > overShootBy) {
          step = stepLeft;
        }
        if (left <= 0 && step < 0) {
            window.clearInterval(slideHandle);
            onComplete(div);
            return;
        }
  
        left += step;
        div.style.left = left + "px";
    }, 30);
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

function showNewViewMarker() {
    var newViewMarker = getByClass("viewmarkerframe_new");
    if (!newViewMarker) {
        return;
    }
    newViewMarker.style.position = "relative"
    
    // Animation parameters.    
    var STEP_RIGHT   = 40;  // pixels
    var STEP_LEFT    = -20; // pixels
    var OVERSHOOT_BY = 50;  // pixels
    slideIn(newViewMarker, STEP_RIGHT, STEP_LEFT, OVERSHOOT_BY, fadeViewMarkerGlow);
}

function loadSvgAfterCollapsing(modelName) {
    var groupIdx = -1;
    for (i=0; i<groupStates.length; i++) {
        var groupState = groupStates[i];
        if (groupState.id == modelName.id) {
            groupIdx = i;
            groupState.expanded = !groupState.expanded;
            break;
        }
    }

    if (groupIdx<0) {
        return;
    }

    var sumNonHiddenAfter =0;
    var sumAfter = 0;

    for (var i=groupIdx+1; i<groups.length; i++) {
        var nextElement = groups[i].nextElementSibling;
        var viewmarks = nextElement.getElementsByClassName('viewmarkerframe');
        sumAfter += viewmarks.length;
        
        if (!hasClass(nextElement, 'hidden')) {
            sumNonHiddenAfter += viewmarks.length;
        }
    }

    if (sumNonHiddenAfter < viewmarksPerViewport) {
        // the collapsed group will sink
        var beginIdxInViewport = viewmarksPerViewport - sumNonHiddenAfter
        var before = beginIdxInViewport + numberPerRow;
        var after = sumNonHiddenAfter;            

        var sumBefore = 0;
        var toBreak = false;
        for (var j=groupIdx; j>=0; j--) {
          var groupState = groupStates[j];
          if (groupState.expanded) {
            for (var k=groupState.endIndx; k>groupState.beginIndx; k--) {
                loadSvgSingle(k);
                sumBefore += 1;
                if (sumBefore == before) {
                    toBreak = true;
                    break;
                }
            }
            
            if (toBreak) {
                toBreak = false;
                break;
            }
          }
        }

        var sumAfter = 0;
        for (var j=groupIdx; j<groupStates.length; j++) {
          var groupState = groupStates[j];
          if (groupState.expanded) {
            for(var k=groupState.beginIndx; k<=groupState.endIndx; k++) {
                loadSvgSingle(k);
                sumAfter += 1;
                if (sumAfter == after) {
                    toBreak = true;
                    break;
                }
            }

            if (toBreak) {
                toBreak = false;
                break;
            }
          }
        }

    } else {
        // will not sink
        var sumAfter = 0;
        var toBreak = false;
        for (var j=groupIdx+1; j<groupStates.length; j++) {
          var groupState = groupStates[j];
          if (groupState.expanded) {
            for (var k=groupState.beginIndx; k<groupState.endIndx; k++) {
                loadSvgSingle(k);
                sumAfter += 1;
                if (sumAfter == viewmarksPerViewport) {
                    toBreak = true;
                    break;
                }
            }

            if (toBreak) {
                toBreak = false;
                break;
            }
          }
        }
    }
}

function toggleViewMarkerOuterFrame(ev) {
    var modelName = ev.target;
    if (!modelName.id) {
        modelName = modelName.parentElement;
    }

    var modelViewMarkersOuterFrame = modelName.nextElementSibling;
    var frames = modelViewMarkersOuterFrame.getElementsByClassName('viewmarkerframe');

    if (hasClass(modelName, "closed")) {       // opening
        removeClass(modelName, "closed");
        removeClass(modelViewMarkersOuterFrame, "hidden");
        addClass(modelName, "open");

        collapsedViewmarks = collapsedViewmarks - frames.length;
        jump(modelName.id);
        updateGroupStates(modelName.id, true);
    } else {                                   // collapsing
        removeClass(modelName, "open");
        addClass(modelViewMarkersOuterFrame, "hidden");
        addClass(modelName, "closed");

        collapsedViewmarks = collapsedViewmarks + frames.length;

        loadSvgAfterCollapsing(modelName);
        updateGroupStates(modelName.id, false);
    }

    pageHeight = document.documentElement.offsetHeight;
}

function handleWindowResize() {
    handleLayout();
    viewportHeight = document.body.clientHeight;
    pageHeight = document.documentElement.offsetHeight;
    document.body.style.backgroundImage = encodeURI("url(file:///" + backgroundFileName + ")");
    rowPerViewPort = Math.floor(viewportHeight/ ((pageWidth-20)/numberPerRow * SVG_ASPECT_RATIO));
    viewmarksPerViewport  = rowPerViewPort * numberPerRow;

    var controlpanel_right = getByClass('controlpanel_right');
    var controlpanel_right_width = getByClass('controlpanel_right').offsetWidth;
    var controlpanel_left_width = getByClass('controlpanel_left').offsetWidth;
    var controlpanel_width = getByClass('controlpanel').offsetWidth;
    var controlpanel_right_minwidth = 160;
    var global_viewmarks = getByClass('global_viewmarks');
    var model_viewmarks = getByClass('currentmdl_viewmark');

    var cb = getByClass('copyVMButton');
	
    var mb = getByClass('multiSelDeletebutton');




    // adjust the width of the right control panel
    if (controlpanel_width - controlpanel_left_width > controlpanel_right_minwidth ) {

        // put the right-control panel in the same line with the left control panel
        // set the 'margin-top' property of the viewmarks container container to be 0
        global_viewmarks.style.marginTop = '0px';
        model_viewmarks.style.marginTop = '0px';

        // set the width of the right panel
        // 260 is the width of the left control panel
        controlpanel_right_width = controlpanel_width - 260;
        controlpanel_right.style.width = controlpanel_right_width + 'px';
        var centerToRightpanel = window.innerWidth/2 - controlpanel_right_width;
        if (centerToRightpanel < 0) {
            cb.style.left = -centerToRightpanel + 5 + 'px';
            mb.style.left = -centerToRightpanel + 5 + 'px';
        } else {
            cb.style.left = '5px';
            mb.style.left = '5px';
        }
    } else {
        // put the right-control panel in another line
        // set the 'margin-top' property of the viewmark container container to be 35px
        // it is the width of the new line
        global_viewmarks.style.marginTop = '35px';
        model_viewmarks.style.marginTop = '35px';

        // set the width of the right panel to be 100%
        controlpanel_right_width = controlpanel_width;
        controlpanel_right.style.width = controlpanel_width + 'px';
        cb.style.left = controlpanel_width/2 - 50 + 'px';
        mb.style.left = controlpanel_width/2 - 50 + 'px';
    }

    // reset the scroll position because the width of the control panel may be changed
    jump(DEFAULT_ANCHOR_ID);
}

function setGroupStates() {
    groups = document.getElementsByClassName('viewmarkerframe_mdlname');
    var beginIndexForGroup = 0;
    var endIndexForGroup = 0;
    var subtotal = 0;
    groupStates = []; 
    
    for (var i=0; i<groups.length; i++) {
        var group = groups[i];
        var viewmarkGrp = group.nextElementSibling;
        var frames = viewmarkGrp.getElementsByClassName('viewmarkerframe');
      
        groupStates.push({
            id: group.getAttribute('id'),
            expanded: true,
            beginIndx: beginIndexForGroup + subtotal,
            endIndx: endIndexForGroup + subtotal - 1 + frames.length
        });
  
        subtotal += frames.length;
    }
}

function updateGroupStates(id, newState) {
    for (var i=0; i<groupStates.length; i++) {
        var groupState = groupStates[i];
        if (groupState.id == id) { 
           groupState.expanded = newState;
        }
    }
}

function updateGroupIndex(id) {
    var needUpdate = false;
    for (var i = 0; i < groupStates.length; i++) {
        var groupState = groupStates[i];
        if (needUpdate) {
            groupState.beginIndx = groupState.beginIndx - 1;
            groupState.endIndx = groupState.endIndx - 1;
        } else {
            if (groupState.id == id) {
                needUpdate = true;
                groupState.endIndx = groupState.endIndx - 1;
            }
        }
    }
}

function deleteGroupState(id) {
    for (var i = 0; i < groupStates.length; i++) {
        var groupState = groupStates[i];
        if (groupState.id == id) {
            groupStates.splice(i,1);
        }
    }
}

var customTooltip;

function addCustomTooltipSupportToElement(element) {
    element.addEventListener("mousemove", function(ev) {
        customTooltip.clearTimeout();

        var self = this;
        var mousePosition = {x: ev.x, y: ev.y};
        customTooltip.timeoutHandle = setTimeout(function(ev) {
            if (self.dataset.tooltip) {
                customTooltip.show(decodeNewlines(decodeSingleQuote(self.dataset.tooltip)), mousePosition.x, mousePosition.y + window.pageYOffset);
            }
        }, customTooltip.delay);
    });
    element.addEventListener("mouseout", function(ev) {
        customTooltip.hide();
        customTooltip.clearTimeout();
    });
    element.addEventListener("mouseleave", function(ev) {
        customTooltip.hide();
        customTooltip.clearTimeout();
    });
    element.setTooltip = function(text) {
        this.dataset.tooltip = text;
    }
}

function initCustomTooltips() {
    var CUSTOM_TOOLTIP_DELAY_MS = 450;

    // Initialize the custom tooltip.
    customTooltip = document.createElement("div");
    customTooltip.className = "customTooltip";
    customTooltip.delay = CUSTOM_TOOLTIP_DELAY_MS;
    customTooltip.timeoutHandle = null;
    customTooltip.clearTimeout = function() {
        if (this.timeoutHandle) {
            clearTimeout(this.timeoutHandle);
            this.timeoutHandle = null;
        }
    }
    customTooltip.hide = function() {
        customTooltip.style.visibility = "hidden";
        customTooltip.style.opacity = "0";
    }
    customTooltip.show = function(text, x, y) {
        customTooltip.innerText = elideAnnotation(text)
        customTooltip.style.left = x + "px";
        customTooltip.style.top = y + 20 + "px";
        customTooltip.style.visibility = "visible";
        customTooltip.style.opacity = "1";
    }

    // Automatically associate custom toolips with any elements that have a "data-tooltip" attribute.
    var customTooltipTargets = document.querySelectorAll("[data-tooltip]");
    for (var i = 0; i < customTooltipTargets.length; ++i) {
        addCustomTooltipSupportToElement(customTooltipTargets[i]);
    }

    document.body.appendChild(customTooltip);
}

function elideAnnotation(str) {
    var maxChar = 100;
    var loc = str.indexOf("\n");
    var previousLoc;
    var returnStr = str.substring(0, maxChar);
    var maxNumOfLines = 3
    var numOfLines = 0;

    while (loc != -1 && loc <= maxChar && numOfLines < maxNumOfLines) {
        previousLoc = loc;	
        loc = str.indexOf("\n", loc+1);
        numOfLines++;
    }

    if (loc == -1) {
        if (numOfLines == maxNumOfLines) {
            returnStr = returnStr.substring(0, previousLoc);
            if (str.length > returnStr.length)
                returnStr += "\n...";
        } else {
            returnStr = returnStr.substring(0, maxChar);
            if (str.length > returnStr.length)
                returnStr += "...";
        }
    }else if (loc>=maxChar) {
        returnStr = returnStr.substring(0, maxChar);
        if (loc>maxChar)
            returnStr += "\n...";
        else
            returnStr += " ...";
    }else if (numOfLines == maxNumOfLines){
        returnStr = returnStr.substring(0, previousLoc);	
        returnStr += "\n...";
    }

    return returnStr;
}

function getHiddenViewmarkWidth() {
    return hiddenViewmarkWidth;
}

function updateHiddenViewmarkWidth() {
    var divs = document.getElementsByClassName('viewmarkerframe_inner');
    for (var i = 0; i < divs.length; ++i) {
        var boundingRect = divs[i].getBoundingClientRect();
        if (boundingRect.width > 0) {
            // The divs may not have exactly the same width.
            // Using the width of the first div ensures they end up with uniform height.
            hiddenViewmarkWidth = boundingRect.width;
            break;
        }
    }
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
        label.addEventListener("keyup", updateName);
        label.addEventListener("change", updateName);
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

    var editButtons_model = document.getElementsByClassName("editButton_model");
    for (var i = 0; i < editButtons_model.length; ++i) {
        var editButton_model = editButtons_model[i];
        editButton_model.addEventListener("click", showEditor);
    }
    
    var deleteButtons_model = document.getElementsByClassName("deleteButton_model");
    for (var i = 0; i < deleteButtons_model.length; ++i) {
        var deleteButton_model = deleteButtons_model[i];
        deleteButton_model.addEventListener("click", deleteViewMark_model);
    }

    var closeButtons = document.getElementsByClassName("closeButton");
    for (var i = 0; i < closeButtons.length; ++i) {
        var closeButton = closeButtons[i];
        closeButton.addEventListener("click", hideEditor);
    }
    
    var OKButtonDeleteGroup = getByClass("OKButtonDeleteGroup");
    OKButtonDeleteGroup.addEventListener("click", deleteGroupViewMark);

    var stopDeleteButtonDeleteGroup = getByClass("stopDeleteButtonDeleteGroup");
    stopDeleteButtonDeleteGroup.addEventListener("click", stopDeleteGroupViewMark);

    var OKButtonForUnavailable = getByClass("OKButtonForUnavailable");
    OKButtonForUnavailable.addEventListener("click", OKButtonForUnavailableCallback);    

    var CancelButtonForUnavailable = getByClass("CancelButtonForUnavailable");
    CancelButtonForUnavailable.addEventListener("click", CancelButtonForUnavailableCallback);    

    var OKButtonForWarningDescLen = getByClass("OKButtonForWarningDescLen");
    OKButtonForWarningDescLen.addEventListener("click", OKButtonForWarningDescLenCallback);    

    var GlobalViewmarkButton = getByClass("globalVMButton");
    GlobalViewmarkButton.addEventListener("click", GlobalViewmarkButtonCallback);

    var ModelViewmarkButton = getByClass("modelVMButton");
    ModelViewmarkButton.addEventListener("click", ModelViewmarkButtonCallback);

    var ModelViewmarkButton = getByClass("copyVMButton");
    ModelViewmarkButton.addEventListener("click", CopyViewmarkButtonCallback);

    var MultiSelDeleteButton = getByClass("multiSelDeleteButton");
    MultiSelDeleteButton.addEventListener("click",  showDeleteGroupConfirmation); // multiSelDeleteButtonCallback);

    var manageModeButton = getByClass("manageModeButton");
    manageModeButton.addEventListener("click", manageModeButtonCallback);

    var checkboxes = getAllByClass("selectCheckbox");
    for (var i = 0; i < checkboxes.length; ++i) {
        checkboxes[i].addEventListener("click", checkboxClickCallback);
    }

    var imgframes = document.getElementsByClassName("imgframe");
    for (var i = 0; i < imgframes.length; ++i) {
        imgframes[i].addEventListener("click", imageClicked);
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
        glasses[i].dataset.tooltip = glasses[i].dataset.tooltip;
    }
    
    var modelNames = getAllByClass("modelGroupIcon");
    for (var i = 0; i < modelNames.length; ++i) {
        var modelName = modelNames[i];
        modelName.addEventListener("click", toggleViewMarkerOuterFrame);
    }

    var modelNameTexts = getAllByClass("viewmarkerframe_mdlname_text");
    for (var i = 0; i < modelNameTexts.length; ++i) {
        var modelNameText = modelNameTexts[i];
        modelNameText.addEventListener("dblclick", toggleViewMarkerOuterFrame);
    }

    var deletegroups = getAllByClass("deletegroup");
    for (var i = 0; i < deletegroups.length; ++i) {
        var deletegroup = deletegroups[i];
        deletegroup.addEventListener("click", showDeleteGroupConfirmation);
    }

    // initializations
    canvases = getAllByClass("canvas_image");
    for(var i=0; i<canvases.length; i++) {
        var canvas = canvases[i];
        canvas.imagePath = svgPath[i];
        canvas.imageLoaded = false;
    }

    if (pageWidth > 1800)
        numberPerRow = 6;
    else if (pageWidth > 1500)
        numberPerRow = 5;
    else if (pageWidth > 1200)
        numberPerRow = 4;
    else if (pageWidth > 900)
        numberPerRow = 3;
    else if (pageWidth > 500)
        numberPerRow = 2;
    else
        numberPerRow = 2;
    
    ratioIndex = numberPerRow;
    
    setGroupStates();
    
    window.onresize = handleWindowResize;    
    
    getByClass("outermost").addEventListener("mouseup", mouseUpForCloseUI);
    
    var viewmarkerframe_outers = getAllByClass("viewmarkerframe_outer");
    for (var i=0; i<viewmarkerframe_outers.length; i++) {
    	var viewmarkerframe_outer = viewmarkerframe_outers[i];
    	viewmarkerframe_outer.addEventListener("mouseup", mouseUpForCloseUI);
    }
    
    var viewmarkerframe_outer_models = getAllByClass("viewmarkerframe_outer_model");
    for (var i=0; i<viewmarkerframe_outer_models.length; i++) {
    	var viewmarkerframe_outer_model = viewmarkerframe_outer_models[i];
    	viewmarkerframe_outer_model.addEventListener("mouseup", mouseUpForCloseUI);
    }

    initCustomTooltips();
    
	dragcontainers = document.getElementsByClassName('DragContainer');
	for (var i=0; i<dragcontainers.length; i++) {
		CreateDragContainer(dragcontainers[i]);
	}

	// Create our helper object that will show the item while dragging
	dragHelper = document.createElement('DIV');
	dragHelper.style.cssText = 'position:absolute;display:none;';

	document.body.appendChild(dragHelper);
}
