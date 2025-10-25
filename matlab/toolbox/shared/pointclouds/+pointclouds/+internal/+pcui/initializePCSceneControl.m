function initializePCSceneControl(hFigure, pcAxes, scatterObj, params)
% Adds 3d scene control to figure for point cloud viewing.

% Copyright 2018-2024 The MathWorks, Inc.


% Point cloud visualization is very slow when interacting with point clouds
% on some MAC platforms. This happens when displayed on a webfigure.
% Checking for the rendering device to throw a warning to let user know
% about the workaround
% Code is disabled to address g3334726, will be re-enabled after g3356787 is
% fixed
% if ismac
%     info = rendererinfo;
%     rendererDevice = string(info.RendererDevice);
%     isAMD = contains(rendererDevice, "AMD");
%     isM1orM2 = contains(rendererDevice, ["Apple M1", "Apple M2"]);
%     isWebFigure = isa(getCanvas(hFigure),'matlab.graphics.primitive.canvas.HTMLCanvas');
% 
%     if isWebFigure && (isAMD || isM1orM2)
%         warning(message('vision:pointcloud:HGMACIssue'));
%     end
% end

pcAxes.Tag = 'PointCloud';  % We'll use this to recognize that the axes holds a point cloud

vertAxis        = params.VerticalAxis;
vertAxisDir     = params.VerticalAxisDir;
pointclouds.internal.pcui.initializeVerticalAxis(pcAxes, vertAxis, vertAxisDir);
resetplotview(pcAxes,'SaveCurrentView');

% Initialize the background color.  When color comes from command line, it
% may use any of the allowed color specifications. Change it to a numeric
% RGB value prior to sending it into setBackgroundColor()
backgroundColor = params.BackgroundColor;
backgroundColor = validatecolor(backgroundColor);
setBackgroundColor(hFigure, pcAxes, backgroundColor);

% Turn off the axis by default
axesVisibility = params.AxesVisibility;
pcAxes.Visible = axesVisibility;

% Set axes projection
projection = params.Projection;
setProjection(pcAxes, projection);

% Prepare the figure before setting up callbacks.
initUIMode(hFigure, pcAxes);

% Create axes toolbar
createAxesToolbar(pcAxes, params);

% Register callbacks. Left click rotate, wheel zoom.
ptCloudThreshold = params.PtCloudThreshold;
registerCallbacks(hFigure,scatterObj,vertAxis,vertAxisDir,ptCloudThreshold);

% Initialize user data
colorSource = params.ColorSource;
initUserData(pcAxes,ptCloudThreshold,colorSource);

% Switch to Camera pan/zoom mode
enableCameraPanZoomMode(pcAxes);

% Enable InvertHardcopy to save background as well, g2766953 (non uifigure ONLY).
if ~matlab.ui.internal.isUIFigure(hFigure)
    set(hFigure, 'InvertHardcopy', matlab.lang.OnOffSwitchState('off'));
end
% Change color based on color source for the color map
pointclouds.internal.pcui.changeColor(hFigure, colorSource);

viewPlane = params.ViewPlane;
pointclouds.internal.pcui.setView(viewPlane, pcAxes);

end

%--------------------------------------------------------------------------
% Register Callbacks
%--------------------------------------------------------------------------
function registerCallbacks(hFigure,hObj,vertAxis,vertAxisDir,ptCloudThreshold)
% Replace rotate3d's callback;
currentAxes = get(hFigure,'CurrentAxes');

% Enable rotate3d so we can get the registered mode.
rotate3d(hFigure,'on'); % this turns it on for all axes in the figure to match custom button state
hui = getuimode(hFigure,'Exploration.Rotate3d');

set(hui,'WindowButtonDownFcn',{@localBtnDown,hFigure,vertAxis,vertAxisDir});
set(hui,'WindowButtonUpFcn', {@localBtnUp});
set(hui,'WindowScrollWheelFcn',{@pointclouds.internal.pcui.localScrollWheelCallback,hFigure});
set(hui,'WindowButtonMotionFcn',@localPointerChange);

% Do not do anything extra than (un)click buttons/menu entries.
% This can preserve the context menu.
set(hui,'ModeStartFcn',{@localRotateStartMode,hFigure});
set(hui,'ModeStopFcn',{@localRotateStopMode,hFigure});

% Do not allow keyboard interaction
set(hui,'KeyReleaseFcn',@processKeyRelease);
set(hui,'KeyPressFcn',@processKeyPress);

% Add data cursor callback
dcmObj = datacursormode(hFigure);
set(dcmObj, 'UpdateFcn', @(o,e)dataCursorCallback(o,e));

% Add context menu items
initContextMenu(hFigure, hui);

% Turn on pan here to get the mode. This introduction is needed with web
% figures, otherwise the return value is empty.
pan(hFigure,'on');

hPanUI = getuimode(hFigure,'Exploration.Pan');

% Do not allow keyboard interaction
set(hPanUI,'KeyReleaseFcn',@processKeyRelease);
set(hPanUI,'KeyPressFcn',@processKeyPress);

rotate3d(hFigure,'on'); 

% Use a hidden property to store a cleanup listener and any additional
% information needed to clean up after the Scatter is blown. The listener
% fires when the Scatter object is being destroyed, and is used to undo the
% interactions registered in this function. Note that all interactions are
% not taken care of.
if ~isprop(currentAxes, 'PCSceneControlDestructor')
    sceneControlDestructor = currentAxes.addprop('PCSceneControlDestructor');
    sceneControlDestructor.Hidden       = true;
    sceneControlDestructor.Transient    = true;

    currentAxes.PCSceneControlDestructor = event.listener.empty();
end

% Add listener for cleanup and associate cleanup listener with life-cycle
% of current axes
currentAxes.PCSceneControlDestructor(end+1)= addlistener(hObj, ...
    'ObjectBeingDestroyed', @cleanupPCSceneControl);

udata = pointclouds.internal.pcui.utils.getAppData(hFigure, 'PCUserData');
if ~isfield(udata,'pcCallbackRegistered') || isempty(udata.pcCallbackRegistered)
    % If there is no userdata, register listeners
    addlistener(hFigure, 'WindowMousePress', @(o,e)localDownsample(o,e.HitObject,ptCloudThreshold));
    addlistener(hFigure, 'WindowMouseRelease', @(o,e)resetWindowMotion(o,e.HitObject));
    addlistener(hFigure, 'WindowKeyRelease', @(o,e)processFigKeyRelease(o,e));
end

udata.pcCallbackRegistered = true;
pointclouds.internal.pcui.utils.setAppData(hFigure, 'PCUserData', udata);

% Set the udata
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
udata.dataLimits = [currentAxes.XLim currentAxes.YLim currentAxes.ZLim];
udata.rotateFromCenter = pointclouds.internal.pcui.pcViewerRotationPreference();
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
end

%--------------------------------------------------------------------------
% Initialization - User data, UI mode interaction, Context menu
%--------------------------------------------------------------------------
function initUserData(currentAxes, ptCloudThreshold, colorSource)
% Initialize User Data

udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

% Do not downsample by default
udata.pcNeedsDownsample = false;

% Previous mouse motion
udata.pcshowMouseData = [];

% Flag to indicate the switch from  rotate to pan on a keyboard shortcut
udata.SwitchedFromRotate = false;

% Flag to indicate the visibility of the rotation axis (red-gree-blue axis)
udata.ShowRotationAxis = true;

pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);

pointclouds.internal.pcui.setColorMapData(currentAxes, colorSource);

% Determine if current axes needs downsample
localSetDownsample(currentAxes,ptCloudThreshold);
end

%--------------------------------------------------------------------------
function initUIMode(hFigure, pcAxes)

% Reset zoom and pan, enable rotation mode
zoom(pcAxes,'off');
pan(pcAxes,'off');
rotate3d(pcAxes,'on');

% Enable legacy exploration modes which are necessary to fully support
% uifigure due to rotate/pan/zoom customizations.
enableLegacyExplorationModes(hFigure);

disableDefaultInteractivity(pcAxes);

end

%--------------------------------------------------------------------------
function initContextMenu(hFigure, huimode)

if isempty(findall(hFigure,'tag','contextPCRotationCenter'))
    props_context.Parent = hFigure;
    props_context.Tag = 'PCRotateContextMenu';
    huimode.UIContextMenu = uicontextmenu(props_context);
    hui = huimode.UIContextMenu;

    % Generic attributes for all rotate context menus

    % Center of Rotation Axis
    props = [];
    if pointclouds.internal.pcui.pcViewerRotationPreference()
        props.Label = getString(message('vision:pointcloud:localCenterOfRotationModeDisable'));
    else
        props.Label = getString(message('vision:pointcloud:localCenterOfRotationModeEnable'));
    end
    props.Tag = 'contextPCRotationCenter';
    props.Separator = 'off';
    props.Callback = {@changeCenterOfRotationMode, hFigure};
    urrotate = uimenu(hui,props); %#ok

    % Color by row or column for organized pointClouds
    props = [];
    props.Label = getString(message('vision:pointcloud:ChangeColorBy'));
    props.Tag = 'contextPCChangeColor';
    props.Separator = 'off';
    urcolor = uimenu(hui,props);

    props.Label = getString(message('vision:pointcloud:X'));
    props.Callback = {@changeColor, hFigure};
    urx = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByX'); %#ok

    props.Label = getString(message('vision:pointcloud:Y'));
    ury = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByY'); %#ok

    props.Label = getString(message('vision:pointcloud:Z'));
    urz = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByZ'); %#ok

    props.Label = getString(message('vision:pointcloud:RGBColor'));
    urrgb = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByRGB'); %#ok

    props.Label = getString(message('vision:pointcloud:Intensity'));
    urintensity = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByIntensity'); %#ok

    props.Label = getString(message('vision:pointcloud:Row'));
    urrow = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByRow'); %#ok

    props.Label = getString(message('vision:pointcloud:Column'));
    urcol = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByCol'); %#ok

    props.Label = getString(message('vision:pointcloud:Range'));
    urrange = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByRange'); %#ok

    props.Label = getString(message('vision:pointcloud:Azimuth'));
    urazimuth = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByAzimuth'); %#ok

    props.Label = getString(message('vision:pointcloud:Elevation'));
    urelev = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByElevation'); %#ok

    props.Label = getString(message('vision:pointcloud:UserSpecColor'));
    uruserspec = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByUserSpecColor'); %#ok

    props.Label = getString(message('vision:pointcloud:MagentaGreen'));
    urmaggr = uimenu('Parent', urcolor, props, 'Tag', 'contextPCChangeColorByMagentaGreen'); %#ok       

else
    % Reset to default state
    udata = pointclouds.internal.pcui.utils.getAppData(hFigure.CurrentAxes, 'PCUserData');

    % Rotation center
    rotationCenterMenuItem = findall(hFigure,'tag','contextPCRotationCenter');
    udata.rotateFromCenter = true;
    rotationCenterMenuItem.Text = getString(message('vision:pointcloud:localCenterOfRotationModeDisable'));

    % Color context menu items
    urcolor = findall(hFigure,'tag','contextPCChangeColor');

    pointclouds.internal.pcui.utils.setAppData(hFigure.CurrentAxes, 'PCUserData', udata);
end

udata = pointclouds.internal.pcui.utils.getAppData(hFigure.CurrentAxes, 'PCUserData');
udata.ColorContextMenu = urcolor;
pointclouds.internal.pcui.utils.setAppData(hFigure.CurrentAxes, 'PCUserData', udata);

pointclouds.internal.pcui.updateColorContextMenu(hFigure);

end

%--------------------------------------------------------------------------
function createAxesToolbar(pcAxes, params)
tb = axtoolbar(pcAxes, {'zoomin','zoomout','rotate','pan','restoreview', 'datacursor', 'brush', 'export'},'Visible','on');

iconFolder = getIconFolder();

projection = params.Projection;
fileName = lower(projection) + "Projection_16.png";
iconFile = fullfile(iconFolder, fileName);
projDropDown = matlab.ui.controls.ToolbarDropdown;
projDropDown.Icon = iconFile;
projDropDown.Parent = tb;
projDropDown.Tag = 'Projection';

iconFile = fullfile(iconFolder, "orthographicProjection_16.png");
orthoProjBtn = matlab.ui.controls.ToolbarPushButton; 
orthoProjBtn.Icon = iconFile;
orthoProjBtn.Tooltip = getString(message("vision:pointcloud:OrthographicProjection"));
orthoProjBtn.ButtonPushedFcn = @changeToOrthographic;
orthoProjBtn.Tag = 'OrthoProjection';

iconFile = fullfile(iconFolder, "perspectiveProjection_16.png");
perspProjBtn = matlab.ui.controls.ToolbarPushButton; 
perspProjBtn.Icon = iconFile;
perspProjBtn.Tooltip = getString(message("vision:pointcloud:PerspectiveProjection"));
perspProjBtn.ButtonPushedFcn = @changeToPerspective;
perspProjBtn.Tag = 'PerspProjection';

perspProjBtn.Parent = projDropDown;
orthoProjBtn.Parent = projDropDown;

axesVisibility  = params.AxesVisibility;
iconFile = fullfile(iconFolder, "axeOn_16.png");
axesVisibilityBtn = axtoolbarbtn(tb,'state');
axesVisibilityBtn.Icon = iconFile;
axesVisibilityBtn.Value = axesVisibility;
axesVisibilityBtn.Tooltip = getString(message('vision:pointcloud:localAxisOnOff'));
axesVisibilityBtn.ValueChangedFcn = @changeAxisVisibility;
axesVisibilityBtn.Tag = 'AxesVisibility';

iconFile = fullfile(iconFolder, "background_16.png");
backgroundColorBtn = axtoolbarbtn(tb, 'push');
backgroundColorBtn.Icon = iconFile;
backgroundColorBtn.Tooltip = getString(message('vision:pointcloud:ChangeBackground'));
backgroundColorBtn.ButtonPushedFcn = @changeBackground;
backgroundColorBtn.Tag = 'BackgroundColor';

iconFile = fullfile(iconFolder, "axesView_16.png");
axesViewDropDown = matlab.ui.controls.ToolbarDropdown;
axesViewDropDown.Icon = iconFile;
axesViewDropDown.Parent = tb;

iconFile = fullfile(iconFolder, "XY.png");
xyBtn = matlab.ui.controls.ToolbarPushButton; 
xyBtn.Icon = iconFile;
xyBtn.Tooltip = getString(message('vision:pointcloud:XY'));
xyBtn.Tag = 'XY';
xyBtn.ButtonPushedFcn = @changeView;

iconFile = fullfile(iconFolder, "YX.png");
yxBtn = matlab.ui.controls.ToolbarPushButton; 
yxBtn.Icon = iconFile;
yxBtn.Tooltip = getString(message('vision:pointcloud:YX'));
yxBtn.Tag = 'YX';
yxBtn.ButtonPushedFcn = @changeView;

iconFile = fullfile(iconFolder, "XZ.png");
xzBtn = matlab.ui.controls.ToolbarPushButton; 
xzBtn.Icon = iconFile;
xzBtn.Tooltip = getString(message('vision:pointcloud:XZ'));
xzBtn.Tag = 'XZ';
xzBtn.ButtonPushedFcn = @changeView;

iconFile = fullfile(iconFolder, "ZX.png");
zxBtn = matlab.ui.controls.ToolbarPushButton; 
zxBtn.Icon = iconFile;
zxBtn.Tooltip = getString(message('vision:pointcloud:ZX'));
zxBtn.Tag = 'ZX';
zxBtn.ButtonPushedFcn = @changeView;

iconFile = fullfile(iconFolder, "YZ.png");
yzBtn = matlab.ui.controls.ToolbarPushButton; 
yzBtn.Icon = iconFile;
yzBtn.Tooltip = getString(message('vision:pointcloud:YZ'));
yzBtn.Tag = 'YZ';
yzBtn.ButtonPushedFcn = @changeView;

iconFile = fullfile(iconFolder, "ZY.png");
zyBtn = matlab.ui.controls.ToolbarPushButton; 
zyBtn.Icon = iconFile;
zyBtn.Tooltip = getString(message('vision:pointcloud:ZY'));
zyBtn.Tag = 'ZY';
zyBtn.ButtonPushedFcn = @changeView;

zyBtn.Parent = axesViewDropDown;
yzBtn.Parent = axesViewDropDown;
zxBtn.Parent = axesViewDropDown;
xzBtn.Parent = axesViewDropDown;
yxBtn.Parent = axesViewDropDown;
xyBtn.Parent = axesViewDropDown;

iconFile = fullfile(iconFolder, "verticalAxis.png");
verticalAxisDropDown = matlab.ui.controls.ToolbarDropdown;
verticalAxisDropDown.Icon = iconFile;
verticalAxisDropDown.Parent = tb;

iconFile = fullfile(iconFolder, "xUp.png");
xUpBtn = matlab.ui.controls.ToolbarPushButton; 
xUpBtn.Icon = iconFile;
xUpBtn.Tooltip = getString(message('vision:pointcloud:XUp'));
xUpBtn.Tag = 'xup';
xUpBtn.UserData.VerticalAxis = 'X';
xUpBtn.UserData.Direction = 'Up';
xUpBtn.ButtonPushedFcn = @changeVerticalAxis;

iconFile = fullfile(iconFolder, "xDown.png");
xDownBtn = matlab.ui.controls.ToolbarPushButton; 
xDownBtn.Icon = iconFile;
xDownBtn.Tooltip = getString(message('vision:pointcloud:XDown'));
xDownBtn.Tag = 'xdown';
xDownBtn.UserData.VerticalAxis = 'X';
xDownBtn.UserData.Direction = 'Down';
xDownBtn.ButtonPushedFcn = @changeVerticalAxis;

iconFile = fullfile(iconFolder, "yUp.png");
yUpBtn = matlab.ui.controls.ToolbarPushButton; 
yUpBtn.Icon = iconFile;
yUpBtn.Tooltip = getString(message('vision:pointcloud:YUp'));
yUpBtn.Tag = 'yup';
yUpBtn.UserData.VerticalAxis = 'Y';
yUpBtn.UserData.Direction = 'Up';
yUpBtn.ButtonPushedFcn = @changeVerticalAxis;

iconFile = fullfile(iconFolder, "yDown.png");
yDownBtn = matlab.ui.controls.ToolbarPushButton; 
yDownBtn.Icon = iconFile;
yDownBtn.Tooltip = getString(message('vision:pointcloud:YDown'));
yDownBtn.Tag = 'ydown';
yDownBtn.UserData.VerticalAxis = 'Y';
yDownBtn.UserData.Direction = 'Down';
yDownBtn.ButtonPushedFcn = @changeVerticalAxis;

iconFile = fullfile(iconFolder, "zUp.png");
zUpBtn = matlab.ui.controls.ToolbarPushButton; 
zUpBtn.Icon = iconFile;
zUpBtn.Tooltip = getString(message('vision:pointcloud:ZUp'));
zUpBtn.Tag = 'zup';
zUpBtn.UserData.VerticalAxis = 'Z';
zUpBtn.UserData.Direction = 'Up';
zUpBtn.ButtonPushedFcn = @changeVerticalAxis;

iconFile = fullfile(iconFolder, "zDown.png");
zDownBtn = matlab.ui.controls.ToolbarPushButton; 
zDownBtn.Icon = iconFile;
zDownBtn.Tooltip = getString(message('vision:pointcloud:ZDown'));
zDownBtn.Tag = 'zdown';
zDownBtn.UserData.VerticalAxis = 'Z';
zDownBtn.UserData.Direction = 'Down';
zDownBtn.ButtonPushedFcn = @changeVerticalAxis;

zDownBtn.Parent = verticalAxisDropDown;
zUpBtn.Parent = verticalAxisDropDown;
yDownBtn.Parent = verticalAxisDropDown;
yUpBtn.Parent = verticalAxisDropDown;
xDownBtn.Parent = verticalAxisDropDown;
xUpBtn.Parent = verticalAxisDropDown;

end

%--------------------------------------------------------------------------
% Rotation Callbacks
%--------------------------------------------------------------------------
function localBtnDown(src,evtData,hFigure,vertAxis,vertAxisDir)

currentAxes = hFigure.CurrentAxes;

isPointCloudAxes = strcmp(currentAxes.Tag, 'PointCloud');
isGeoAxes        = isa(currentAxes,'matlab.graphics.axis.GeographicAxes'); % g2409093

hui = getuimode(hFigure, 'Exploration.Rotate3D');

switch src.SelectionType
    case {'normal', 'extend'} % Handle rotation
        if isGeoAxes
            return;
        end

        % Trigger pre-action callback for rotate3d
        evd.Axes = currentAxes;
        hui.fireActionPreCallback(evd);

        if isPointCloudAxes
            rotationCenter = changeCenterOfRotation(currentAxes);
        else
            % In the case of multiple axes in the same figure, reproduce standard
            % behavior for non-point cloud data unless it's geoaxes.
            rotationCenter = [mean(currentAxes.XLim), mean(currentAxes.YLim), mean(currentAxes.ZLim)];
        end

        hObj = rotate3d(currentAxes);
        flag = isAllowAxesRotate(hObj,currentAxes);

        % If the user clicks on any of the graphics object inside the
        % figure (axes,scatter3 etc), rotation is allowed. Rotation is
        % disabled, if the click was only on figure and not on any of the
        % graphics objects. This behavior is to support subplots, where
        % rotation in one axes should not influence the other axes. Once we
        % move to webgraphics and camera interactions are also moved to the
        % web, this check can be removed.
        wasClickNotInFigure = ~isgraphics(evtData.HitObject, 'figure');

        if flag && wasClickNotInFigure
            src.WindowButtonMotionFcn = {@localRotate,hFigure,vertAxis,vertAxisDir,rotationCenter};
        end

    case {'alt'} % right click for sub-menu

        rotateAroundPointEntry = findall(hui.UIContextMenu, 'tag', 'contextPCRotationCenter');
        if ~isempty(rotateAroundPointEntry)
            if isPointCloudAxes
                rotateAroundPointEntry.Enable = 'on';

                % Set the text based on current state
                udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
                if udata.rotateFromCenter
                    rotateAroundPointEntry.Text = getString(message('vision:pointcloud:localCenterOfRotationModeDisable'));
                else
                    rotateAroundPointEntry.Text = getString(message('vision:pointcloud:localCenterOfRotationModeEnable'));
                end
            else
                % Gray out center of rotation change option for non-point
                % cloud data
                rotateAroundPointEntry.Enable = 'off';
                rotateAroundPointEntry.Text = getString(message('vision:pointcloud:localCenterOfRotationModeDisable'));
            end
        end

        changeColorEntry = findall(hui.UIContextMenu, 'tag', 'contextPCChangeColor');
        if ~isempty(changeColorEntry)
            if isPointCloudAxes
                changeColorEntry.Enable = 'on';
            else
                % Gray out color selections for non-point cloud data
                changeColorEntry.Enable = 'off';
            end
        end
end
end

%--------------------------------------------------------------------------
function localBtnUp(src,~)
% Trigger post-action callback for rotate3d
hui = getuimode(src, 'Exploration.Rotate3D');
evd.Axes = src.CurrentAxes;
hui.fireActionPostCallback(evd);
end

%--------------------------------------------------------------------------
function localRotate(src,~,hFigure,vertAxis,vertDir,rotCenter)

currentAxes = hFigure.CurrentAxes;
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
if ~isfield(udata,'pcshowMouseData')
    return;
end

if isempty(udata.pcshowMouseData)
    udata.pcshowMouseData = hFigure.CurrentPoint;
    pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
end
% Previous mouse position
hData = udata.pcshowMouseData;

% Grab current mouse point in pixels
pt = hgconvertunits(src,[0 0 src.CurrentPoint],...
    src.Units,'pixels',src.Parent);
pt = pt(3:4);

% Change in mouse position
deltaPix  = -(pt-hData);

% Update mouse position
udata.pcshowMouseData = pt;
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);

pointclouds.internal.pcui.rotateAxes(currentAxes,deltaPix(1),deltaPix(2),rotCenter,...
    vertAxis,vertDir);
end

%--------------------------------------------------------------------------
function localRotateStartMode(hFigure)
% Rotate mode starts, click the button
localToggleRotateState(hFigure,'on');
end

%--------------------------------------------------------------------------
function localRotateStopMode(hFigure)
% Rotate mode stop
localToggleRotateState(hFigure,'off');
end

%--------------------------------------------------------------------------
function localToggleRotateState(hFigure,state)

% pop back the button, uncheck the menu entry
btn = findall(hFigure,'tag','Exploration.Rotate', 'Type', 'uitoggletool');
if ~isempty(btn)
    btn.State = state;
end

rmenu = findall(hFigure,'tag','figMenuRotate3D');
if ~isempty(rmenu)
    rmenu.Checked = state;
end
end

%--------------------------------------------------------------------------
function localPointerChange(obj,~)
% Change the icon to indicate the rotation
if strcmpi(obj.Pointer,'custom')
    %We already have custom icon
    return;
end
SetData = setptr('rotate');
set(obj, SetData{:});
end

%--------------------------------------------------------------------------
% Rotation utilities
%--------------------------------------------------------------------------
function rotationCenter = changeCenterOfRotation(currentAxes)

currentPoint = get(currentAxes, 'CurrentPoint');

udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

if ~(udata.rotateFromCenter) && currentPointWithinLimits(currentAxes, currentPoint(1,:))

    % Check if it is within the data limits

    frontPoint = currentPoint(1,:);
    backPoint = currentPoint(2,:);

    plotHandle = findall(currentAxes,'Tag', 'pcviewer');

    points = [];
    for i = 1:numel(plotHandle)
        tempPoints = [ plotHandle(i).XData' plotHandle(i).YData' plotHandle(i).ZData'];
        points = [points; tempPoints]; %#ok<AGROW>
    end

    % Find the distance of each point to the line passing through the
    % front and back face of the axes.
    diff1 = frontPoint - backPoint;
    diff1 = repmat(diff1, size(points,1), 1);
    diff2 = points - backPoint;

    crossP = cross(diff1,diff2);
    numerator = sqrt(sum((crossP.^2),2));
    denom = sqrt(sum((diff1.^2),2));

    d = numerator ./ denom;

    minLimit = min(udata.dataLimits);
    maxLimit = max(udata.dataLimits);

    distanceThreshold = 2.5 * (maxLimit - minLimit) / 100;

    withinDataLimits = min(d) < distanceThreshold;

    if withinDataLimits
        [~, I] = sort(d);
        % Select the first five closest points to the line
        if numel(I) > 5
            top5Idx = I(1:5);
        else
            top5Idx = I;
        end
        top5Points = points(top5Idx,:);
        % Find out he closest point to the point on the front face of
        % axes
        [~, idx] = min(sqrt(sum((top5Points - frontPoint) .^ 2, 2)));
        rotationCenter = points(I(idx),:);

    else
        % If there are no points within a distace of the click, the
        % rotation center is at a fixed distance from the point
        % clicked.
        moveDistance = 0.2;
        rotationCenter = ((1-moveDistance)* currentPoint(1,:)) + moveDistance * (currentPoint(2,:));
    end
else
    Xc = mean(currentAxes.XLim);
    Yc = mean(currentAxes.YLim);
    Zc = mean(currentAxes.ZLim);
    rotationCenter = [Xc,Yc,Zc];
end
end

%--------------------------------------------------------------------------
function TF = currentPointWithinLimits(currentAxes, currentPoint)

% Adding eps for the limit calculation to ensure that when the upper limit
% is the same as the current point clicked, the rotation center does not
% default to the center of the axes. Since the user is cliking on a 3d
% scene on a 2d screen, the current point clicked can have a value equal to
% the upper axis limit (g2518345)
TF =  (currentPoint(1,1) >= currentAxes.XLim(1)) && (currentPoint(1,1) <= currentAxes.XLim(2)+2*eps) ...
    && (currentPoint(1,2) >= currentAxes.YLim(1)) && (currentPoint(1,2) <= currentAxes.YLim(2)+2*eps)...
    && (currentPoint(1,3) >= currentAxes.ZLim(1)) && (currentPoint(1,3) <= currentAxes.ZLim(2)+2*eps);

end

%--------------------------------------------------------------------------
% Context menu callbacks
%--------------------------------------------------------------------------
function changeCenterOfRotationMode(~, ~, hFigure)

currentAxes = hFigure.CurrentAxes;

udata = pointclouds.internal.pcui.utils.getAppData(hFigure.CurrentAxes, 'PCUserData');

if udata.rotateFromCenter
    udata.rotateFromCenter = false;
else
    udata.rotateFromCenter = true;
end
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);

end


%--------------------------------------------------------------------------
function changeColor(src, ~, hFigure)

colorSource = pointclouds.internal.pcui.getColorSourceString(src.Text);
pointclouds.internal.pcui.changeColor(hFigure, colorSource);

currentAxes = hFigure.CurrentAxes;
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
udata.colorMapData = colorSource;
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
% add labels to the colorbar for pointcloud Viewer block
if ~isempty(hFigure.UserData) && isequal(class(hFigure.UserData), 'matlabshared.scopes.UnifiedScope') && isequal(class(hFigure.UserData.Visual), 'vipscopes.PointCloudVisual')
    name = char(colorSource);
    labelName = string(replace(name,name(1),upper(name(1)))); % caplitalize the first letter
    set(hFigure.UserData.Visual.Colormap.Label, 'String', labelName);
end

end

%--------------------------------------------------------------------------
% Axes toolbar callbacks
%--------------------------------------------------------------------------
function changeAxisVisibility(~, evtData)

currentAxes = evtData.Axes;

if strcmpi(currentAxes.Visible, 'on')
    currentAxes.Visible = 'off';
else
    currentAxes.Visible = 'on';
end
end

%--------------------------------------------------------------------------
function changeView(src, evtData)

currentAxes = evtData.Axes;
pointclouds.internal.pcui.setView(src.Tag, currentAxes);

end

%--------------------------------------------------------------------------
function changeBackground(~, evtData)

currentAxes = evtData.Axes;

hFigure = ancestor(currentAxes, 'figure');

color = uisetcolor;

setBackgroundColor(hFigure, hFigure.CurrentAxes, color);

end

%--------------------------------------------------------------------------
function setBackgroundColor(hFigure, ax, color)

if sum(color) < 1
    tickColor = [0.8 0.8 0.8];
else
    tickColor = [0 0 0];
end

if ~isscalar(color)
    hFigure.Color  = color;
    ax.Color       = color;
    ax.XColor      = tickColor;
    ax.YColor      = tickColor;
    ax.ZColor      = tickColor;
    ax.Title.Color = tickColor;
end
end


%--------------------------------------------------------------------------
function changeToPerspective(src, evtData)

currentAxes = evtData.Axes;

setProjection(currentAxes, 'perspective');

projDropDown = src.Parent;

iconFolder = getIconFolder();
iconFile = fullfile(iconFolder, "perspectiveProjection_16.png");
projDropDown.Icon = iconFile;
end

%--------------------------------------------------------------------------
function changeToOrthographic(src,evtData)

currentAxes = evtData.Axes;

setProjection(currentAxes, 'orthographic');

projDropDown = src.Parent;

iconFolder = getIconFolder();
iconFile = fullfile(iconFolder, "orthographicProjection_16.png");
projDropDown.Icon = iconFile;

end

%--------------------------------------------------------------------------
function setProjection(currentAxes, projection)
camproj(currentAxes, projection);
end

%--------------------------------------------------------------------------
function changeVerticalAxis(src, evtData)

currentAxes = evtData.Axes;

vertAxis = src.UserData.VerticalAxis;
vertAxisDir = src.UserData.Direction;

pointclouds.internal.pcui.initializeVerticalAxis(currentAxes, vertAxis, vertAxisDir);

end

%--------------------------------------------------------------------------
% Keypress Callbacks
%--------------------------------------------------------------------------
function processKeyPress(hFigure, evtData)

keyPressed = evtData.Key;
keyModifier = evtData.Modifier;
keyBindings = pointclouds.internal.pcui.getCurrentKeyBindings();
stepProps = pointclouds.internal.pcui.getDefaultStepProps();

pointclouds.internal.pcui.pcKeyBoardShortcuts(hFigure, keyBindings, keyPressed,...
    keyModifier, stepProps)
end

%--------------------------------------------------------------------------
function processKeyRelease(hFigure, evtData)

currentAxes = hFigure.CurrentAxes;
keyPressed = evtData.Key;
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

keyBindings = pointclouds.internal.pcui.getCurrentKeyBindings();

if (keyPressed == keyBindings("SwitchToPan")) && udata.SwitchedFromRotate

    hManager = uigetmodemanager(hFigure);
    
    if ~isempty(hManager.CurrentMode) && ...
            strcmp(hManager.CurrentMode.Name, 'Exploration.Pan')
        zoom(currentAxes,'off');
        pan(currentAxes,'off');
        rotate3d(currentAxes,'on');
        udata.SwitchedFromRotate = false;
    end
elseif keyPressed == keyBindings("RotateFromPoint")
    if isfield(udata,'changeModeOnRelease') && udata.changeModeOnRelease
        udata.rotateFromCenter = true;
        pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
    end
end
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);

end

%--------------------------------------------------------------------------
function processFigKeyRelease(hFigure, evtData)

currentAxes = hFigure.CurrentAxes;
keyPressed = evtData.Key;

keyBindings = pointclouds.internal.pcui.getCurrentKeyBindings();

if keyPressed == keyBindings("RotateByThirdAxis")
    rotate3d(currentAxes,'on');
end
end

%--------------------------------------------------------------------------
% Data cursor callback
%--------------------------------------------------------------------------
function txt = dataCursorCallback(~, eventObj)

ptCloud = pointclouds.internal.pcui.utils.getAppData(eventObj.Target, 'PointCloud');

pos = get(eventObj,'Position');

txt = {['X: ',num2str(pos(1))],...
    ['Y: ',num2str(pos(2))],...
    ['Z: ',num2str(pos(3))]};


if ~isempty(ptCloud) && isa(ptCloud, 'pointCloud')

    isOrganized = ~ismatrix(ptCloud.Location);

    dataIndex = get(eventObj,'DataIndex');

    if ~isOrganized
        index = dataIndex;
    else
        [i,j] = ind2sub(size(ptCloud.Location), dataIndex);
        index = [i j];
    end

    if ~isempty(ptCloud.Color)
        if isOrganized
            colorValue = ptCloud.Color(index(1), index(2), :);
        else
            colorValue = ptCloud.Color(index, :);
        end
        txt{end+1} = ['Color: ', num2str(colorValue)];
    end

    if ~isempty(ptCloud.Normal)
        if isOrganized
            normalValue = ptCloud.Normal(index(1), index(2), :);
        else
            normalValue = ptCloud.Normal(index, :);
        end
        txt{end+1} = ['Normal: ', num2str(normalValue)];
    end

    if ~isempty(ptCloud.Intensity)
        intensity = ptCloud.Intensity(dataIndex);
        txt{end+1} = ['Intensity: ', num2str(intensity)];
    end

    if isOrganized
        txt{end+1} = ['Row: ', num2str(index(1))];
        txt{end+1} = ['Column: ', num2str(index(2))];
    end

    if ~isempty(ptCloud.RangeData)
        if isOrganized
            rangeData = ptCloud.RangeData(index(1), index(2), :);
        else
            rangeData = ptCloud.RangeData(index, :);
        end
        range = rangeData(1);
        verticalAngle = rangeData(2);
        azimuth = rangeData(3);

        txt{end+1} = ['Range: ', num2str(range)];
        txt{end+1} = ['Vertical Angle: ', num2str(verticalAngle)];
        txt{end+1} = ['Azimuth Angle: ', num2str(azimuth)];
    end
end

end

%--------------------------------------------------------------------------
% Other Callbacks - Unset mouse motion
%--------------------------------------------------------------------------
function resetWindowMotion(src,objectClicked)
% Unset mouse motion callback

currentAxes = get(src,'CurrentAxes');
if isa(currentAxes, 'matlab.graphics.axis.GeographicAxes')
    % g2409093
    return;
end

src.WindowButtonMotionFcn = '';

if isLocallyImplementedMode(src, objectClicked)

    udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
    udata.newDataLimits = [currentAxes.XLim currentAxes.YLim currentAxes.ZLim];

    plotHandles = findall(src,'Tag', 'pcviewer');

    if isempty(plotHandles)
        % no  point cloud data available
        return;
    end

    udata.pcshowMouseData = [];
    needsDownsample = udata.pcNeedsDownsample;
    pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
    if needsDownsample
        % Restore all Scatter3 Object

        for i = 1:numel(plotHandles)
            ptCloud = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'PointCloud');
            count = ptCloud.Count;

            plotHandles(i).XData = ptCloud.Location(1:count);
            plotHandles(i).YData = ptCloud.Location(count+1:count*2);
            plotHandles(i).ZData = ptCloud.Location(count*2+1:end);
            plotHandles(i).CData = ptCloud.Location(count*2+1:end)';
        end

        udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
        pointclouds.internal.pcui.changeColor(src, udata.colorMapData);
    end
end
end

%--------------------------------------------------------------------------
% Downsample
%--------------------------------------------------------------------------
function localDownsample(hFigure,objectClicked,ptCloudThreshold)
% Perform downsampling in current Axes

currentAxes = get(hFigure,'CurrentAxes');
if isa(currentAxes, 'matlab.graphics.axis.GeographicAxes')
    % g2409093
    return;
end

if isLocallyImplementedMode(hFigure, objectClicked)

    plotHandles = findall(hFigure,'Tag', 'pcviewer');

    if isempty(plotHandles)
        % no  point cloud data available
        return;
    end

    % Determine if current axes needs downsample
    localSetDownsample(currentAxes,ptCloudThreshold);

    % Perform downsample on all scatter3 and plot3 objects
    udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');

    needsDownsample = udata.pcNeedsDownsample;

    % Handle datacursormode
    dcm_obj = datacursormode(hFigure);
    cInfo = getCursorInfo(dcm_obj);

    % We do not downsample when there are datatips. The datatip relies on
    % the linear index of its underlying data, this will change when we
    % downsample the points.

    hasDatatip = ~isempty(cInfo);

    % only needs to check isempty(pccache)
    if ~isempty(needsDownsample) &&  needsDownsample ...
            && ~hasDatatip
        
        % Downsample
        for i = 1:numel(plotHandles)
            ptcloud = pointclouds.internal.pcui.utils.getAppData(plotHandles(i), 'PointCloud');
            K = min(round(ptcloud.Count*0.5),ptCloudThreshold(1));
            indices = pointclouds.internal.pcui.samplingWithoutReplacement(ptcloud.Count, K);
            if max(indices(:)) > numel(plotHandles(i).XData)
                % Renderer is not ready yet.
                continue;
            end
            plotHandles(i).XData = plotHandles(i).XData(indices);
            plotHandles(i).YData = plotHandles(i).YData(indices);
            plotHandles(i).ZData = plotHandles(i).ZData(indices);
            if numel(plotHandles(i).CData) > 3
                plotHandles(i).CData = plotHandles(i).CData(indices,:);
            end
        end
    end
end
end

%--------------------------------------------------------------------------
function localSetDownsample(currentAxes,ptCloudThreshold)
% Determine if current axes needs downsample

plotHandles = findall(currentAxes,'Tag', 'pcviewer');

% Adaptive Downsample:
needsDownsample = false;
numData  = 0;

if ~isempty(plotHandles)
    numData = numel([plotHandles.XData]);
end

if numData > ptCloudThreshold(1) && numData < ptCloudThreshold(2)
    needsDownsample = true;
end
udata = pointclouds.internal.pcui.utils.getAppData(currentAxes, 'PCUserData');
udata.pcNeedsDownsample = needsDownsample;
pointclouds.internal.pcui.utils.setAppData(currentAxes, 'PCUserData', udata);
end

%--------------------------------------------------------------------------
% Utilities
%--------------------------------------------------------------------------
function isLocal = isLocallyImplementedMode(hFigure, objectClicked)
% Decide if we are in rotate/pan/zoom mode

hManager = uigetmodemanager(hFigure);

isLeftOrMiddleClick = (strcmpi(hFigure.SelectionType,'normal') ||...
    strcmpi(hFigure.SelectionType,'extend'));

isCurrentUIModeSupported = ~isempty(hManager.CurrentMode) ...
    && ismember(hManager.CurrentMode.Name,...
    {'Exploration.Rotate3d','Exploration.Pan','Exploration.Zoom'});

isButton = isa(objectClicked, 'matlab.graphics.shape.internal.Button');

isLocal = isLeftOrMiddleClick && isCurrentUIModeSupported && ~isButton;
end

%--------------------------------------------------------------------------
function c = crossSimple(a,b)
% simple cross product

c(1) = b(3)*a(2) - b(2)*a(3);
c(2) = b(1)*a(3) - b(3)*a(1);
c(3) = b(2)*a(1) - b(1)*a(2);
end

%--------------------------------------------------------------------------
function enableCameraPanZoomMode(currentAxes)
% Limit Pan/Zoom mode is not suitable for Point Cloud application

z = zoom(currentAxes);
z.setAxes3DPanAndZoomStyle(currentAxes,'camera');
end

%--------------------------------------------------------------------------
function iconFolder = getIconFolder()
iconFolder = fullfile(toolboxdir('shared'), 'pointclouds', '+pointclouds', '+internal', '+pcui', '+icons');
end

%--------------------------------------------------------------------------
% Cleanup
%--------------------------------------------------------------------------
function cleanupPCSceneControl(hSrc, ~)

hFigure = ancestor(hSrc, 'figure');

if isempty(hFigure) || ~isvalid(hFigure)
    return;
end

hui = getuimode(hFigure, 'Exploration.Rotate3d');

if ~isempty(hui)
    set(hui, 'WindowButtonDownFcn',   {});
    set(hui, 'WindowScrollWheelFcn',  {});
    set(hui, 'WindowButtonMotionFcn', {});

    set(hui,'ModeStartFcn', {});
    set(hui,'ModeStopFcn',  {});

    % Do not allow keyboard interaction
    set(hui,'KeyReleaseFcn', {});
    set(hui,'KeyPressFcn',   {});

    delete(hui.UIContextMenu);

    unregisterMode(hFigure.ModeManager,hui);
end

dcmObj = datacursormode(hFigure);
set(dcmObj, 'UpdateFcn', {});

end

