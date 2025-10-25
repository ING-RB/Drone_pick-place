function scribeContextMenuCallback(obj,evd,callbackName,actionCodeGen,varargin)
% Executes a callback and registers the change (if any) with the undo
% stack.

%   Copyright 2006-2023 The MathWorks, Inc.

% This is a switchyard function for plot edit callbacks
feval(callbackName,obj,evd,actionCodeGen,varargin{:});

%----------------------------------------------------------------------%
function localUpdateValue(obj,evd,hFig,propName,value,undoName,actionCodeGen) %#ok<INUSL>
% Update the property value specified by the callback:

% Make sure the mode is active. Some context menus (legend and colorbar)
% may execute their callbacks when the mode is not active. In this case, we
% use a different tack. It should be noted that if we are not in plot edit
% mode, the callbacks will *not* be registered with undo/redo
% We check the "scribeActive" flag in case we are in the middle of
% initialization.

[hObjs, hMode] = matlab.graphics.annotation.internal.getMenuTargetObjects(hFig, obj);
if ~isempty(hMode)
    matlab.graphics.internal.PlotEditInteractionUtils.contextMenuConstructPropertyUndo(hFig,hMode,undoName,propName,get(hObjs,propName),value);
end
if iscell(propName)
    cellfun(@(x)(set(hObjs,x,value)),propName);
else
    set(hObjs,propName,value);

     p = matlab.plottools.notifier.PlotToolsNotifier();

     p.notifyCodeGen(hObjs, matlab.internal.editor.figure.ActionID.PROPERTY_EDITED, propName);

	% Update the toolstrip so the new value is reflected
    p.notifyToolstrip();
end

%----------------------------------------------------------------------%
function localExecuteColorCallback(obj,evd,hFig,propName,undoName,actionCodeGen) 
% Brings up a color dialog linked to "propName". The object is determined
% by the currently selected objects of the plot select mode.

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hObjs = matlab.graphics.annotation.internal.getMenuTargetObjects(hFig, obj);

if isempty(hObjs)
    hObjs = hFig;
end
if iscell(propName)
    pName = propName{1};
else
    pName = propName;
end
c = uisetcolor(get(hObjs(end),pName));
if ~isequal(c,0)
    localUpdateValue(obj,evd,hFig,propName,c,undoName,actionCodeGen)
end

%-----------------------------------------------------------------------%
function localExecuteFontCallback(obj,evd,hFig,undoName,varargin) %#ok<DEFNU,INUSL>
% Brings up a font dialog linked to an object. The object is determined by
% the currently selected object of the plot select mode.

[hObjs, hMode] = matlab.graphics.annotation.internal.getMenuTargetObjects(hFig, obj);

props = {'FontName','FontWeight','FontAngle','FontUnits','FontSize'};

for i=1:numel(props)
    if ~isprop(hObjs(end), props{i})
        props{i} = '';
    end
end
% Remove the empty values
props = props(~cellfun(@isempty, props));
pv = [props; get(hObjs(end),props)]; % 2-by-n array to be flattened
s = uisetfont(struct(pv{:}));
% On MAC, the structure returned may not have a "FontUnits" field. In this
% case, create one to prevent problems down the line.
if isstruct(s) && ~isfield(s,'FontUnits')
    s.FontUnits = 'Points';
end


if ~isequal(s,0)
    if ~isempty(hMode)
        matlab.graphics.internal.PlotEditInteractionUtils.contextMenuConstructPropertyUndo(hFig,hMode,undoName,props,get(hObjs,props),struct2cell(s));
    end
    for i=1:numel(props)
    if ischar( hObjs.(props{i})) && ~strcmp( hObjs.(props{i}), s.(props{i}))  % only generate code for changed props
        matlab.graphics.internal.PlotEditInteractionUtils.contextMenuSetFont(hObjs,s,props{i});
    elseif hObjs.(props{i}) ~= s.(props{i}) % check if FontSize is changed
        matlab.graphics.internal.PlotEditInteractionUtils.contextMenuSetFont(hObjs,s,props{i});
    end
    end
end


%-----------------------------------------------------------------------%
function localConstructPropertyUndoCallback(obj,evd,hFig,hMode,Name,propName,oldValue,newValue)
% Externally called by functions that want to register with undo/redo

matlab.graphics.internal.PlotEditInteractionUtils.contextMenuConstructPropertyUndo(hFig,hMode,Name,propName,oldValue,newValue);
%-----------------------------------------------------------------------%
function localUndoHeterogeneousProperties(hObjs,propName,value)
% Undo by setting different properties for each object

for i=1:length(hObjs)
    if iscell(propName{i})
        for j=1:numel(propName{i})
            set(hObjs(i),propName{i}{j},value{i}{j});
        end
    else
        set(hObjs(i),propName{i},value{i});
    end
end

%----------------------------------------------------------------------%
function localMoreFewerBinsCallback(~,~,hFig,hFunc, undoName) 

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hPlotEdit = plotedit(hFig,'getmode');
hMode = hPlotEdit.ModeStateData.PlotSelectMode;
hObjs = hMode.ModeStateData.SelectedObjects;

% Construct undo command
nObjs = length(hObjs);
propNames = cell(nObjs,1);
oldVals = cell(nObjs,1);
for i=1:nObjs
    if strcmp(hObjs(i).BinLimitsMode, 'manual')
        propNames{i} = 'BinEdges';
        oldVals{i} = hObjs(i).BinEdges;
    elseif isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).BinLimits(1), hObjs(i).BinWidth) == 0
        propNames{i} = 'BinWidth';
        oldVals{i} = hObjs(i).BinWidth;
    else
        propNames{i} = 'NumBins';
        oldVals{i} = hObjs(i).NumBins;        
    end
end

opName = undoName;
cmd.Name = opName;
cmd.Function = hFunc;
cmd.Varargin = {hObjs};
cmd.InverseFunction = @localUndoHeterogeneousProperties;
cmd.InverseVarargin = {hObjs, propNames, oldVals};

% Register with undo/redo
uiundo(hFig,'function',cmd);

hFunc(hObjs);

% Generate codes for MoreFewerBins
% "generatePropertyEditingCode" adds a tight dependency between this and the code generator
% To do: update the CodeGen with a notification mechanism that can decouple this
matlab.graphics.internal.propertyinspector.generatePropertyEditingCode(hObjs, {'NumBins'});

%----------------------------------------------------------------------%
function localMoreFewerBins2DCallback(~,~,hFig,hFunc,arg,undoName) 

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hPlotEdit = plotedit(hFig,'getmode');
hMode = hPlotEdit.ModeStateData.PlotSelectMode;
hObjs = hMode.ModeStateData.SelectedObjects;

% Construct undo command

nObjs = length(hObjs);
propNames = cell(nObjs,1);
oldVals = cell(nObjs,1);
switch arg
    case 'x'
        for i=1:nObjs
            if strcmp(hObjs(i).XBinLimitsMode, 'manual')
                propNames{i} = 'XBinEdges';
                oldVals{i} = hObjs(i).XBinEdges;
            elseif (isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).XBinLimits(1), hObjs(i).BinWidth(1)) == 0) ...
                    || (matlab.graphics.chart.primitive.histogram.internal.areBinEdgesUniform(hObjs(i).XBinEdges) ...
                    && rem(hObjs(i).XBinLimits(1), diff(hObjs(i).XBinEdges(1:2))) == 0)
                propNames{i} = 'BinWidth';
                oldVals{i} = hObjs(i).BinWidth;
            else
                propNames{i} = 'NumBins';
                oldVals{i} = hObjs(i).NumBins;
            end
        end
    case 'y'
         for i=1:nObjs
            if strcmp(hObjs(i).YBinLimitsMode, 'manual')
                propNames{i} = 'YBinEdges';
                oldVals{i} = hObjs(i).YBinEdges;
            elseif (isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).YBinLimits(1), hObjs(i).BinWidth(2)) == 0) ...
                    || (matlab.graphics.chart.primitive.histogram.internal.areBinEdgesUniform(hObjs(i).YBinEdges) ...
                    && rem(hObjs(i).YBinLimits(1), diff(hObjs(i).YBinEdges(1:2))) == 0)
                propNames{i} = 'BinWidth';
                oldVals{i} = hObjs(i).BinWidth;
            else
                propNames{i} = 'NumBins';
                oldVals{i} = hObjs(i).NumBins;
            end
        end       
    otherwise % both
        for i=1:nObjs    
            xmanual = strcmp(hObjs(i).XBinLimitsMode, 'manual');
            ymanual = strcmp(hObjs(i).YBinLimitsMode, 'manual');
            if xmanual && ymanual
                propNames{i} = {'XBinEdges', 'YBinEdges'};
                oldVals{i} = {hObjs(i).XBinEdges, hObjs(i).YBinEdges};
            elseif xmanual
                if (isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).YBinLimits(1), hObjs(i).BinWidth(2)) == 0) ...
                        || (matlab.graphics.chart.primitive.histogram.internal.areBinEdgesUniform(hObjs(i).YBinEdges) ...
                        && rem(hObjs(i).YBinLimits(1), diff(hObjs(i).YBinEdges(1:2))) == 0)
                    propNames{i} = {'XBinEdges','BinWidth'};
                    oldVals{i} = {hObjs(i).XBinEdges, hObjs(i).BinWidth};
                else
                    propNames{i} = {'XBinEdges','NumBins'};
                    oldVals{i} = {hObjs(i).XBinEdges, hObjs(i).NumBins};
                end
            elseif ymanual
                if (isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).XBinLimits(1), hObjs(i).BinWidth(1)) == 0) ...
                        || (matlab.graphics.chart.primitive.histogram.internal.areBinEdgesUniform(hObjs(i).XBinEdges) ...
                        && rem(hObjs(i).YBinLimits(2), diff(hObjs(i).YBinEdges(1:2))) == 0)
                    propNames{i} = {'YBinEdges','BinWidth'};
                    oldVals{i} = {hObjs(i).YBinEdges, hObjs(i).BinWidth};
                else
                    propNames{i} = {'YBinEdges','NumBins'};
                    oldVals{i} = {hObjs(i).YBinEdges, hObjs(i).NumBins};
                end
            else % ~xmanual && ~ymanual
                if all(rem([hObjs(i).XBinLimits(1) hObjs(i).YBinLimits(1)], hObjs(i).BinWidth) == 0)
                    propNames{i} = 'BinWidth';
                    oldVals{i} = hObjs(i).BinWidth;
                else
                    propNames{i} = 'NumBins';
                    oldVals{i} = hObjs(i).NumBins;
                end
            end
        end
end

opName = undoName;
cmd.Name = opName;
cmd.Function = hFunc;
cmd.Varargin = {hObjs};
cmd.InverseFunction = @localUndoHeterogeneousProperties;
cmd.InverseVarargin = {hObjs, propNames, oldVals};

% Register with undo/redo
uiundo(hFig,'function',cmd);

hFunc(hObjs,arg);


%-----------------------------------------------------------------------%
function localUndoDisplayOrder(hAx,propName,value)


set(hAx,propName,value);

%----------------------------------------------------------------------%
function localDisplayOrderCallback(~,~,hFig,order,undoName) 

% order input is expected to be one of +-1 or +-Inf
% +1 Bring Forward
% -1 Send Backward
% +Inf Bring to Front
% -Inf Send to Back

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hPlotEdit = plotedit(hFig,'getmode');
hMode = hPlotEdit.ModeStateData.PlotSelectMode;
hObjs = hMode.ModeStateData.SelectedObjects;

if isscalar(hObjs)
    hAxes = ancestor(hObjs,'axes');
    hAxesChildren = hAxes.Children;
    
    cmd.Name = undoName;
    cmd.InverseFunction = @localUndoDisplayOrder;
    cmd.InverseVarargin = {hAxes, 'Children', hAxesChildren};
    
    if order == inf  % Bring To Front
        hAxesOtherChildren = setdiff(hAxesChildren,hObjs,'stable');
        hAxes.Children = [hObjs; hAxesOtherChildren];
    elseif order == 1  % Bring Forward
        [~,locb] = ismember(hObjs, hAxesChildren);
        % note that this menu should be disabled if object is already
        % in front. From that assumption, locb > 1.
        hAxes.Children([locb-1 locb]) = hAxes.Children([locb locb-1]);
    elseif order == -1  % Send Backward
        [~,locb] = ismember(hObjs, hAxesChildren);
        % note that this menu should be disabled if object is already
        % at the back. From that assumption, locb < length(hAxes.Children).
        hAxes.Children([locb locb+1]) = hAxes.Children([locb+1 locb]);
    else % order == -inf, Send To Back
        hAxesOtherChildren = setdiff(hAxesChildren,hObjs,'stable');
        hAxes.Children = [hAxesOtherChildren; hObjs];
    end
    
    cmd.Function = @localUndoDisplayOrder;
    cmd.Varargin = {hAxes, 'Children', hAxes.Children};
    
    % Register with undo/redo
    uiundo(hFig,'function',cmd);
end

%----------------------------------------------------------------------%
function localAlignBins(hObjs)

% it is essential to separate the following two set commands in 2 lines,
% because if BinLimitsMode is initially manual, the histograms may be using
% uneven bins and thus do not have numeric BinWidth. 
set(hObjs, 'BinLimitsMode', 'auto');
set(hObjs,'BinWidth',hObjs(1).BinWidth);

%----------------------------------------------------------------------%
function localAlignBinsCallback(~,~,hFig,undoName) 

% Get a handle to the mode. Though this creates an interdependency, it is
% mitigated by the guarantee that this callback is only executed while the
% mode is active, and thus already created.
hPlotEdit = plotedit(hFig,'getmode');
hMode = hPlotEdit.ModeStateData.PlotSelectMode;
hObjs = hMode.ModeStateData.SelectedObjects;

% Construct undo command
nObjs = length(hObjs);
propNames = cell(nObjs,1);
oldVals = cell(nObjs,1);
for i=1:nObjs
    if strcmp(hObjs(i).BinLimitsMode, 'manual')
        propNames{i} = 'BinEdges';
        oldVals{i} = hObjs(i).BinEdges;
    elseif isnumeric(hObjs(i).BinWidth) && rem(hObjs(i).BinLimits(1), hObjs(i).BinWidth) == 0
        propNames{i} = 'BinWidth';
        oldVals{i} = hObjs(i).BinWidth;
    else
        propNames{i} = 'NumBins';
        oldVals{i} = hObjs(i).NumBins;        
    end
end
opName = undoName;
cmd.Name = opName;
cmd.Function = @localAlignBins;
cmd.Varargin = {hObjs};
cmd.InverseFunction = @localUndoHeterogeneousProperties;
cmd.InverseVarargin = {hObjs, propNames, oldVals};

% Register with undo/redo
uiundo(hFig,'function',cmd);

localAlignBins(hObjs);

