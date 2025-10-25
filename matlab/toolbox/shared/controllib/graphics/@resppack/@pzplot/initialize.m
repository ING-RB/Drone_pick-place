function initialize(this, ax, gridsize)
%  INITIALIZE  Initializes the @pzplot objects.
%  Author(s): K. Subbarao

%  Copyright 1986-2010 The MathWorks, Inc.

% Axes geometry parameters 
geometry = struct('HeightRatio',[],...
   'HorizontalGap', 16, 'VerticalGap', 16, ...
   'LeftMargin', 12, 'TopMargin', 20);

% Grid options
GridOptions = gridopts('pzmap');
GridOptions.Zlevel = -10;

% Create @axesgrid object
AxesGrid = ctrluis.axesgrid(gridsize, ax, ...
   'Visible',     'off', ...
   'Geometry',     geometry, ...
   'GridFcn',      {@LocalPlotGrid this},...
   'GridOptions',  GridOptions,...
   'LimitFcn',  {@updatelims this}, ...
   'Title',       getString(message('Controllib:plots:strPoleZeroMap')), ...
   'XLabel',      getString(message('Controllib:plots:strRealAxis')),...
   'YLabel',      getString(message('Controllib:plots:strImaginaryAxis')),...
   'XScale',      'linear',...
   'YScale',      'linear',...
   'XLimSharing', 'column', ...
   'YLimSharing', 'row', ...
   'XUnits', sprintf('%s^{-1}',this.TimeUnits),...
   'YUnits', sprintf('%s^{-1}',this.TimeUnits));
AxesGrid.LabelFcn = {@PZPlotLabelFcn AxesGrid};

this.AxesGrid = AxesGrid;

% Create background lines
LocalCreateBackgroundLines([], [], this)

% Generic initialization
init_graphics(this)

% Add standard listeners
addlisteners(this)

% Other listeners
AxStyle = AxesGrid.AxesStyle;
p_color = [findprop(AxStyle,'XColor'),findprop(AxStyle,'YColor')];
L = [handle.listener(this,[this.findprop('FrequencyUnits'),this.findprop('TimeUnits')],...
      'PropertyPostSet',{@LocalUpdateFreqUnits this});...
      handle.listener(AxStyle,p_color,...
      'PropertyPostSet',{@LocalSetColor this});...
      handle.listener(AxesGrid,'SizeChanged',{@LocalCreateBackgroundLines this});...
      handle.listener(AxesGrid,AxesGrid.findprop('Grid'),...
      'PropertyPostSet',{@LocalSetYaxisVis this});...
      handle.listener(this,this.findprop('Responses'),...
      'PropertyPostSet',{@LocalUpdateUnits this})];
this.addlisteners(L);

% PreLimitChangeListener
this.addlisteners(handle.listener(this.AxesGrid,'PreLimitChanged',{@LocalAdjustView this}));

%-------------------------- Local Functions ----------------------------


function LocalUpdateUnits(~,~,this)
% If any system is discrete do not display timeunits in labels
AxGrid = this.AxesGrid;
DisplayTimeUnits = true;
for ct = 1:length(this.Responses)
    r = this.Responses(ct);
    if isempty(r.DataSrc)
        Ts = r.Data.Ts;
    else
        Ts = r.DataSrc.Model.Ts;
    end
    if Ts ~= 0
        DisplayTimeUnits = false;
        break
    end
end

DataExceptionWarningState = this.DataExceptionWarning;
this.DataExceptionWarning= 'off'; % Prevent warnings when datafcn has not been set

if DisplayTimeUnits
    AxGrid.XUnits = sprintf('%s^{-1}',this.TimeUnits);
    AxGrid.YUnits = sprintf('%s^{-1}',this.TimeUnits);
else
    AxGrid.XUnits = '';
    AxGrid.YUnits = '';
end


this.DataExceptionWarning = DataExceptionWarningState;




function LocalUpdateFreqUnits(~,~,this)
% Update grid labels
AxGrid = this.AxesGrid;
GridState = AxGrid.Grid;
AxGrid.Grid = 'off';
AxGrid.Grid = GridState;
AxGrid.XUnits = sprintf('%s^{-1}',this.TimeUnits);
AxGrid.YUnits = sprintf('%s^{-1}',this.TimeUnits);
this.draw;
   

function LocalSetColor(~,eventdata,this)
% Adjust axis line color
set(this.BackgroundLines(:,:,[1 3]),'Color',eventdata.AffectedObject.XColor)
set(this.BackgroundLines(:,:,2),'Color',eventdata.AffectedObject.YColor)


function LocalSetYaxisVis(~,eventdata,this)
% Hide Y axis line when plotting S or Z grid
Yaxis = this.BackgroundLines(:,:,2);
if (numel(Yaxis)>1 || strcmp(eventdata.NewValue,'off'))
   set(Yaxis,'Visible','on')
else
   set(Yaxis,'Visible','off')
end


function GridHandles = LocalPlotGrid(this)
% Plot S or Z grid
% Determine domain
Sgrid = false;
Zgrid = false;
AxGrid = this.AxesGrid;
if prod(AxGrid.Size)==1 && ~isempty(this.Responses)
   for r=find(this.Responses,'Visible','on')'
      Ts = r.Data(1).Ts;
      Sgrid = Sgrid | (Ts==0);
      Zgrid = Zgrid | (Ts~=0);
   end
end
% Plot grid
if xor(Sgrid,Zgrid)
   % Well-defined domain
   % Update grid options
   % REVISIT: simplify
   GridOptions = AxGrid.GridOptions;
   GridOptions.FrequencyUnits = this.FrequencyUnits;
   GridOptions.TimeUnits = this.TimeUnits;
   AxGrid.GridOptions = GridOptions;
   if Sgrid
      GridHandles = AxGrid.plotgrid('sgrid');
   else
      GridHandles = AxGrid.plotgrid('zgrid');
      % Hide unit circle
      set(this.BackgroundLines(:,:,4),'Visible','off')
   end 
else
   % Mixed case: show regular grid
   set(getaxes(AxGrid),'XGrid','on','YGrid','on')
   GridHandles = [];
end  


function LocalCreateBackgroundLines(~, ~, this)
% Creates and updates background x-y lines (during axes grid resize)
% Delete existing lines
BL = this.BackgroundLines(:);
delete(BL(ishandle(BL)))
% Create new lines
AxGrid = this.AxesGrid;
ax = getaxes(AxGrid); % HG axes
AxStyle = AxGrid.AxesStyle;
gridsize = AxGrid.Size([1 2]);
% X and Y axis lines
Zlevel = -10;
LineSpan = infline(-Inf,Inf);
npts = length(LineSpan);
theta = 0:0.062831:2*pi;
cth = cos(theta);
sth = sin(theta);
for ct=prod(gridsize):-1:1
   % Real/Imag axes lines
   Xaxis(ct,1) = line(LineSpan,zeros(1,npts),Zlevel(ones(1,npts)),...
      'XlimInclude','off','YlimInclude','off',...
      'LineStyle',':','Color',AxStyle.YColor,...
      'HitTest','off','HandleVisibility','off','Parent',ax(ct));
   Yaxis(ct,1) = line(zeros(1,npts),LineSpan,Zlevel(ones(1,npts)),...
      'XlimInclude','off','YlimInclude','off',...
      'LineStyle',':','Color',AxStyle.XColor,...
      'HitTest','off','HandleVisibility','off','Parent',ax(ct));
   % Add (0,0) to make sure it is always included in the scene
   Origin(ct,1) = line(0,0,-20,'Parent',ax(ct),'Color',get(ax(ct),'Color'),...
      'HitTest','off','HandleVisibility','off');
   % Unit circle (always included)
   Circle(ct,1) = line(cth,sth,Zlevel(ones(1,length(theta))),...
      'Color',AxStyle.XColor,'Parent',ax(ct),'LineStyle',':',...
      'HitTest','off','HandleVisibility','off','Visible','off');
end
this.BackgroundLines = reshape([Xaxis Yaxis Origin Circle],[gridsize 4]);

function LocalAdjustView(~, ~, this)
% Prepares view for limit picker
% REVISIT: use FIND
for r=this.Responses(strcmp(get(this.Responses,'Visible'),'on'))'
   adjustview(r,'prelim')
end
