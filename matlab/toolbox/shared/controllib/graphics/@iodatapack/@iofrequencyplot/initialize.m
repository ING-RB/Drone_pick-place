function initialize(this, ax, iosize)
%INITIALIZE  Initializes the @iofrequencyplot objects.

%  Copyright 2013-2015 The MathWorks, Inc.

% Axes geometry parameters (main grid and 2x1 subgrid)
if iosize(1)==iosize(2)
   vg = {40;25};
else
   vg = {50;30};
end

geometry = struct(...
   'HeightRatio',{[];[.53 .47]},...
   'HorizontalGap',{40;0},...
   'VerticalGap',vg,...
   'LeftMargin',{0;0},...
   'TopMargin',{10;0});

% Create @axesgrid object
this.AxesGrid = iodatapack.axesrows([iosize, 1, 2, 1], ax, ...
   'Visible',     'off', ...
   'Geometry',    geometry, ...
   'LimitFcn',  {@updatelims this}, ...
   'LabelFcn',  {@LocalBuildLabels this}, ...
   'Title',    getString(message('Controllib:plots:strIOData')), ...
   'XLabel',   getString(message('Controllib:plots:strFrequency')),...
   'XScale',   'log',...
   'XUnit',  'rad/s',...
   'YLabel', {getString(message('Controllib:plots:strMagnitude')) ; getString(message('Controllib:plots:strPhase'))},...
   'YScale',   'linear',...
   'YUnit',  {'dB' ; 'deg'},...
   'RowVisible', this.io2rcvis('r',this.OutputVisible));  % to account for PhaseVisible state

% Generic initialization
init_graphics(this)

% Add listeners
addlisteners(this)

% PreLimitChangeListener
this.addlisteners(handle.listener(this.AxesGrid,'PreLimitChanged',{@LocalAdjustView this}));

%----------------- Local Functions --------------------------------------------

function LabelMap = LocalBuildLabels(this)
% Builds labels for Bode plots
AxGrid = this.AxesGrid;

% Initialize label map
LabelMap = struct(...
   'XLabel',sprintf('%s %s',AxGrid.XLabel,LocalUnitInfo(AxGrid.XUnits)),...
   'XLabelStyle',AxGrid.XLabelStyle,...
   'YLabel',[],...
   'YLabelStyle',AxGrid.YLabelStyle,...
   'ColumnLabel',{AxGrid.ColumnLabel},...
   'ColumnLabelStyle',AxGrid.ColumnLabelStyle,...
   'RowLabel',[],...
   'RowLabelStyle',[]);

% Y label and row labels
MagLabel = sprintf('%s%s',AxGrid.YLabel{1},LocalUnitInfo(AxGrid.YUnits{1}));
PhaseLabel = sprintf('%s%s',AxGrid.YLabel{2},LocalUnitInfo(AxGrid.YUnits{2}));
MagVis = strcmp(this.MagVisible,'on');
PhaseVis = strcmp(this.PhaseVisible,'on');

if prod(AxGrid.Size(1:2))>1
   % MIMO case: Mag and Phase go to the YLabel field
   LabelMap.RowLabel = AxGrid.RowLabel;   
   LabelMap.RowLabelStyle = AxGrid.RowLabelStyle;   
   if MagVis && PhaseVis
      LabelMap.YLabel = sprintf('%s ; %s',MagLabel,PhaseLabel);
   elseif MagVis
      LabelMap.YLabel = MagLabel;
   elseif PhaseVis
      LabelMap.YLabel = PhaseLabel;
   end
   
else
   % SISO case: Mag and Phase go to the RowLabel field
   LabelMap.YLabel = '';
   LabelMap.RowLabel = {MagLabel ; PhaseLabel};
   LabelMap.RowLabelStyle = AxGrid.YLabelStyle;   
end


function str = LocalUnitInfo(unit)
% Returns string capturing unit and transform info
if isempty(unit)
   str = '';
else
   str = sprintf(' (%s)',controllibutils.utXlateUnitsString(unit));
end

function LocalAdjustView(~, ~, this)
% Prepares view for limit picker
% REVISIT: use FIND
for r=this.Responses(strcmp(get(this.Responses,'Visible'),'on'))'
   adjustview(r,'prelim')
end