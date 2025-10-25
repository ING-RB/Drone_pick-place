var mouseOffset = null;
var iMouseDown  = false;
var lMouseState = false;
/*
	iMouseDown represents the current mouse button state: up or down
	
	lMouseState represents the previous mouse button state so that we can
	check for button clicks and button releases:

	if(iMouseDown && !lMouseState) // button just clicked!
	if(!iMouseDown && lMouseState) // button just released!
*/
var dragObject  = null;

var DragDrops   = [];
var curTarget   = null;
var lastTarget  = null;
var dragHelper  = null;
var tempDiv     = null;
var rootParent  = null;
var rootSibling = null;

var renderImg   = true;
var blankCanvas = null;

var mdlname = null;
var dragDropTarget = null;

Number.prototype.NaN0=function(){return isNaN(this)?0:this;}

function CreateDragContainer(){
	/*
	Create a new "Container Instance" so that items from one "Set" can not
	be dragged into items from another "Set"
	*/
	var cDrag = DragDrops.length;
	DragDrops[cDrag] = [];

	/*
	Each item passed to this function should be a "container".  Store each
	of these items in our current container
	*/
	for(var i=0; i<arguments.length; i++){
		var cObj = arguments[i];     // this is each of the outermost containers
		DragDrops[cDrag].push(cObj);
		cObj.setAttribute('DropObj', cDrag);

		/*
		Every top level item in these containers should be draggable.  Do this
		by setting the DragObj attribute on each item and then later checking
		this attribute in the mouseMove function
		*/
		for(var j=0; j<cObj.childNodes.length; j++){
			// browser puts in lots of #text nodes...skip these
			if(cObj.childNodes[j].nodeName=='#text') 
				continue;

			cObj.childNodes[j].setAttribute('DragObj', cDrag);
		}
	} 
}

function getPosition(e){
	var left = 0;
	var top  = 0;
	while (e.offsetParent){
		left += e.offsetLeft + (e.currentStyle?(parseInt(e.currentStyle.borderLeftWidth)).NaN0():0);
		top  += e.offsetTop  + (e.currentStyle?(parseInt(e.currentStyle.borderTopWidth)).NaN0():0);
		e     = e.offsetParent;
	}

	left += e.offsetLeft + (e.currentStyle?(parseInt(e.currentStyle.borderLeftWidth)).NaN0():0);
	top  += e.offsetTop  + (e.currentStyle?(parseInt(e.currentStyle.borderTopWidth)).NaN0():0);

	return {x:left, y:top};
}

function mouseCoords(ev){
	if(ev.pageX || ev.pageY){
		return {x:ev.pageX, y:ev.pageY};
	}
	return {
		x:ev.clientX + document.body.scrollLeft - document.body.clientLeft,
		y:ev.clientY + document.body.scrollTop  - document.body.clientTop
	};
}

function writeHistory(object, message){
/*
	if(!object || !object.parentNode || !object.parentNode.getAttribute) return;
	var historyDiv = object.parentNode.getAttribute('history');
	var hasHistoryDiv = false;
	
	if(historyDiv){
		hasHistoryDiv = true;
		historyDiv = document.getElementById(historyDiv);
	}else{
		hasHistoryDiv = true;
		var outermost = getByClass('outermost', object.parentElement.parentElement);
		historyDiv = getByClass('History', outermost);
	}
	
	if (hasHistoryDiv) {
		historyDiv.appendChild(document.createTextNode(object.id+': '+message));
		historyDiv.appendChild(document.createElement('BR'));
		historyDiv.scrollTop += 50;
	}
*/
}

function getMouseOffset(target, ev){
	ev = ev || window.event;

	var docPos    = getPosition(target);
	var mousePos  = mouseCoords(ev);
	return {x:mousePos.x - docPos.x, y:mousePos.y - docPos.y};
}

function mouseMove(ev){
    if (!manageMode) {
        return;
    }

	var target   = ev.target || ev.srcElement;
	var mousePos = mouseCoords(ev);

	if (target.className == "outermost hideCanvas" ||
		target.className == "outermost_model hideCanvas" ||
		target.className == "viewmarkerframe_mdlname" ||
		target.className == "viewmarkerframe_mdlname_model" ||
		target.className == "global_viewmarks" ||
		target.className == "currentmdl_viewmark" ||
		target.className == "currentmdl_viewmark hidden" ||
		target.className == "viewmarkerframe_mdlname_text" ||
		target.className == "titlebar" ||
		target.className == "titlebartext" ||
		target.className == "deletegroup" ||		
		target.className == "controlpanel" ||
		target.className == "globalVMButton" ||
		target.className == "modelVMButton" ||
		target.className == "copyVMButton" ||
		target.className == "multiSelDeleteButton" ||		
		target.className == "manageModeButton" ||		
		target.className == "viewmarkerframe_outer DragContainer" ||
		target.className == "viewmarkerframe_outer_model DragContainer") {
		return;
	}

	target = getDraggable(target);

	if (target=="") {
		return;
	}

	var realTarget = target;

	// mouseOut event - fires if the item the mouse is on has changed
	if(lastTarget && (target!==lastTarget)){
		if (target.className == 'glass') {
			realTarget = target.parentElement.parentElement.parentElement;
		} else if (target.type == 'image' || 
				   target.className == 'viewmarker_lower_sec' || 
				   target.className == 'viewmarkerframe_inner' || 
				   target.className == 'nameLabel active' ||
				   target.className == 'nameLabel inactive') {
			realTarget = target.parentElement;
		}
		
		if (lastTarget && (realTarget != lastTarget)){
		/*
			realTargetId = getId(realTarget);
			if (realTargetId=='') {
				writeHistory(lastTarget, 'Mouse Out Fired =>' + Math.random() + ', lastTarget = ' + lastTarget.className + '@' + getId(lastTarget) +', target = ' + target.className  + ', realTarget = ' + realTarget.className + '@' + getId(realTarget));
			}else{
				 writeHistory(lastTarget, 'Mouse Out Fired =>' + Math.random() + ', lastTarget = ' + lastTarget.className + '@' + getId(lastTarget) +', target = ' + target.className  + ', realTarget = ' + realTarget.className + '@' + getId(realTarget));
			}
		*/
			// reset the classname for the target element
			var origClass = lastTarget.getAttribute('origClass');
			if(origClass) {
				lastTarget.className = origClass;
			}
		}
	}

	/*
	dragObj is the grouping our item is in (set from the createDragContainer function).
	if the item is not in a grouping we ignore it since it can't be dragged with this
	script.
	*/
	var dragObj = realTarget.getAttribute('DragObj');

	// if the mouse was moved over an element that is draggable
	if(dragObj!=null){
		// mouseOver event - Change the item's class if necessary
		if(realTarget != lastTarget){
			/*if (lastTarget == null)
				writeHistory(realTarget, 'Mouse Over Fired, realTarget is ' + realTarget.className  + '@' + getId(realTarget) + '(lastTarget is null)');
			else
				writeHistory(realTarget, 'Mouse Over Fired, realTarget is ' + realTarget.className  + '@' + getId(realTarget) + '(lastTarget is ' + lastTarget.className  + '@' + getId(lastTarget) + ')');
			*/
			var oClass = realTarget.getAttribute('overClass');
			if(oClass){
				realTarget.setAttribute('origClass', realTarget.className);
				if (hasClass(realTarget, 'DragBox')) {
				    removeClass(realTarget, 'DragBox')
				}
				addClass(realTarget, oClass);
			}
		}

		// if the user is just starting to drag the element
		if(iMouseDown && !lMouseState){
			writeHistory(realTarget, 'Start Dragging');

			// mouseDown target
			curTarget = realTarget;

			var mdlname_div = curTarget.parentElement.previousElementSibling;
			mdlname = mdlname_div.id;
			dragDropTarget = realTarget;
			
			// Record the mouse x and y offset for the element
			rootParent    = curTarget.parentNode;
			rootSibling   = curTarget.nextSibling;

			mouseOffset   = getMouseOffset(realTarget, ev);

			// We remove anything that is in our dragHelper DIV so we can put a new item in it.
			for(var i=0; i<dragHelper.childNodes.length; i++) {
				dragHelper.removeChild(dragHelper.childNodes[i]);
			}

			// Make a copy of the current item and put it in our drag helper.
			dragHelper.appendChild(curTarget.cloneNode(true));
			dragHelper.style.display = 'block';

			// set the class on our helper DIV if necessary
			var dragClass = curTarget.getAttribute('dragClass');
			if(dragClass){
				if (hasClass(dragHelper.firstChild, 'DragBox')) {
				    removeClass(dragHelper.firstChild, 'DragBox')
				}
				addClass(dragHelper.firstChild, dragClass);


			}

			// disable dragging from our helper DIV (it's already being dragged)
			dragHelper.firstChild.removeAttribute('DragObj');

			/*
			Record the current position of all drag/drop targets related
			to the element.  We do this here so that we do not have to do
			it on the general mouse move event which fires when the mouse
			moves even 1 pixel.  If we don't do this here the script
			would run much slower.
			*/
			var dragConts = DragDrops[dragObj];

			/*
			first record the width/height of our drag item.  Then hide it since
			it is going to (potentially) be moved out of its parent.
			*/
			curTarget.setAttribute('startWidth',  parseInt(curTarget.offsetWidth));
			curTarget.setAttribute('startHeight', parseInt(curTarget.offsetHeight));
			curTarget.style.display = 'none';

			// loop through each possible drop container
			for(var i=0; i<dragConts.length; i++){
				let container = dragConts[i];
				var pos = getPosition(container);

				/*
				save the width, height and position of each container.

				Even though we are saving the width and height of each
				container back to the container this is much faster because
				we are saving the number and do not have to run through
				any calculations again.  Also, offsetHeight and offsetWidth
				are both fairly slow.  You would never normally notice any
				performance hit from these two functions but our code is
				going to be running hundreds of times each second so every
				little bit helps!

				Note that the biggest performance gain here, by far, comes
				from not having to run through the getPosition function
				hundreds of times.
				*/
				setAttribute('startWidth',  parseInt(offsetWidth));
				setAttribute('startHeight', parseInt(offsetHeight));
				setAttribute('startLeft',   pos.x);
				setAttribute('startTop',    pos.y);

				// loop through each child element of each container
				for(var j=0; j<container.childNodes.length; j++){
					let child = container.childNodes[j];
					if((nodeName=='#text') || (child==curTarget)) 
						continue;

					var pos = getPosition(child);

					// save the width, height and position of each element
					setAttribute('startWidth',  parseInt(offsetWidth));
					setAttribute('startHeight', parseInt(offsetHeight));
					setAttribute('startLeft',   pos.x);
					setAttribute('startTop',    pos.y);
				}
			}
		}

		// track the current mouse state so we can compare against it next time
		lMouseState = iMouseDown;

		// mouseMove target
		lastTarget  = realTarget;
	}
	
	if(curTarget){
	    /*
		if (lastTarget!=realTarget) {
			writeHistory(lastTarget, 'Moving --- x = ' + mousePos.x + ', y = ' + mousePos.y + '  ' + Math.random() + ', lastTarget = ' + lastTarget.className + '@' + getId(lastTarget) +', target = ' + target.className  + ', realTarget = ' + realTarget.className + '@' + getId(realTarget));
		}else{
			writeHistory(lastTarget, 'Moving --- x = ' + mousePos.x + ', y = ' + mousePos.y + '  ' + Math.random() + ', lastTarget == realTarget == ' + realTarget.className + '@' + getId(realTarget));
		}
		*/
		
		// move our helper div to wherever the mouse is (adjusted by mouseOffset)
		dragHelper.style.top  = mousePos.y - mouseOffset.y;
		dragHelper.style.left = mousePos.x - mouseOffset.x;
		dragHelper.style.width = curTarget.getAttribute('startWidth');
		dragHelper.firstChild.style.width = curTarget.getAttribute('startWidth');

		var dragConts  = DragDrops[curTarget.getAttribute('DragObj')];
		var activeCont = null;

		var xPos = mousePos.x - mouseOffset.x + (parseInt(curTarget.getAttribute('startWidth')) /2);
		var yPos = mousePos.y - mouseOffset.y + (parseInt(curTarget.getAttribute('startHeight'))/2);

		if (renderImg) {
			var imageframe = getByClass('imgframe', dragHelper.firstChild);
			var canvas = getByClass('canvas_image', imageframe);
			var img = canvas.parentNode.querySelector("img");
			var cxt = canvas.getContext("2d");
			img.onload = function() {
			    cxt.drawImage(img, 0, 0, canvas.width, canvas.height)
		        }
			// draw the old canvas on the new canvas if the image does not exist
			img.onerror = function() {
			    var targetCanvas = getByClass('canvas_image', curTarget);
			    cxt.drawImage(targetCanvas, 0, 0, canvas.width, canvas.height);
			}
			renderImg = false;
		}
		
		// check each drop container to see if our target object is "inside" the container
		for(var i=0; i<dragConts.length; i++){
			let container = dragConts[i];
			if((parseInt(getAttribute('startLeft'))                                           < xPos) &&
				(parseInt(getAttribute('startTop'))                                            < yPos) &&
				((parseInt(getAttribute('startLeft')) + parseInt(getAttribute('startWidth')))  > xPos) &&
				((parseInt(getAttribute('startTop'))  + parseInt(getAttribute('startHeight'))) > yPos)){

					/*
					our target is inside of our container so save the container into
					the activeCont variable and then exit the loop since we no longer
					need to check the rest of the containers
					*/
					activeCont = container;

					// exit the for loop
					break;
			}
		}

		// Our target object is in one of our containers.  Check to see where our div belongs
		if(activeCont){
			if(activeCont != curTarget.parentNode){
				writeHistory(curTarget, 'Moved into '+activeCont.id);
			}

			// beforeNode will hold the first node AFTER where our div belongs
			var beforeNode = null;

			// loop through each child node (skipping text nodes).
			for(var i=activeCont.childNodes.length-1; i>=0; i--){
				let child = activeCont.childNodes[i];
				if(nodeName=='#text') 
					continue;

				// if the current item is "After" the item being dragged
				if(curTarget != child                                                  &&
					((parseInt(getAttribute('startLeft')) + parseInt(getAttribute('startWidth')))  > xPos) &&
					((parseInt(getAttribute('startTop'))  + parseInt(getAttribute('startHeight'))) > yPos)){
						beforeNode = child;
				}
			}

			// the item being dragged belongs before another item
			if(beforeNode){
				if(beforeNode!=curTarget.nextSibling){
					writeHistory(curTarget, 'Inserted Before '+beforeNode.id);
					activeCont.insertBefore(curTarget, beforeNode);
				}

			// the item being dragged belongs at the end of the current container
			} else {
				if((curTarget.nextSibling) || (curTarget.parentNode!=activeCont)){
					writeHistory(curTarget, 'Inserted at end of '+activeCont.id);
					activeCont.appendChild(curTarget);
				}
			}

			// the timeout is here because the container doesn't "immediately" resize
			setTimeout(function(){
				var contPos = getPosition(activeCont);
				activeCont.setAttribute('startWidth',  parseInt(activeCont.offsetWidth));
				activeCont.setAttribute('startHeight', parseInt(activeCont.offsetHeight));
				activeCont.setAttribute('startLeft',   contPos.x);
				activeCont.setAttribute('startTop',    contPos.y);
			}, 5);

			// make our drag item visible
			if(curTarget.style.display!=''){
				writeHistory(curTarget, 'Made Visible');
				curTarget.style.display    = '';
				curTarget.style.visibility = 'hidden';
			}
			dragObject = dragHelper;
			
		} else {
			// our drag item is not in a container, so hide it.
			if(curTarget.style.display!='none'){
				writeHistory(curTarget, 'Hidden');
				curTarget.style.display  = 'none';
			}
		}
	}

	if(dragObject){
		dragObject.style.position = 'absolute';
		dragObject.style.top      = mousePos.y - mouseOffset.y;
		dragObject.style.left     = mousePos.x - mouseOffset.x;
	}

	// track the current mouse state so we can compare against it next time
	lMouseState = iMouseDown;

	// this prevents items on the page from being highlighted while dragging
	if(curTarget || dragObject) return false;
}

function mouseUp(ev){

	if(curTarget){
		writeHistory(curTarget, 'Mouse Up Fired');

		dragHelper.style.display = 'none';
		if(curTarget.style.display == 'none'){
			if(rootSibling){
				rootParent.insertBefore(curTarget, rootSibling);
			} else {
				rootParent.appendChild(curTarget);
			}
		}
		curTarget.style.display    = '';
		curTarget.style.visibility = 'visible';
	}
	
	curTarget  = null;
	dragObject = null;

	iMouseDown = false;
	renderImg = true;
	
	if (dragDropTarget!=null) {
		var parent = dragDropTarget.parentElement;
		var children = getAllByClass('viewmarkerframe', parent);

		var ids = [];
		for (i=0; i<children.length; i++) {
			ids.push(children[i].id);
		}

		if (globalview) {
			updateViewMarker(mdlname, ids, "drag_drop_update");
		}else{
			updateViewMarker(mdlname, ids, "drag_drop_update_model");
		}
		
		dragDropTarget = null;
	}
}

function mouseDown(ev){
	ev         = ev || window.event;
	var target = ev.target || ev.srcElement;

	if (target.className == "" ||
		target.className == "manageModeButton" ||
		target.className == "outermost" || 
		target.className == "outermost hideCanvas" || 
		target.className == "viewmarkerframe_mdlname" || 
		target.className == "global_viewmarks" || 
		target.className == "viewmarkerframe_outer DragContainer") {
		return;
	}

	if (target && target.parentElement && target.parentElement.classList.contains("editPane"))
		return;

	if (target && target.classList.contains("nameLabel"))
		return;
		
	iMouseDown = true;
	if(lastTarget){
		writeHistory(lastTarget, 'Mouse Down Fired');
	}

	if(target.onmousedown || target.getAttribute('DragObj')){
		return false;
	}
}

/*
function makeDraggable(item){
	if(!item) return;
	item.onmousedown = function(ev){
		dragObject  = this;
		mouseOffset = getMouseOffset(this, ev);
		return false;
	}
}

function makeClickable(item){
	if(!item) return;
	item.onmousedown = function(ev){
		document.getElementById('ClickImage').value = this.name;
	}
}

function addDropTarget(item, target){
	item.setAttribute('droptarget', target);
}
*/


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

function getId(div) {
    if (div==null) {
        console.log('getId: div is null.');
    }  

	if (div.className.indexOf('viewmarkerframe')>=0 && div.className.indexOf('_')<0) {
		return div.id;
	}
	
	var parent = div;
	while (1) {		
		var p = parent.parentElement;
		if (p==null) {
			break;
		}else{
			parent = p;
		}
		
		if (parent.className.indexOf('viewmarkerframe ')>=0 && parent.className.indexOf('_')<0) {
			return parent.id;
		}
	}
	
	return '';
}

function getDraggable(div) {
	if (div.className.indexOf('viewmarkerframe')>=0 && div.className.indexOf('_')<0) {
		return div;
	}
	
	var parent = div;
	while (1) {		
		var p = parent.parentElement;
		if (p==null) {
			break;
		}else{
			parent = p;
		}
		
		if (parent.className.indexOf('viewmarkerframe ')>=0 && parent.className.indexOf('_')<0) {
			return parent;
		}
	}
	
	return '';
}

function isCanvasBlank(canvas) {
	if (blankCanvas==null) {
		blankCanvas = document.createElement('canvas');
		blankCanvas.width = canvas.width;
		blankCanvas.height = canvas.height;
	}
	
    return canvas.toDataURL() == blankCanvas.toDataURL();
}
document.onmousemove = mouseMove;
document.onmousedown = mouseDown;
document.onmouseup   = mouseUp;
