function wf = addwf(this, varargin)
%ADDWF  Adds a new @waveform to a given plot.
%
%   WF = ADDWF(PLOT,ROWINDEX,COLINDEX,NWAVES) creates a new @waveform 
%   WF for the @plot instance PLOT.  The index vectors ROWINDEX 
%   and COLINDEX specify the wave position in the axes grid, and NWAVES
%   specifies the number of individual waves in W.
%
%   WF = ADDWF(PLOT,DATASRC) adds a wave W that is hot-linked to the data 
%   source DATASRC.

%   WF = ADDWF(PLOT,...,VIEWTYPE) sets the view object to be used specified
%   by VIEWTYPE


%  Author(s): Bora Eryilmaz, P. Gahinet
%  Revised  : Kamesh Subbarao
%  Copyright 1986-2012 The MathWorks, Inc.

ViewType = [];

if ~isempty(varargin) && isa(varargin{end},'char')
    ViewType = varargin{end};
    varargin = varargin(1:end-1);
end

% Create a new @waveform object
wf = wavepack.waveform;
wf.Parent = this;

% Determine @waveform size (#rows, #columns, #waves)
nvargs = length(varargin);
switch nvargs
case 0
   % Spans full grid by default
   wf.RowIndex = 1:this.AxesGrid.Size(1);
   wf.ColumnIndex = 1:this.AxesGrid.Size(2);
   Nwaves = 1;
case 1
   % Data source supplied
   DataSrc = varargin{1};
   if ~isa(DataSrc, 'wrfc.datasource')
       ctrlMsgUtils.error('Controllib:plots:addwf1', ...
           'addwf(PLOT,DATASRC)','DATASRC','wrfc.datasource')
   end
   wf.DataSrc = DataSrc;
   wf.Name = DataSrc.Name;
   % Localize RowIndex and ColumnIndex
   localize(wf)
   Nwaves = getNumResp(DataSrc);
otherwise
   wf.RowIndex = varargin{1};
   wf.ColumnIndex = varargin{2};
   Nwaves = [varargin{3:end} ones(1,3-nvargs)];
end

% Initialize new @waveform
if isempty(ViewType)
    initialize(wf,Nwaves)
else
    initialize(wf,Nwaves,ViewType)
end

% Apply options
applyOptions(wf.View,this.Options)

% Add default tip (tip function calls MAKETIP first on data source, then on view)
fig = ancestor(wf.View(1).AxesGrid.Parent,'figure');
% Branching for axes parented to uifigure in Live Editor Task
if ~controllibutils.isLiveTaskFigure(fig)
    addtip(wf);
end

% Set style
% RE: Before adding wave to plot's wave list so that legend available to RC menus
SList = get(allwaves(this),{'Style'});
StyleList = cat(1,SList{:});
wf.Style = this.StyleManager.dealstyle(StyleList);  % use next available style

% Refresh Legends
this.AxesGrid.refreshlegends;
