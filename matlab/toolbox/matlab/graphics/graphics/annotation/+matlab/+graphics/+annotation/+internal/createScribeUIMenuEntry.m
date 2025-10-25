function entry = createScribeUIMenuEntry(hCallbackParent,hParent,menuType,displayText,propName,undoName,actionCodeGen,varargin)
% Create a scribe entry for a UIContextMenu
% hCallbackParent - The object to use in callbacks
% hParent - The parent to use to contain the menu item. This is often the
% same as the hCallbackParent but it can be specified separately when
% using a temporary parent
% menuType - String representing the
%            expected result of calling the menu.
% displayText - The text to be displayed in the menu.
% propName - The name of the property being modified.
% undoName - The string to be shown in the undo menu

%   Copyright 2006-2023 The MathWorks, Inc.

import matlab.internal.capability.Capability;
isMOTW = ~Capability.isSupported(Capability.LocalClient);

yes = matlab.internal.environment.context.isMATLABOnline || isMOTW || feature('webui');
if ~exist('actionCodeGen','var') || ~yes
    actionCodeGen = NaN;
end

switch menuType
    case 'CapSize'
        entry = localCreateCapSizeEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'Color'
        entry = localCreateColorEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'LineWidth'
        entry = localCreateLineWidthEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'LineStyle'
        entry = localCreateLineStyleEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'HeadStyle'
        entry = localCreateHeadStyleEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'HeadSize'
        entry = localCreateHeadSizeEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'AddData'
        entry = localCreateAddDataEntry(hCallbackParent,hParent,displayText);
    case 'LegendToggle'
        entry = localCreateLegendToggleEntry(hCallbackParent,hParent,displayText);
    case 'Toggle'
        entry = localCreateToggleEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'Marker'
        entry = localCreateMarkerEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'MarkerSize'
        entry = localCreateMarkerSizeEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'EditText'
        entry = localCreateEditTextEntry(hCallbackParent,hParent,displayText);
    case 'Font'
        entry = localCreateFontEntry(hCallbackParent,hParent,displayText,propName,undoName);
    case 'TextInterpreter'
        entry = localCreateTextInterpreterEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'CloseFigure'
        entry = localCreateCloseFigureEntry(hCallbackParent,hParent,displayText);
    case 'BarWidth'
        entry = localCreateBarWidthEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'BarLayout'
        entry = localCreateBarLayoutEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'AutoScaleFactor'
        entry = localCreateAutoScaleFactorEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'EnumEntry'
        entry = localCreateEnumEntry(hCallbackParent,hParent,displayText,propName,varargin{:},undoName,actionCodeGen);
    case 'CustomEnumEntry'
        entry = localCreateCustomEnumEntry(hCallbackParent,hParent,displayText,propName,varargin{:});        
    case 'GeneralAction'
        entry = localCreateActionEntry(hCallbackParent,hParent,displayText,varargin{:});
    case 'DisplayStyle'
        entry = localCreateDisplayStyleEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'DisplayStyle2D'
        entry = localCreateDisplayStyle2DEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);   
    case 'morebins'
        entry = localCreateMoreFewerbinsEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'fewerbins'
        entry = localCreateMoreFewerbinsEntry(hCallbackParent,hParent,displayText,propName,undoName,actionCodeGen);
    case 'morebins2D'
        entry = localCreateMoreFewerbins2DEntry(hCallbackParent,hParent,displayText,propName);
    case 'fewerbins2D'
        entry = localCreateMoreFewerbins2DEntry(hCallbackParent,hParent,displayText,propName);
    case 'DisplayOrder'
        entry = localCreateDisplayOrderEntry(hCallbackParent,hParent,displayText,propName);
    case 'AlignBins'
        entry = localCreateAlignBinsEntry(hCallbackParent,hParent,displayText,undoName);
end

%----------------------------------------------------------------------%
function entry = localCreateActionEntry(~,hParent,displayText,callbackFunction)

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',callbackFunction);

%----------------------------------------------------------------------%
function entry = localCreateAutoScaleFactorEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of scale sizes

values = [.2,.3,.4,.5,.7,.9,1.0];
format = '%1.1f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateBarWidthEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of bar width sizes

values = [.2,.3,.4,.5,.6,.7,.8,.9,1.0];
format = '%1.1f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateBarLayoutEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that is linked to text interpreters

descriptions = {getString(message('MATLAB:uistring:scribemenu:Grouped')),getString(message('MATLAB:uistring:scribemenu:Stacked'))};
values = {'grouped','stacked'};

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateCloseFigureEntry(hFig,hParent,displayText)
% Create a uimenu that closes the figure

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localCloseFigure,hFig});

%----------------------------------------------------------------------%
function localCloseFigure(~,~,hParent) 
% Close the figure

close(localGetFigure(hParent));

%----------------------------------------------------------------------%
function entry = localCreateTextInterpreterEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that is linked to text interpreters

descriptions = cellfun(@(x)getString(message(['MATLAB:uistring:scribemenu:' x ])),{'latex','tex','none'},'UniformOutput',false);
values = {'latex','tex','none'};

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values, undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateFontEntry(hFig,hParent,displayText,propName,undoName) %#ok<INUSL>
% Create a uimenu that brings up a font picker.

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localExecuteFontCallback',hFig,undoName});

%----------------------------------------------------------------------%
function entry = localCreateEditTextEntry(hFig,hParent,displayText)
% Create a uimenu that sets text into edit mode

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localEditText,hFig});

%----------------------------------------------------------------------%
function localEditText(~,~,hParent)
% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.

hFig = localGetFigure(hParent);
if isactiveuimode(hFig,'Standard.EditPlot')
    hPlotEdit = plotedit(hFig,'getmode');
    hMode = hPlotEdit.ModeStateData.PlotSelectMode;
    hObj = hMode.ModeStateData.SelectedObjects;
else
    hObj = hittest(hFig);
end
% Create a one shot listener to the "Edit" option in context menu
% when editing stops
tempListenerProp = findprop(hObj,'TempEditingListener');
if isempty(tempListenerProp)
    tempListenerProp = addprop(hObj,'TempEditingListener');
    tempListenerProp.Transient = true;
    tempListenerProp.Hidden = true;
end
hObj.TempEditingListener = event.proplistener(hObj, hObj.findprop('Editing'), 'PostSet', @(~,~) EditCodeGenCallback(hObj));
set(hObj,'Editing','on');

%----------------------------------------------------------------------%
function EditCodeGenCallback(hObj)
if  hObj.Editing =='off'
    delete(hObj.TempEditingListener);
    hObj.TempEditingListener= [];
    matlab.graphics.internal.propertyinspector.generatePropertyEditingCode(hObj, {'String'});
end

%----------------------------------------------------------------------%
function entry = localCreateMarkerSizeEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of marker sizes

values = [2,4,5,6,7,8,10,12,18,24,48];
format = '%1.0f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateHeadSizeEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of marker sizes

values = [6,8,10,12,15,20,25,30,40];
format = '%2.0f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateCapSizeEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of cap sizes

values = [6,9,12,15,18,24,30,36,48,60,72];
format = '%1.0f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateMarkerEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Creates a uimenu that represents marker types

descriptions = {'+','o','*','.','x',getString(message('MATLAB:uistring:scribemenu:square')),getString(message('MATLAB:uistring:scribemenu:diamond')),'v','^','>','<',getString(message('MATLAB:uistring:scribemenu:pentagram')),getString(message('MATLAB:uistring:scribemenu:hexagram')),getString(message('MATLAB:uistring:scribemenu:none'))};
values = {'+','o','*','.','x','square','diamond','v','^','>','<','pentagram','hexagram','none'};
isActionCodeGenString = isstring(actionCodeGen);
if isActionCodeGenString
    actionCodeGen = containers.Map(values, ...
        {"motw.embeddedfigures.lineMarker.plus", "motw.embeddedfigures.lineMarker.circle", ...
        "motw.embeddedfigures.lineMarker.asterisk", "motw.embeddedfigures.lineMarker.point", ...
        "motw.embeddedfigures.lineMarker.cross","motw.embeddedfigures.lineMarker.square", ...
        "motw.embeddedfigures.lineMarker.diamond", "motw.embeddedfigures.lineMarker.v", ...
        "motw.embeddedfigures.lineMarker.hat", "motw.embeddedfigures.lineMarker.gt", ...
        "motw.embeddedfigures.lineMarker.lt","motw.embeddedfigures.lineMarker.pentagram", ...
        "motw.embeddedfigures.lineMarker.hexagram","motw.embeddedfigures.lineMarker.none"});
end

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values,undoName,actionCodeGen);


%----------------------------------------------------------------------%
function entry = localCreateToggleEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Creates a uimenu that sets a property to "on" or "off" 

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localToggleValue,hFig,propName,undoName,actionCodeGen});

%----------------------------------------------------------------------%
function localToggleValue(obj,evd,hParent,propName,undoName,actionCodeGen)
% Sets the toggle value

% If we are going to generate code for this menu item, use the FigureToolstripActionfacotry to 
% provide a unified backend. Otherwise use the existing pattern
if ~exist('actionCodeGen','var') || ~isstring(actionCodeGen)
    % The value to set is the "Checked" property 
    if strcmpi(get(obj,'Checked'),'on')
        checkValue = 'off';
    else
        checkValue = 'on';
    end
    
    matlab.graphics.annotation.internal.scribeContextMenuCallback(obj,evd,'localUpdateValue',localGetFigure(hParent),propName,checkValue,undoName, NaN);
else
    factory = matlab.graphics.internal.toolstrip.FigureToolstripActionFactory.getInstance();
    factory.executeAction(actionCodeGen);
end

%----------------------------------------------------------------------%
function entry = localCreateLegendToggleEntry(hFig,hParent,displayText)
% Create a uimenu entry that toggles a legend.

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localToggleLegend,hFig});

%----------------------------------------------------------------------%
function localToggleLegend(~,~,hParent)
% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hFig = localGetFigure(hParent);
if isactiveuimode(hFig,'Standard.EditPlot')
    hPlotEdit = plotedit(hFig,'getmode');
    hMode = hPlotEdit.ModeStateData.PlotSelectMode;
    hObj = hMode.ModeStateData.SelectedObjects;
else
    hObj = hittest(hFig);
end

for i=1:length(hObj)
    legend(double(hObj(i)),'Toggle');
end

%----------------------------------------------------------------------%
function entry = localCreateAddDataEntry(hFig,hParent,displayText)
% Create the menu entry which adds data to an axes.

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localAddData,hFig});

%----------------------------------------------------------------------%
function localAddData(~,~,hParent)
% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hFig = localGetFigure(hParent);
if isactiveuimode(hFig,'Standard.EditPlot')
    hPlotEdit = plotedit(hFig,'getmode');
    hMode = hPlotEdit.ModeStateData.PlotSelectMode;
    hObj = hMode.ModeStateData.SelectedObjects;
else
    hObj = hittest(hFig);
end

adddatadlg(hObj, hFig);

%----------------------------------------------------------------------%
function entry = localCreateLineStyleEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of line styles

descriptions = cellfun(@(x)getString(message(['MATLAB:uistring:scribemenu:' x ])),{'solid','dash','dot','dash_dot','none'},'UniformOutput',false);
values = {'-','--',':','-.','none'};
isActionCodeGenString = isstring(actionCodeGen);
if isActionCodeGenString
    actionCodeGen = containers.Map(values, ...
        {"motw.embeddedfigures.lineStyle.solid", "motw.embeddedfigures.lineStyle.dashed", ...
        "motw.embeddedfigures.lineStyle.dotted", "motw.embeddedfigures.lineStyle.dashdot", ...
        "motw.embeddedfigures.lineStyle.none"});
end

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateHeadStyleEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of line styles

descriptions = cellfun(@(x)getString(message(['MATLAB:uistring:scribemenu:' x ])),{'None_2','Plain','V_Back','C_Back','Diamond_2','Deltoid'},'UniformOutput',false);
values = {'none','plain','vback2','cback2','diamond','deltoid'};

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values,undoName,actionCodeGen)
% General helper function for enumerated types

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localUpdateEnumCheck,hFig,propName,descriptions,values});
for k=1:length(values)
    if isequal(class(actionCodeGen),'containers.Map')
        actionCodeGenString = actionCodeGen(values{k});
    else
        actionCodeGenString = actionCodeGen;
    end
    uimenu(entry,...
        'HandleVisibility','off',...
        'Label',descriptions{k},...
        'Separator','off',...
        'Visible','off',...
        'Tag', [propName '.Item' num2str(k)], ...
        'Callback',{@localScribeContextMenuCallback,'localUpdateValue',hFig,propName,values{k},undoName,actionCodeGenString});
end

%----------------------------------------------------------------------%
function entry = localCreateCustomEnumEntry(hFig,hParent,displayText,propName,descriptions,values,callback)
% General helper function for enumerated types

if ~iscell(callback)
    callback = {callback};
end

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localUpdateEnumCheck,hFig,propName,descriptions,values});
for k=1:length(values)
    uimenu(entry,...
        'HandleVisibility','off',...
        'Label',descriptions{k},...
        'Separator','off',...
        'Visible','off',...
        'Tag', [propName '.Item' num2str(k)], ...
        'Callback',[callback,{hFig,values{k}}]);
end

%----------------------------------------------------------------------%
function localUpdateEnumCheck(obj,evd,hParent,propName,descriptions,values) %#ok<INUSL>
% For uimenu entries with children, make sure the proper one is checked

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.

hFig = localGetFigure(hParent);

hObjs = matlab.graphics.annotation.internal.getMenuTargetObjects(hFig, obj);

value = get(hObjs(end),propName);
location = strcmpi(value,values);
if any(location)
    label = descriptions{strcmpi(value,values)};
    menus = findall(obj,'Label',label);
    hPar = get(menus(1),'Parent');
else
    menus = [];
    hTemp = findall(obj,'Label',descriptions{1});
    hPar = get(hTemp(1),'Parent');
end
hSibs = findall(hPar);
set(hSibs(2:end),'Checked','off');
set(menus,'Checked','on');

%----------------------------------------------------------------------%
function entry = localCreateLineWidthEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of line widths

values = [.5,1:1:12];
format = '%1.1f';

entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateNumEntry(hFig,hParent,displayText,propName,values,format,undoName,actionCodeGen)
% General helper function for menus with numeric values.
entry=uimenu(hParent,...
         'HandleVisibility','off',...
         'Label',displayText,...
         'Visible','off',...
         'Callback',{@localUpdateCheck,hFig,propName,format});     
for k=1:length(values)
  uimenu(entry,...
         'HandleVisibility','off',...
         'Label',sprintf(format,values(k)),...
         'Separator','off',...
         'Visible','off',...
         'Tag', [propName '.Item' num2str(k)], ...
         'Callback',{@localScribeContextMenuCallback,'localUpdateValue',hFig,propName,values(k),undoName,actionCodeGen});
     
     
end

%----------------------------------------------------------------------%
function localUpdateCheck(obj,evd,hParent,propName,format) %#ok<INUSL>
% For uimenu entries with children, make sure the proper one is checked

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.)
hFig = localGetFigure(hParent);
if isactiveuimode(hFig,'Standard.EditPlot')
    hPlotEdit = plotedit(hFig,'getmode');
    hMode = hPlotEdit.ModeStateData.PlotSelectMode;
    hObjs = hMode.ModeStateData.SelectedObjects;
else
    hMenu = ancestor(obj,'UIContextMenu');
    if isappdata(hMenu,'CallbackObject')
        hObjs = getappdata(hMenu,'CallbackObject');
    else
        hObjs = hittest(hFig);
    end
end

if ~isprop(hObjs(end),propName)
    return;
end

value = get(hObjs(end),propName);
label = sprintf(format,value);
menus = findall(obj,'Label',label);
if ~isempty(menus)
    hPar = get(menus(1),'Parent');
else
    menus = [];
    hPar = obj;
end
hSibs = findall(hPar);

set(hSibs(2:end),'Checked','off');
set(menus,'Checked','on');

%----------------------------------------------------------------------%
function entry = localCreateColorEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a color dialog:

entry = uimenu(hParent,'HandleVisibility','off','Label',displayText, ...
    'Callback',{@localScribeContextMenuCallback,'localExecuteColorCallback',hFig,propName,undoName,actionCodeGen});

%----------------------------------------------------------------------%
function hFig = localGetFigure(hParent)

if ishghandle(hParent,'figure')
    hFig = hParent;
elseif ishghandle(hParent,'uicontextmenu')
    hFig = get(hParent,'Parent');
else
    hFig = ancestor(hParent,'figure');
end

%----------------------------------------------------------------------%

function localScribeContextMenuCallback(es,ed,switchArg,hParent,actionCodeGen,varargin)

matlab.graphics.annotation.internal.scribeContextMenuCallback(es,ed,switchArg,localGetFigure(hParent),actionCodeGen,varargin{:});

%----------------------------------------------------------------------%
function entry = localCreateDisplayStyleEntry(hFig,hParent,displayText,propName,undoName,actionCodeGen)
% Create a uimenu that brings up a list of histogram display styles

values = {'bar','stairs'};
descriptions = cellfun(@(x)getString(message(['MATLAB:uistring:scribemenu:' x ])),values,'UniformOutput',false);

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values, undoName,actionCodeGen);

%----------------------------------------------------------------------%
function entry = localCreateDisplayStyle2DEntry(hFig,hParent,displayText,propName,undoName,localCreateDisplayStyleEntry)
% Create a uimenu that brings up a list of histogram2 display styles

values = {'bar3','tile'};
descriptions = cellfun(@(x)getString(message(['MATLAB:uistring:scribemenu:' x ])),values,'UniformOutput',false);

entry = localCreateEnumEntry(hFig,hParent,displayText,propName,descriptions,values, undoName,localCreateDisplayStyleEntry);

%----------------------------------------------------------------------%
function entry = localCreateMoreFewerbinsEntry(hFig,hParent,displayText,methodName,undoName,actionCodeGen)
% creates a uimenu that increments the number of histogram bins

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localMoreFewerBinsCallback',...
                hFig, str2func(methodName), undoName});

 %----------------------------------------------------------------------%
function entry = localCreateMoreFewerbins2DEntry(hFig,hParent,displayText,methodName)
% creates a uimenu that increments the number of 2D histogram bins

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off');
uimenu(entry, ...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:XAxisOnly')),...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localMoreFewerBins2DCallback',...
    hFig, str2func(methodName), 'x', ...
    getString(message(['MATLAB:uistring:scribemenu:' methodName 'x']))});
uimenu(entry, ...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:YAxisOnly')),...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localMoreFewerBins2DCallback',...
                hFig, str2func(methodName), 'y', ...
                getString(message(['MATLAB:uistring:scribemenu:' methodName 'y']))});
uimenu(entry, ...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:XAndYAxes')),...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localMoreFewerBins2DCallback',...
                hFig, str2func(methodName), 'both', ...
                getString(message(['MATLAB:uistring:scribemenu:' methodName 'xy']))});        
            
%----------------------------------------------------------------------%
function entry = localCreateDisplayOrderEntry(hFig,hParent,displayText,propName)
% creates a uimenu that changes the order of axes children

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off');
uimenu(entry,...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:BringToFront')),...
    'Visible','off',...
    'Tag', [propName '.BringToFront'], ...
    'Callback',{@localScribeContextMenuCallback,'localDisplayOrderCallback',...
                hFig, inf, getString(message('MATLAB:uistring:scribemenu:BringToFront'))});  
uimenu(entry,...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:SendToBack')),...
    'Visible','off',...
    'Tag', [propName '.SendToBack'], ...    
    'Callback',{@localScribeContextMenuCallback,'localDisplayOrderCallback',...
                hFig, -inf, getString(message('MATLAB:uistring:scribemenu:SendToBack'))});     
uimenu(entry,...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:BringForward')),...
    'Visible','off',...
    'Tag', [propName '.BringForward'], ...      
    'Callback',{@localScribeContextMenuCallback,'localDisplayOrderCallback',...
                hFig, 1, getString(message('MATLAB:uistring:scribemenu:BringForward'))});  
uimenu(entry,...
    'HandleVisibility','off',...
    'Label',getString(message('MATLAB:uistring:scribemenu:SendBackward')),...
    'Visible','off',...
    'Tag', [propName '.SendBackward'], ...   
    'Callback',{@localScribeContextMenuCallback,'localDisplayOrderCallback',...
                hFig, -1, getString(message('MATLAB:uistring:scribemenu:SendBackward'))});             
%----------------------------------------------------------------------%
 function entry = localCreateAlignBinsEntry(hFig,hParent,displayText,undoName)
% Create a uimenu that align bins of multiple histograms

entry = uimenu(hParent,...
    'HandleVisibility','off',...
    'Label',displayText,...
    'Visible','off',...
    'Callback',{@localScribeContextMenuCallback,'localAlignBinsCallback',...
                hFig, undoName});

    
            
