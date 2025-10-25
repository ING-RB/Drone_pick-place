function [out] = brush(arg1,arg2)
%BRUSH Interactively highlight, delete, and modify observations in graphs.
%  BRUSH ON turns on brushing.
%  BRUSH OFF turns it off.
%  BRUSH by itself toggles the state.
%  BRUSH COLOR sets the current color used for brushing graphics to the
%  specified ColorSpec. Note that this does not affect the brush state.
%  BRUSH(FIG,OPTION) applies the brush command to the figure specified by
%  FIG. OPTION can be any of the above arguments.
%
%  H = BRUSH(FIG) returns the figure's brush mode object for customization.
%        The following properties can be modified using set/get:
%
%        Enable  'on'|{'off'}
%        Specifies whether this figure mode is currently 
%        enabled on the figure.
%
%        FigureHandle <handle>
%        The associated figure handle. This property supports GET only.
%
%        Color <MATLAB array>
%        Specifies the current color used for brushing
%
%  EXAMPLE 1:
%
%  plot(1:10);
%  brush on
%  % brush graphics in the plot
%
%  EXAMPLE 2:
%
%  plot(1:10);
%  h = brush;
%  h.Color = [1 0 0];
%  h.Enable = 'on';
%  % brush graphics on the plot in red.
%
%
%  See also ZOOM, PAN, ROTATE3D, LINKAXES.

% Copyright 2007-2023 The MathWorks, Inc.

fig = [];
if nargin == 0 || (nargin == 1 && (~isscalar(arg1) || ~isgraphics(arg1)))
    fig = gcf; % caller did not specify handle
end


% Web figure implementation
webAxesInputArgument = (nargin > 0) && matlab.graphics.interaction.internal.isWebAxes(arg1);
webFigureInputArgument = (nargin > 0) && (isscalar(arg1) && isgraphics(arg1) && isa(arg1,'matlab.ui.Figure') && ...
    ~isWebFigureType(arg1,'EmbeddedMorphableFigure') && ...
    matlab.graphics.interaction.internal.isNotLiveEditorWebFigure(arg1));
webFigureIsCurrent = matlab.graphics.interaction.internal.isNotLiveEditorWebFigure(fig);

if (nargin > 0) && isempty(fig)
    obj = arg1;
else
    obj = fig;
end

UseLegacyModes = (nargout>0) || ShouldUseLegacyModes(webAxesInputArgument, webFigureInputArgument, webFigureIsCurrent, obj);
if ~UseLegacyModes && nargin >= 1 
    % If a color input argument is used switch to legacy modes as custom
    % colors are not supported using the web mode
    if nargin>=2
        colorArg = arg2;
    else
        colorArg = arg1;
    end
    if isnumeric(colorArg) && length(colorArg)==3
        UseLegacyModes = true;
    elseif ischar(colorArg) || isstring(colorArg)
        if ~(strcmp(colorArg,'on') || strcmp(colorArg,'off') || strcmp(colorArg,'ison'))
            UseLegacyModes = true;
        end
    end
end
if ~UseLegacyModes && (webAxesInputArgument || webFigureInputArgument || webFigureIsCurrent)
    switch(nargin)
        case 0
            % brush with no input args should toggle the mode
            matlab.graphics.interaction.webmodes.modeFunctionHelper('brush', obj);
        case 1
            matlab.graphics.interaction.webmodes.modeFunctionHelper('brush', arg1);
        case 2
            matlab.graphics.interaction.webmodes.modeFunctionHelper('brush', arg1, arg2);
    end
    return
end

brushColor = [];
state = '';
if nargin==0
    f = gcf;
    if nargout>0
        out = locGetObj(f);
        return
    end
    if isactiveuimode(f,'Exploration.Brushing')
        state = 'off';
    else
        state = 'on';
    end
elseif nargin==1
    if length(arg1)==1 && ishghandle(arg1) && isgraphics(arg1)
        f = ancestor(arg1,'figure');
        if isempty(f)
            out = [];
            return
        end
        if nargout>0
           out = locGetObj(f);
           return
        end
        if isactiveuimode(f,'Exploration.Brushing')
            state = 'off';
        else
            state = 'on';
        end
    elseif ischar(arg1) || isstring(arg1)
        f = gcf;
        if nargout>0 
            if ~strcmpi(arg1,'ison')
                error(message('MATLAB:brush:NoBrushColorModeOut'))
            end
        end
        if strcmp(arg1,'on') || strcmp(arg1,'off')
            state = arg1;
        elseif strcmp(arg1,'ison')
            out = isactiveuimode(f,'Exploration.Brushing');
            return;
        else
            brushColor = arg1;
            enableLegacyExplorationModes(f)
        end
    elseif isnumeric(arg1) && length(arg1)==3
        if nargout>0
            error(message('MATLAB:brush:NoColorOut'))
        end
        f = gcf;
        brushColor = arg1;
        enableLegacyExplorationModes(f)
    elseif nargout>0
        error(message('MATLAB:brush:InvalidInputForOutArg')) 
    end
elseif nargin==2
    if nargout>0 && ~strcmpi(arg2,'ison')
            error(message('MATLAB:brush:NoBrushColorModeOut'))
    end
    if ~ishghandle(arg1) || (~strcmp(get(arg1,'type'),'figure') && ~ishghandle(arg1,'axes'))
        error(message('MATLAB:brush:InvalidFigure'));
    else
        f = ancestor(arg1,'figure');
        if isempty(f)
            out = [];
            return
        end
    end

    if (ischar(arg2) || isstring(arg2)) && any(strcmpi(arg2,{'on','off','ison'}))
        if strcmp(arg2,'on') || strcmp(arg2,'off')
             state = arg2;
        elseif strcmp(arg2,'ison')
            out = isactiveuimode(f,'Exploration.Brushing');
            return
        end
    else
        brushColor = arg2;
        enableLegacyExplorationModes(f)
    end
end
    
if strcmp(state,'off') && isactiveuimode(f,'Exploration.Brushing')
    activateuimode(f,'');
elseif strcmp(state,'on')
    ptrCache = get(f,'Pointer');
    set(f,'Pointer','watch');
      
    % Create the scribe layer camera now since it will be needed
    % once the drag gesture creates the ROI
    % Call drawnow after initialization of the scribe layer to ensure
    % that the WindowButtonMotion events do not get triggered before the
    % scribe layering has completed. This avoids WindowButtonMotionFcn
    % getting WindowMouseData with an empty HitPrimitive even when the
    % mouse is over an axes when the axes is in the process of
    % being re-parented.
    scribelayer = matlab.graphics.annotation.internal.getDefaultCamera(f,'overlay','-peek');
    if isempty(scribelayer)
        matlab.graphics.annotation.internal.findScribeLayer(f);
        drawnow
    end
    drawnow expose
    locGetMode(f); % Creates the mode 
    set(f,'Pointer',ptrCache);
    activateuimode(f,'Exploration.Brushing'); 
end

if ~isempty(brushColor)
    hMode = locGetMode(f);
    locGetObj(f); % Make sure mode accessor is there
    if ischar(brushColor)        
        hMode.ModeStateData.color = localConvertColorSpecString(brushColor);
    elseif isstring(brushColor)
        hMode.ModeStateData.color = localConvertColorSpecString(char(brushColor));
    elseif isnumeric(brushColor) && isvector(brushColor) && length(brushColor)==3 && ...
            ~any(isnan(brushColor)) && min(brushColor)>=0 && max(brushColor)<=1
        hMode.ModeStateData.color = brushColor;
    else
        error(message('MATLAB:brush:invColor'));
    end    
    tb = findobj(allchild(f),'flat','Type','uitoolbar');
    brushToolbarButton = matlab.ui.internal.findToolbarModeButtonsById(allchild(tb),'Exploration.Brushing');
    if ~isempty(brushToolbarButton)
        localColorCallback(hMode,brushToolbarButton);    
    end
end

% Callback for mode start/stop
function localModeStateChange(hMode,newstate)

fig = hMode.FigureHandle;
tb = findobj(allchild(fig),'flat','Type','uitoolbar');
brushToolbarButton = matlab.ui.internal.findToolbarModeButtonsById(findall(tb),'Exploration.Brushing');
set(brushToolbarButton,'State',newstate);

set(findall(fig,'tag','figBrush'),'Checked',newstate);
set(findall(fig,'Tag','figBrushTools'),'Enable',newstate);

% Enable/disable figure copy menu
set(findall(fig,'Tag','figMenuEditCopy'),'Enable',newstate);

% Add doUpdate listener to react to renderer changes
% JSD_OGL_REMOVAL The figure renderer will not change in webui
if strcmp('on',newstate) && isobject(fig) && ~feature('webui')
    addFigureRendererListener(fig)
end

function hBrush = locGetObj(hFig)

% Return the brush accessor object, if it exists.
hMode = locGetMode(hFig);
if isempty(hMode.ModeStateData.accessor) ||~ishandle(hMode.ModeStateData.accessor)
    hBrush = matlab.graphics.interaction.internal.brush(hMode);
    hMode.ModeStateData.accessor = hBrush;
else
    hBrush = hMode.ModeStateData.accessor;
end


function [hMode] = locGetMode(hFig)

hMode = getuimode(hFig,'Exploration.Brushing');
if isempty(hMode)
    
    
    % Construct the mode object and set properties
    hMode = uimode(hFig,'Exploration.Brushing');
    hMode.WindowButtonDownFcn = @(es,ed) datamanager.brushdown(es,ed);
    hMode.WindowButtonUpFcn = @(es,ed) datamanager.brushup(es,ed);
    hMode.WindowButtonMotionFcn = @(es,ed) datamanager.brushdrag(es,ed);
    hMode.KeyPressFcn = @datamanager.brushkeypress;
    hMode.ModeStateData = ...
       struct('color',[1 0 0],'xLimMode','','yLimMode','',...
       'zLimMode','','brushIndex',[],'time',[],'SelectionObject',[],...
       'accessor',[],'brushObjects',[],'lastRegion',[],...
       'scribeLayer',[],'plotYYModeStateData',[]);
    
    % If necessary, add a BrushStyleMap instance property to the figure
    hFig_ = handle(hFig);
    if isempty(hFig_.findprop('BrushStyleMap'))
        brushStyleMapProp = addprop(hFig_,'BrushStyleMap');
        brushStyleMapProp.Hidden = true;
        hFig_.BrushStyleMap = [1 0 0;0 1 0; 0 0 1]; % default
    end

    % Activate the mode
    hMode.ModeStopFcn = {@localModeStateChange hMode  'off'};
    hMode.ModeStartFcn = {@localModeStateChange hMode  'on'};
end   
 
function localColorCallback(hMode,brushbtn)

modeColor = hMode.ModeStateData.color;
  
if ~isempty(brushbtn)
    cdata = get(brushbtn,'cdata');
    for row=11:15
        for col=11:15
            cdata(row,col,:) = modeColor;
        end
    end
    set(brushbtn,'CData',cdata);
end

function colorVector = localConvertColorSpecString(colorString)
       try
           colorVector = hgcastvalue('matlab.graphics.datatype.RGBColor', colorString);
       catch 
           error(message("matlab:datatypes:rgbcolor:ParseError"))
       end

function localClearROI(hMode)

if ~isempty(hMode.ModeStateData.SelectionObject)
    hMode.ModeStateData.SelectionObject.reset;
end

%-----------------------------------------------%
function tf = ShouldUseLegacyModes(webAxesInputArgument, webFigureInputArgument, webFigureIsCurrent, obj)

fig_handle = gobjects(1);
if webAxesInputArgument
    fig_handle = ancestor(obj,'figure');
elseif webFigureInputArgument || webFigureIsCurrent
    fig_handle = obj;
end

tf = isprop(fig_handle,'UseLegacyExplorationModes') && fig_handle.UseLegacyExplorationModes;





