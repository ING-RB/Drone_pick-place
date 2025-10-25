function h = ltiplot(ax,PlotType,InputNames,OutputNames,PlotOptions,Prefs,varargin)
%LTIPLOT  Construct LTI plot using @resppack.
%
%   H = LTIPLOT(AX,PlotType,InputNames,OutputNames,Preferences) where
%     * AX is an HG axes handle
%     * PlotType is the response type
%     * InputNames and OutputNames are the I/O names (specify axes grid size)
%     * PlotOptions is a PlotOptions object for initializing the plot.
%     * Prefs = Preference object (tbxprefs or viewprefs)

%   Author(s): Adam DiVergilio, P. Gahinet, B. Eryilmaz
%   Revised  : Kamesh Subbarao, 10-15-2001
%   Copyright 1986-2019 The MathWorks, Inc.

% Ax can be a numeric so cast it as a handle
axHndl = handle(ax);

if ~isempty(ancestor(ax,'matlab.graphics.layout.Layout'))
    error(message('MATLAB:handle_graphics:Layout:UnsupportedChart'))
end

% Get plot object if exists
h = gcr(ax);

% Get plot add/replace status
NewPlot = strcmp(get(ax,'NextPlot'),'replace');
NewRespPlot = NewPlot || isempty(h);

% Generate appropriate plot options for this plot
PlotOptions = ltiplotoption(PlotType,PlotOptions,Prefs,NewRespPlot,h);

% Check hold state
% Used to see if grid is on
if ~NewPlot && isempty(h) && ~isempty(findall(ax,'Tag','CSTgridLines'))
    PlotOptions.Grid = 'on';
end

% Clear and reset axes if new plot
if NewPlot

  % Notify the live editor of newplot
  matlab.graphics.internal.clearNotify(ax);
    
  % Clear any existing response plot upfront (otherwise style
  % settings below get erased by CLA in respplot/check_hold)
  if ~isempty(h)
      cla(h.AxesGrid,handle(ax))  % speed optimization
  else
      cla(ax,'reset')
  end
  
  % Release manual limits and hide axis for optimal performance
  % RE: Manual negative Xlim can cause warning for BODE (not reset by clear)
  set(ax,'Visible','off','XlimMode','auto','YlimMode','auto')
end

% Style settings specific to LTI plots
if NewRespPlot
    set(ax,...
        'XGrid',      PlotOptions.Grid,...
        'YGrid',      PlotOptions.Grid,...
        'FontSize',   PlotOptions.TickLabel.FontSize,...
        'FontWeight', PlotOptions.TickLabel.FontWeight,...
        'FontAngle',  PlotOptions.TickLabel.FontAngle,...
        'Selected',   'off')
    set(get(ax,'Title'),...
        'FontSize',  PlotOptions.Title.FontSize,...
        'FontWeight',PlotOptions.Title.FontWeight,...
        'FontAngle', PlotOptions.Title.FontAngle)
    set(get(ax,'XLabel'),...
        'FontSize',  PlotOptions.XLabel.FontSize,...
        'FontWeight',PlotOptions.XLabel.FontWeight,...
        'FontAngle', PlotOptions.XLabel.FontAngle)
    set(get(ax,'YLabel'),...
        'FontSize',  PlotOptions.YLabel.FontSize,...
        'FontWeight',PlotOptions.YLabel.FontWeight,...
        'FontAngle', PlotOptions.YLabel.FontAngle)

    if strcmp(PlotOptions.ColorMode.TickLabel,"manual")
        set(ax,'XColor',PlotOptions.TickLabel.Color,'YColor',PlotOptions.TickLabel.Color);
    end

    if strcmp(PlotOptions.ColorMode.XLabel,"manual")
        axHndl.XLabel.Color = PlotOptions.XLabel.Color;
    end

    if strcmp(PlotOptions.ColorMode.YLabel,"manual")
        axHndl.YLabel.Color = PlotOptions.YLabel.Color;
    end
end

% Create plot
GridSize = [length(OutputNames) , length(InputNames)];  % generic case
Settings = {'InputName',  InputNames, ...
    'OutputName', OutputNames,...
    'Tag', PlotType};

% ----
% This is used by the Figure Toolstrip via the
% matlab.plottools.service.accessor.ControlsPlotAccessor to
% enable/disable features for the controls plots




if ~isprop(axHndl, 'FDT_Accessor')     
    accesorId = addprop(axHndl, 'FDT_Accessor');
    accesorId.Transient = true;
    accesorId.Hidden = true;
end

% Use the controls PlotType as the Accessor key
axHndl.FDT_Accessor = PlotType;
% ----

switch PlotType
    case 'bode'
        h = resppack.bodeplot(ax, GridSize, Settings{:}, varargin{:});
    case 'impulse'
        h = resppack.timeplot(ax, GridSize, Settings{:}, varargin{:});
    case 'initial'
        h = resppack.simplot(ax,GridSize(1),...
            'OutputName', OutputNames, 'Tag', PlotType, varargin{:});
    case 'iopzmap'
        h = resppack.pzplot(ax, GridSize,...
            Settings{:}, varargin{:});
    case 'hsv'
        h = resppack.hsvplot(ax, 'Tag', PlotType, varargin{:});
    case 'lsim'
        h = resppack.simplot(ax, GridSize(1),...
            'OutputName', OutputNames, 'Tag', PlotType, varargin{:});
        h.setInputWidth(length(InputNames));
        h.Input.ChannelName = InputNames;
    case 'nichols'
        h = resppack.nicholsplot(ax, GridSize, Settings{:}, varargin{:});
    case 'nyquist'
        h = resppack.nyquistplot(ax, GridSize, Settings{:}, varargin{:});
    case 'pzmap'
        h = resppack.mpzplot(ax,'Tag', PlotType, varargin{:});
    case 'rlocus'
        h = resppack.rlplot(ax,'Tag', PlotType, varargin{:});
    case 'sigma'
        h = resppack.sigmaplot(ax, 'Tag', PlotType, varargin{:});
    case 'step'
        h = resppack.timeplot(ax, GridSize, Settings{:}, varargin{:});
    case 'noisespectrum'
        h = resppack.noisespectrumplot(ax, GridSize, Settings{:}, varargin{:});
    case 'diskmargin'
        h = resppack.diskmarginplot(ax, 'Tag', PlotType, varargin{:});
    case {'sectorplot'}
        h = resppack.RelativeIndexPlot(ax, 'Tag', PlotType, varargin{:});
    case {'dirindex'}
        h = resppack.DirectionalIndexPlot(ax, 'Tag', PlotType, varargin{:});
end

% Delete datatips when the axis is clicked
fig = ancestor(h.AxesGrid.Parent,'figure'); 
% Branching for axes parented to uifigure in Live Editor Task
if ~controllibutils.isLiveTaskFigure(fig)  
    set(allaxes(h),'ButtonDownFcn',{@LocalAxesButtonDownFcn}) %Temporary workaround
    %set(allaxes(h),'ButtonDownFcn',@(eventsrc,y) defaultButtonDownFcn(h,eventsrc))
    
    % Control cursor and datatip popups over characteristic markers
    % REVISIT: remove this code when MouseEntered/Exited event available
    if isempty(get(fig,'WindowButtonMotionFcn'))
        set(fig,'WindowButtonMotionFcn',@(x,y) hoverfig(fig))
        % Customize datacursor to use datatip style and not
        % cursor window
        hTool = datacursormode(fig);
        set(hTool,'DisplayStyle','datatip');
    end
end

% Limit management
if any(strcmp(PlotType, {'step','impulse','initial'}))
    L = handle.listener(h.AxesGrid, 'PreLimitChanged', @LocalAdjustSimHorizon);
    set(L, 'CallbackTarget', h);
    h.addlisteners(L);
end

% set plot properties
setoptions(h,PlotOptions);


%-------------------------Local Functions--------------------------------%
%------------------------------------------------------------------------%
% Purpose: Recompute responses to span the x-axis limits
%------------------------------------------------------------------------%
function LocalAdjustSimHorizon(this, ~)
Responses = this.Responses;
Tfinal = max(getfocus(this));
for ct = 1:length(Responses)
    DataSrc = Responses(ct).DataSrc;
    if ~isempty(DataSrc)
        try %#ok<TRYNC>
            % Read plot type (step, impulse, or initial) from Tag
            % (needed for step+hold+impulse)
            UpdateFlag = DataSrc.fillresp(Responses(ct),Tfinal);
            if UpdateFlag
                draw(Responses(ct))
            end
        end
    end
end

% Temporary workaround
% ----------------------------------------------------------------------------%
% Purpose: Axes callback to delete datatips when clicked
% ----------------------------------------------------------------------------%
function LocalAxesButtonDownFcn(EventSrc,~)
% Axes ButtonDown function
% Process event
RespPlot = gcr(EventSrc);
if ishandle(RespPlot) % Bypass if RespPlot is not a valid handle
    switch get(ancestor(EventSrc,'figure'),'SelectionType')
        case 'normal'
            PropEdit = PropEditor(RespPlot,'current');  % handle of (unique) property editor
            if ~isempty(PropEdit) && isvalid(PropEdit) && PropEdit.IsVisible
                % Left-click & property editor open: quick target change
                PropEdit.setTarget(RespPlot);
            end
            % Clear all data tips
            target = handle(EventSrc);
            if ishghandle(target,'axes')
                hTips = findall(target,'-class','matlab.graphics.shape.internal.PointDataTip');
                delete(hTips);
            end
        case 'open'
            % Double-click: open editor
            PropEdit = PropEditor(RespPlot);
            PropEdit.setTarget(RespPlot);
            PropEdit.show();
    end
end
