function wf = addwf(this, varargin)
%ADDWF  Adds a new @iowave to a given plot.
%
%   WF = ADDWF(PLOT,INPUTINDEX,OUTPUTINDEX) creates a new @waveform
%   WF for the @plot instance PLOT.  The index vectors ROWINDEX
%   and COLINDEX specify the wave position in the axes grid.
%
%   WF = ADDWF(PLOT,DATASRC) adds a wave W that is hot-linked to the data
%   source DATASRC.

%   WF = ADDWF(PLOT,...,VIEWTYPE) sets the view object to be used specified
%   by VIEWTYPE.

%  Copyright 2013 The MathWorks, Inc.

ViewType = [];

if ~isempty(varargin) && isa(varargin{end},'char')
   ViewType = varargin{end};
   varargin = varargin(1:end-1);
end

% Create a new @waveform object
wf = iodatapack.iowave;
wf.Parent = this;

% Determine @waveform size (#rows, #columns, #waves)
nvargs = length(varargin);
switch nvargs
   case 0
      % Spans full grid by default
      wf.RowIndex = 1:this.AxesGrid.Size(1);
      wf.ColumnIndex = 1:this.AxesGrid.Size(2);
      wf.InputIndex = 1:this.IOSize(2);
      wf.OutputIndex = 1:this.IOSize(1);
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
      % Localize InputIndex and OutputIndex
      localize(wf)
      Nwaves = 1;
   otherwise
      wf.InputIndex = varargin{1};
      wf.OutputIndex = varargin{2};
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
addtip(wf)

% Set style
% RE: Before adding wave to plot's wave list so that legend available to RC menus
SList = get(allwaves(this),{'Style'});
StyleList = cat(1,SList{:});
wf.Style = this.StyleManager.dealstyle(StyleList);  % use next available style

% Refresh Legends
this.AxesGrid.refreshlegends;
