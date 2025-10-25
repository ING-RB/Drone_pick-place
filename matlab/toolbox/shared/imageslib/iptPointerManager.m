function api = iptPointerManager(figHandle, str)
%iptPointerManager Install mouse pointer manager in figure.
%   iptPointerManager(hFigure) creates a pointer manager in the specified
%   figure.
%
%   iptPointerManager(hFigure, 'disable') disables the figure's pointer
%   manager.
%
%   iptPointerManager(hFigure, 'enable') enables and updates the figure's
%   pointer manager.
%
%   If the figure already contains a pointer manager, then
%   iptPointerManager(hFigure) does not create a new one.  It has the same
%   effect as iptPointerManager(hFigure, 'enable').
%
%   Use iptPointerManager in conjunction with iptSetPointerBehavior to vary
%   the figure's mouse pointer depending on which object it is
%   over. iptSetPointerBehavior is used on a specific object to define
%   specific actions that occur when the mouse pointer moves over and then
%   leaves the object.  See the iptSetPointerBehavior documentation for more
%   information.       
%
%   EXAMPLE
%   =======
%   Plot a line.  Install a pointer manager in the figure, and then give the
%   line a "pointer behavior" that changes the mouse pointer into a fleur
%   whenever the pointer is over it.
%
%       h = plot(1:10);
%       iptPointerManager(gcf);
%       enterFcn = @(hFigure, currentPoint) set(hFigure, 'Pointer', 'fleur');
%       iptSetPointerBehavior(h, enterFcn);
%
%   See also iptGetPointerBehavior, iptSetPointerBehavior.

%   Copyright 2005-2021 The MathWorks, Inc.

% Information hiding:
% This routine hides the specific mechanism used to install and retrieve a
% pointer manager in a figure.  It hides from the client whether or not a
% pointer manager already exists in the figure.  It even hides what a
% pointer manager exactly is.

% Assert that there is one or two input arguments.
if nargin > 1
    str = convertStringsToChars(str);
end

narginchk(1, 2);

% Assert that the first input argument is a valid figure handle.
iptcheckhandle(figHandle, {'figure'}, mfilename, 'figHandle', 1);

% Check second input argument.
default_str = 'enable';
if nargin < 2
    str = default_str;
end

str = validatestring(str,...
    {'enable', 'disable'},...
    mfilename,...
    'STR',...
    2);

pointerManager = getFigurePointerManager(figHandle);

% If no pointer manager found, create one.
if isempty(pointerManager)
    pointerManager = createPointerManager(figHandle);
    setFigurePointerManager(figHandle, pointerManager);
end

if strcmp(str, 'enable')
    pointerManager.API.enable();
else
    pointerManager.API.disable();
end

if nargout > 0
    % Output argument is to facilitate unit testing.  It is undocumented.
    api = pointerManager.API;
end


end

function pointerManager = getFigurePointerManager(figHandle)
% getFigurePointerManager takes a figure handle as an input argument and
% returns the pointer manager struct, or it returns [] if there is no
% pointer manager in the figure.

% Preconditions (not checked):
%     One input argument.
%     Input argument is a valid figure handle.

% Information hiding:
%     This routine, together with setFigurePointerManager, hides the
%     specific mechanism used to save and retrieve a pointer manager in a
%     figure.

pointerManager = getappdata(figHandle, 'iptPointerManager');

% Assert that pointer manager is valid.
if ~isempty(pointerManager) && ~isValidPointerManager(pointerManager)      
    error(message('imageslib:iptPointer:invalidPointerManagerGet'))
end
end

function setFigurePointerManager(figHandle, pointerManager)
% setFigurePointerManager(figHandle, pointerManager) stores the pointer
% manager in the specified figure.

% Preconditions (not checked):
%     Two input arguments
%     First input argument is a valid HG figure handle.
%     Second input argument is a valid pointer manager struct.

% Information hiding:
%     This routine, together with getFigurePointerManager, hides the
%     specific mechanism used to save and retrieve a pointer manager in a
%     figure.

setappdata(figHandle, 'iptPointerManager', pointerManager);

end

function p = isValidPointerManager(pointerManager)
% p = isValidPointerManager(pointerManager) returns true if its input is
% a valid pointer manager struct.  This is used to protect against the
% pointer manager struct getting corrupted, which can occur if someone
% sets the "iptPointerManager" appdata directly.

p = isscalar(pointerManager) && ...
    isstruct(pointerManager) && ...
    isfield(pointerManager, 'API') && ...
    isfield(pointerManager, 'listener');
end

function fcn = createFigurePointerRestoreFcn(figHandle)
% fcn = createFigurePointerRestoreFcn(figHandle) creates a function
% handle that sets the state of the input figure's mouse pointer to
% whatever it was when this function was called.

% Preconditions (not checked):
%     one input argument
%     input argument is a valid figure handle

figurePointer             = get(figHandle, 'Pointer');
figurePointerShapeCData   = get(figHandle, 'PointerShapeCData');
figurePointerShapeHotSpot = get(figHandle, 'PointerShapeHotSpot');
fcn = @() set(figHandle, ...
    'Pointer', figurePointer, ...
    'PointerShapeCData', figurePointerShapeCData, ...
    'PointerShapeHotSpot', figurePointerShapeHotSpot);
end

function callIfNotEmpty(fcn, varargin)
% callIfNotEmpty(fcn, varargin) calls the function handle fcn with the
% input arguments varargin{:}, unless fcn is [].  In that case, the
% function simply returns without doing anything.

if ~isempty(fcn)
    fcn(varargin{:});
end
end

function pointerManager = createPointerManager(figHandle)
% createPointerManager takes a figure handle as an input argument and
% creates a pointer manager struct.  The fields of the struct include
% api, which is the pointer manager api, and listener, which is the
% WindowMouseMotion event listener.

% Preconditions (not checked):
%     One input argument
%     Input argument is a valid HG figure handle.

% Information hiding:
%     Hides from the rest of the application and from clients the
%     implementation of the api and the implementation of mouse pointer
%     updating.

% Initialize outer scope of cross-function variables. Note that figHandle
% is also used as a cross-function variable.
currentManagedObject = [];
figurePointerRestoreFcn = [];
isEnabled = false;
lastCurrentPoint = [0 0];
lastHitObject = figHandle;

% Initialize API field of pointer manager struct with function handles
% for enable and disable.
pointerManager.API.enable = @enablePointerManager;
pointerManager.API.disable = @disablePointerManager;

callbackFcn = @updatePointer;

% Create WindowMouseMotion event listener whose callback implements the
% pointer updating behavior. Save listener in the pointer manager
% struct.
pointerManager.listener = event.listener(figHandle,...
    'WindowMouseMotion', ...
    callbackFcn);

    function enablePointerManager()
        % Enables the pointer manager so that it responds to
        % WindowMouseMotion events.  Calls the updatePointer() function.
        %
        % Modifies cross-function variable isEnabled.
        
        isEnabled = true;
        
        % We want to simulate a mouse event here, but we cannot set the
        % read only properties of an *actual* mouse event object.  Instead
        % we construct a struct that has the necessary fields.   We will
        % call updatePointer "manually" as if the first arg is the figure
        % handle and the second argument is an object containing the
        % WindowMouseMotion event data.
        evt = constructMouseEventData(lastHitObject,lastCurrentPoint);
        
        % We are caching the last known HitObject from the event data.
        % Between when that HitObject was cached and when the
        % PointerManager was re-enabled, this handle may no longer be
        % valid. We only want to update the pointer based on a valid
        % lastHitObject. Otherwise, the pointer will be refreshed on the
        % next WindowMouseMotion event, where the HitObject is guaranteed
        % to be valid since it will be passed by HG.
        if isvalid(lastHitObject)
            updatePointer(figHandle, evt);
        end
        
    end

    function disablePointerManager
        % Disables the pointer manager so that it no longer responds to
        % WindowMouseMotion events.
        %
        % Modifies cross-function variable isEnabled.
        
        isEnabled = false;
    end

    function updatePointer(hFigure, mouseMotionEvent)
        % Responds to WindowMouseMotion events.  Invokes pointer behavior of
        % object that pointer is over.  Updates internal state appropriately.
        %
        % Reads cross-function variable isEnabled.
        % Reads and modifies cross-function variable currentManagedObject.
        % Reads and modifies cross-function variable figurePointerRestoreFcn.
        
        currentPoint = mouseMotionEvent.Point;
        % Update our last known HitObject. We refresh lastHitObject so
        % that we have up-to-date information when the manager is
        % enabled.
        lastHitObject = mouseMotionEvent.HitObject;
        
        % Update our last known currentPoint.  Even if the pointer manager
        % is disabled, we refresh lastCurrentPoint so that we have
        % up-to-date information when the manager is enabled.
        lastCurrentPoint = currentPoint;
        
        % If pointer manager is disabled, return early.
        if ~isEnabled
            return;
        end
        
        % Find the lowest object in the HG hierarchy starting at currentPoint that
        % has a pointer behavior.
        overMe = findLowestManagedObject(mouseMotionEvent);

        % If the pointer-managed object is part of an axes or figure with
        % an active interactivity mode, such as pan or zoom, then take no
        % action. Note: ancestor returns empty if its input is empty, or if
        % if its input is not a descendent of an axes object.
        ax = ancestor(overMe.Handle,"axes");
        if ~isempty(ax) && imageslib.internal.app.utilities.isAxesInteractionModeActive( ...
                ax,figHandle)
            return
        end
        
        % If the "over me" object is the same as the currentManagedObject,
        % then invoke the traverseFcn of the currentManagedObject and
        % return.
        if isequal(overMe, currentManagedObject)
            callIfNotEmpty(currentManagedObject.PointerBehavior.traverseFcn, ...
                hFigure, currentPoint);
            return;
        end
        
        if ~isempty(overMe.PointerBehavior)
            % If the currentManagedObject is empty, create a new
            % figurePointerRestoreFcn that will return the figure's pointer
            % to its current state; otherwise invoke the
            % currentManagedObject's exitFcn.
            if isempty(currentManagedObject)
                figurePointerRestoreFcn = createFigurePointerRestoreFcn(hFigure);
            else
                callIfNotEmpty(currentManagedObject.PointerBehavior.exitFcn, ...
                    hFigure, currentPoint);
            end
            
            % Invoke the "over me" object's enterFcn and traverseFcn.
            callIfNotEmpty(overMe.PointerBehavior.enterFcn, hFigure, currentPoint);
            callIfNotEmpty(overMe.PointerBehavior.traverseFcn, hFigure, currentPoint);
            
            % Save the "over me" object.
            currentManagedObject = overMe;
            
        else
            
            if ~isempty(currentManagedObject)
                % Invoke the currentManagedObject's exitFcn, clear the
                % currentManagedObject, and restore the figure pointer.
                callIfNotEmpty(currentManagedObject.PointerBehavior.exitFcn, ...
                    hFigure, currentPoint);
                currentManagedObject = [];
                figurePointerRestoreFcn();
                
            else
                % No code needed here; pointer is over unmanaged area.
            end
            
        end
        
    end
end

%-----------------------------------------------------
function mouseEvt = constructMouseEventData(hitObject,currentPoint)
% Ideally we would like to cache the last WindowMouseData event at function
% scope instead of maintaining lastCurrentPoint and lastHitObject
% separately.  Instead we construct a pseudo event data object here using a
% struct with appropriately named fields.

mouseEvt = struct('Point',currentPoint,...
    'HitObject',hitObject);

end % constructMouseEventData
