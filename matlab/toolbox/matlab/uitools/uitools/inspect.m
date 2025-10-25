function [argout] = inspect(varargin)
%INSPECT Open the inspector and inspect object properties
%
%   INSPECT (h) edits all properties of the given object whose handle is h,
%   using a property-sheet-like interface.
%   INSPECT ([h1, h2]) edits both objects h1 and h2; any number of objects
%   can be edited this way.  If you edit two or more objects of different
%   types, the inspector might not be able to show any properties in common.
%   INSPECT with no argument launches a blank inspector window.
%
%   Note that "INSPECT h" edits the string 'h', not the object whose
%   handle is h.

%   Copyright 1984-2024 The MathWorks, Inc.

import matlab.internal.capability.Capability;

% g1695984: Early return if inspect is called from the Live Editor. Please
% note that this is the temporary fix which should be removed once
% inspector can operate on the live Editor figures.
if feature('LiveEditorRunning')
    warning(message('MATLAB:uitools:inspector:UnsupportedInLiveEditor'));
    return;
end

if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

nin = nargin;
vargin = varargin;
doPushToFront = true;
doAddDestroyListener = false;

%add selection listener but only in HG2 because Property Inspector gets
%selection events in scribeaxes.m in HG1
persistent selectionListener;

%
if isempty(selectionListener)
    plotmgr = matlab.graphics.annotation.internal.getplotmanager;
    selectionListener = event.listener(plotmgr,'PlotSelectionChange',@localChangedSelectedObjects);
end


if nargin==1
    if ischar(vargin{1})
        switch(vargin{1})
            case '-close'
                if usejava('jvm')
                    com.mathworks.mlservices.MLInspectorServices.closeWindow;
                end
                if matlab.graphics.internal.propertyinspector.shouldShowNewInspector()
                    matlab.graphics.internal.propertyinspector.propertyinspector('hide');
                end
                return;
            case '-isopen'
                if usejava('jvm')
                    argout = com.mathworks.mlservices.MLInspectorServices.isInspectorOpen;
                    return;
                else
                    argout = false;
                end
        end
    end

elseif nargin>=2
    if ischar(vargin{1})

        switch(vargin{1})

            % For debugging
            % Remove this syntax entirely in 11 A release
            case 'newinspector'
                warning(message('MATLAB:uitools:inspector:InvalidSyntax'));
                return

                % For debugging
                % Remove this syntax entirely after 7B release
            case 'newtreetable'
                warning(message('MATLAB:uitools:inspector:InvalidTreeTableSyntax'));
                return

                % For debugging
            case 'desktopclient'
                if strcmp(varargin{2},'on')
                    com.mathworks.mde.inspector.Inspector.setDesktopClient(true);
                elseif strcmp(varargin{2},'off')
                    com.mathworks.mde.inspector.Inspector.setDesktopClient(false);
                end
                return

                % For debugging
            case 'autoupdate'
                if strcmp(varargin{2},'on')
                    com.mathworks.mde.inspector.Inspector.setAutoUpdate(true);
                elseif strcmp(varargin{2},'off')
                    com.mathworks.mde.inspector.Inspector.setAutoUpdate(false);
                end
                return

                % Called by the inspector Java code
            case '-getInspectorPropertyGrouping'
                obj = varargin{2};
                argout = localGetInspectorPropertyGrouping(obj);
                return;

                % Called by the inspector Java code
            case '-hasHelp'
                obj = varargin{2};
                argout = localHasHelp(obj);
                return;

                % Called by the inspector Java code
            case '-showHelp'
                if length(varargin)>=3
                    obj = varargin{2};
                    propname = varargin{3};
                    localShowHelp(obj,propname);
                end
                return;

        end % Switch

    elseif ischar(vargin{2})
        switch(vargin{2})
            case '-ifopen'
                if (com.mathworks.mlservices.MLInspectorServices.isInspectorOpen)
                    % prune off string
                    nin = 1;
                    doPushToFront = false;
                else
                    return;
                end
        end
    end
end

switch nin

    case 0
        % Show the inspector.
        if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector && ...
                ~isempty(get(0,'CurrentFigure')) && ...
                matlab.graphics.internal.propertyinspector.shouldShowNewInspector()
            matlab.graphics.internal.propertyinspector.propertyinspector('show');
        else
            matlab.graphics.internal.propertyinspector.propertyinspector('show', internal.matlab.inspector.EmptyObject);
        end
    case 1
        obj = vargin{1};

        if all(ishghandle(obj)) || (all(isa(obj, 'handle') && all(isobject(obj)) && all(isvalid(obj))) ...
                || all(ishandle(obj)))

            hdl = obj;

            % Check if a graphic object, or a non-java MCOS object is inspected,
            % the and feature switch for inspector is turned on
            if all(ishghandle(obj)) || isjava(obj) || (isobject(obj)) && ...
                    ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector

                % Show old java inspector for uicomponents
                if matlab.graphics.internal.propertyinspector.shouldShowNewInspector(obj)

                    % Save the variable name argument to inspect().  This needs
                    % to be done here since this is the only time we have access
                    % to the inputname.
                    varName = inputname(1);
                    matlab.graphics.internal.propertyinspector.PropertyInspectorManager.getInstance.setCurrentVarName(varName);

                    % Show the inspector
                    matlab.graphics.internal.propertyinspector.propertyinspector('show',obj);
                    % By-pass rest of the logic and early return
                    return;
                end
            end
        else
            error(message('MATLAB:uitools:inspector:invalidinput'));
        end

        % Check if the object is JavaVisible for Java Inspector
        % arrayfun because isa(<array of axes and charts>,'JavaVisible')
        % returns false when charts inherit JavaVisible via different base-classes
        if isobject(obj) && ~all(arrayfun(@(a) isa(a,'JavaVisible'), obj))
            error(message('MATLAB:uitools:inspector:invalidobject'));
        end
        enablePlotEditMode(obj);
        if ~isempty(hdl)
            len = builtin('length',hdl);
            if len == 1
                if len == 1 && ~isa(obj, 'handle')
                    % obj has value semantics so do not make a copy that was
                    % made from hdl = obj(...)
                    obj = requestJavaAdapter(obj);
                else
                    obj = requestJavaAdapter(hdl);
                end
                if ~localIsUDDObject(obj)
                    doAddDestroyListener = true;
                end
                com.mathworks.mlservices.MLInspectorServices.inspectObject(obj,doPushToFront);
            else
                obj = requestJavaAdapter(hdl);
                if ~localIsUDDObject(obj)
                    doAddDestroyListener = true;
                end
                com.mathworks.mlservices.MLInspectorServices.inspectObjectArray(obj,doPushToFront);
            end

            if doAddDestroyListener
                % Listen to when the object gets deleted and remove
                % from inspector. A persistent variable is used since
                % the inspector is a singleton. If we do go away from
                % a singleton then this will have to be stored elsewhere.
                persistent deleteListener; %#ok
                hobj = handle(hdl);
                deleteListener = handle.listener(hobj, 'ObjectBeingDestroyed', ...
                    {@localObjectRemoved, obj, com.mathworks.mlservices.MLInspectorServices.getRegistry});
            end

        else
            % g512786 This is necessary because inrepreter does not
            % convert empty MCOS objects to null and this call would error
            % out. It worked fine for UDD objects because interpreter
            % converted them to null in this case. Pass in [] only for
            % MATLAB objects as returned by isobject(). For all other
            % objects including Java objects use obj reference.
            if isobject(obj)
                com.mathworks.mlservices.MLInspectorServices.inspectObject([],doPushToFront);
            else
                com.mathworks.mlservices.MLInspectorServices.inspectObject(obj,doPushToFront);
            end
        end

    otherwise
        if ~matlab.graphics.internal.propertyinspector.PropertyInspectorManager.showJavaInspector
            allObjects = cellfun(@(x) ishghandle(x), vargin, 'UniformOutput', 1);
            if all(allObjects)
                % Check if any of the objects passed as arguments have uifigure
                % as ancestor, then return
                if all(matlab.graphics.internal.propertyinspector.shouldShowNewInspector([vargin{:}]))
                    % Show the inspector
                    matlab.graphics.internal.propertyinspector.propertyinspector('show',vargin);
                    % By-pass rest of the logic and early return
                    return;
                end
            end
        end
        % bug -- need to make java adapters for multiple arguments
        enablePlotEditMode(vargin);
        com.mathworks.mlservices.MLInspectorServices.inspectObjectArray(vargin,doPushToFront);
end

% The function ensures that we enable plot-edit mode for all parent JAVA figures
% for the currently inspected objects
function enablePlotEditMode(hObjs)
% E.g. inspect(line, timer, line) -> hObjs is a cell. We want to find the
% graphic objects in order to enable plot edit mode.
if iscell(hObjs)
    indexToGraphicObjects = cellfun(@(x) ishghandle(x), hObjs, 'UniformOutput', 1);
    hObjs = hObjs(indexToGraphicObjects);
    % Get the graphics array
    hObjs = [hObjs{:}];
end

% We need to find the figure ancestor of the currently inspected object(s).
hFig = ancestor(hObjs,'figure');
if iscell(hFig)
    hFig = [hFig{:}];
end

% Find the unique figures in the figure array. ic is used to
% index onto the object array to find out which object(s) belong
% to a certain figure
[figureHandles,~,indexByFigure] = unique(hFig);

% Below logic ensures that we enable the plotedit mode on the parent JAVA figure
% and also select the inspected object
for i=1:numel(figureHandles)
    iFig = figureHandles(i);
    iObj = hObjs(indexByFigure==i);
    % Enable plotedit mode if object is selectable and plotedit
    % mode is off
    if ~isempty(iFig) && isvalid(iFig) && ...
            ~isempty(matlab.graphics.internal.getFigureJavaFrame(iFig)) && ...
            all(isprop(iObj,'Selected'))
        if ~isactiveuimode(iFig,'Standard.EditPlot')
            plotedit(iFig,'on');
        end
        selectobject(iObj,'replace');
    end
end


function localChangedSelectedObjects(~,eventData)
% Java inspector may be unsupported for certain objects e.g. PointDataTip.
% Now, with plotedit mode support for uifigures; users can interactively
% click on data tips in uifigures while inspector is opened. This check is
% added to avoid warnings/errors.

%----------------------------------------------------%
function localObjectRemoved(hSrc, event, obj, objRegistry) %#ok
% Used by original MWT Inspector implementation

objRegistry.setSelected({obj}, 0);

%----------------------------------------------------%
function bool = localIsUDDObject(h)
% Returns true if the input handles can be represented as a
% UDDObject in Java. We need to know this in order to determine
% whether or not we can add listeners on the Java side or the
% MATLAB code side.
%
% Example:
%    handle(0)                 Returns true
%    handle(java.awt.Button)   Returns false

bool = false;
if isscalar(h)
    bool = com.mathworks.mlservices.MLInspectorServices.isUDDObjectInJava(h);
elseif isvector(h)
    bool = com.mathworks.mlservices.MLInspectorServices.isUDDObjectArrayInJava(h);
end

%----------------------------------------------------%
function jhash = localGetInspectorPropertyGrouping(obj)

jhash = java.util.HashMap;

% For now, don't group multiple objects
if iscell(obj)
    obj = obj{1};
end

% Cast to a handle
if ~ishandle(obj)
    return
end
obj = handle(obj);

% Get grouping for this object
info = inspectGetGroupingHelper(obj);

% Convert to a hashtable
for n = 1:length(info)
    group_name = info{n}{1};
    prop_names = info{n}{2};
    for m = 1:length(prop_names)
        jhash.put(java.lang.String(prop_names{m}),group_name);
    end
end

%----------------------------------------------------%
function b = localHasHelp(hObj)
% Returns true if this instance has a property reference page

% For now, don't group multiple objects
if iscell(hObj)
    hObj = hObj{1};
end

classname = localGetClassName(hObj);
b = java.lang.Boolean(matlab.internal.doc.reference.classHasPropertyHelp(classname));

%----------------------------------------------------%
function localShowHelp(hObj,propname)
% Displays help for the supplied instance and property

% For now, don't group multiple objects
if iscell(hObj)
    hObj = hObj{1};
end

if ishandle(hObj) && ischar(propname)
    classname = localGetClassName(hObj);
    matlab.internal.doc.reference.showPropertyHelp(classname, propname);
end

%----------------------------------------------------%
function classname = localGetClassName(hObj)
% Returns the full absolute class name for a supplied instance

classname = [];
if ishandle(hObj)
    hObj = handle(hObj);
    if ~isobject(hObj)
        hCls = classhandle(hObj);
        hPk = get(hCls,'Package');
        classname = [get(hPk,'Name'), '.',get(hCls,'Name')];
    else
        classname=class(hObj);
    end
end

%----------------------------------------------------%

% Certain objects do not support java inspector e.g. PointDataTip. With
% plotedit mode support for uifigures which show java inspector; users can
% get into a state where java inspector is opened and users select data
% tips. In such cases, plotselection change should be ignored and nothing
% should happen. g2228168
function isSupported = localIsInspectorSupported(hObjs)
isSupported = true;
hObjs = handle(hObjs);

% This logic relies on the assumption that when you have a data tip
% object inside a UiFigure; you cannot multi-select another object.
if iscell(hObjs)
    indexToGraphicObjects = cellfun(@(x) ishghandle(x), hObjs, 'UniformOutput', 1);
    hObjs = hObjs(indexToGraphicObjects);
    % Get the graphics array
    hObjs = [hObjs{:}];
end

% We need to find the figure ancestor of the currently inspected object(s).
hFig = ancestor(hObjs,'figure');
if iscell(hFig)
    hFig = hFig{1};
end

% This will return false for a data tip inside uifigure
if ~isempty(hFig) && matlab.ui.internal.FigureServices.isUIFigure(hFig)
    for i=1:numel(hObjs)
        if isa(hObjs(i),'matlab.graphics.shape.internal.PointDataTip') || ...
                isa(hObjs(i),'matlab.graphics.datatip.DataTip')
            isSupported = false;
            break;
        end
    end
end
