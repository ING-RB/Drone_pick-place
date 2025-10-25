function h = iodataplot(ax,PlotType,InputNames,OutputNames,PlotOptions,Prefs,varargin)
%LTIPLOT  Construct data plot using @wrfc graphics infrastructure.
%
%   H = IODATAPLOT(AX,PlotType,InputNames,OutputNames,Preferences) where
%     * AX is an HG axes handle
%     * PlotType: 'time' or 'frequency'
%     * InputNames and OutputNames are the I/O names (specify axes grid size)
%     * PlotOptions is a PlotOptions object for initializing the plot.
%     * Prefs = Preference object (tbxprefs or viewprefs)

%   Copyright 2013-2019 The MathWorks, Inc.

if ~isempty(ancestor(ax,'matlab.graphics.layout.Layout'))
    error(message('MATLAB:handle_graphics:Layout:UnsupportedChart'))
end

% Ax can be a numeric so cast it as a handle
axHndl = handle(ax);

% Get plot object if exists
h = gcr(ax);

% Get plot add/replace status
NewPlot = strcmp(get(ax,'NextPlot'),'replace');
NewRespPlot = NewPlot || isempty(h);

% Generate appropriate plot options for this plot
PlotOptions = localManagePlotOption(PlotType,PlotOptions,Prefs,NewRespPlot,h);

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
iosize = [numel(OutputNames), numel(InputNames)];
switch PlotType
   case 'time'
      Settings = {'InputName',  InputNames, 'OutputName', OutputNames,...
         'Tag', sprintf('IODataPlot(%s)',PlotType)};
      
      h = iodatapack.iotimeplot(ax, iosize, Settings{:}, varargin{:});
   case 'frequency'
      Settings = {'InputName',  {''}, 'OutputName', [OutputNames; InputNames],...
         'Tag', sprintf('IODataPlot(%s)',PlotType)};
      
      h = iodatapack.iofrequencyplot(ax, iosize, Settings{:}, varargin{:});
end

% Delete datatips when the axis is clicked
set(allaxes(h),'ButtonDownFcn',{@LocalAxesButtonDownFcn}) %Temporary workaround

% Control cursor and datatip popups over characteristic markers
% REVISIT: remove this code when MouseEntered/Exited event available
fig = ancestor(h.AxesGrid.Parent,'figure');
if isempty(get(fig,'WindowButtonMotionFcn'))
   set(fig,'WindowButtonMotionFcn',@(x,y) hoverfig(fig))
   % Customize datacursor to use datatip style and not
   % cursor window
   hTool = datacursormode(fig);
   set(hTool,'DisplayStyle','datatip');
end

% set plot properties
setoptions(h,PlotOptions);

%-------------------------Local Functions---------------------------------%
function LocalAxesButtonDownFcn(EventSrc,varargin)
% Axes callback to delete datatips when clicked
% Temporary workaround
RespPlot = gcr(EventSrc);
if ishandle(RespPlot)
   switch get(ancestor(EventSrc,'figure'),'SelectionType')
      case 'normal'
         PropEdit = PropEditor(RespPlot,'current');  % handle of (unique) property editor
         if ~isempty(PropEdit) && isvalid(PropEdit) && PropEdit.IsVisible
%             Left-click & property editor open: quick target change
            PropEdit.setTarget(RespPlot);
         end
         % Get the cursor mode object
         hTool = datacursormode(ancestor(EventSrc,'figure'));
         % Clear all data tips
         target = handle(EventSrc);
         if ishghandle(target,'axes')
            removeAllDataCursors(hTool,target);
         end
      case 'open'
         % Double-click: open editor
         PropEdit = PropEditor(RespPlot);
         PropEdit.setTarget(RespPlot);
   end
end

%--------------------------------------------------------------------------
function p = localManagePlotOption(PlotType,OptionsObject,Pref,NewPlot,h)
% Create and update plot options.

updateflag = true;
if NewPlot
   % New respplot
   switch PlotType
      case 'time'
         if isa(OptionsObject,'plotopts.IOTimePlotOptions')
            p = OptionsObject;
            updateflag = false;
         else
            p = plotopts.IOTimePlotOptions;
         end
      case 'frequency'
         if isa(OptionsObject,'plotopts.IOFrequencyPlotOptions')
            p = OptionsObject;
            updateflag = false;
         else
            p = plotopts.IOFrequencyPlotOptions;
            p.Title.String = getString(message('Controllib:plots:strIOData'));
         end
   end
   
   if updateflag
      % Update default options object
      mapCSTPrefs(p,Pref);
      
      % Override mag units for data freq plot in case of default
      % construction
      if isa(p,'plotopts.IOFrequencyPlotOptions')
         p.MagUnits = 'abs';
      end
      
      % Copy options to new object
      if ~isempty(OptionsObject)
         p = copyPlotOptions(p,OptionsObject);
      end
   end
else
   % Not a new data plot
   % get current plotoptions
   p = getoptions(h);
   % Copy specified options to current options
   if ~isempty(OptionsObject)
      p = copyPlotOptions(p,OptionsObject);
   end
end
