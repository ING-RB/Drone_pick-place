function h = axesrows(rlen,hndl,varargin)
% Returns instance of @axesrows class
%
%   H = AXESROWS(ROWLENGTHS, AXHANDLE) creates a sum(ROWLENGTHS)-by-1 grid
%   of subplots using the axes handles supplied in AXHANDLE.  The subplot
%   properties are inherited from the first axes in AXHANDLE.  Additional
%   axes are created if necessary. ROWLENGTHS is a two element rwo vector.
%
%   H = AXESROWS([ROWLENGTHS, NCOL, MSUB, NSUB], AXHANDLE) creates a
%   sum(ROWLENGTHS)-by-NCOL grid where each grid cell itself contains a
%   MSUB-by-NSUB array of subplots (nested subplots).
%
%   H = AXESROWS(ROWLENGTHS, FIGHANDLE) parents all the grid axes to the figure
%   with handle FIGHANDLE.

%   Copyright 2013-2015 The MathWorks, Inc.

% Create @axes instance and initialize
h = iodatapack.axesrows;

if numel(rlen)>2
    gridsize2 = rlen(3);
    gridsize3 = rlen(4:end);
    rlen = rlen(1:2);
else
    gridsize2 = 1;
    gridsize3 = [1 1];
end
h.RowLen = rlen;
gridsize = [sum(rlen), gridsize2, gridsize3];
h.Size = gridsize;

% Validate first input argument
if any(~ishghandle(hndl))
    ctrlMsgUtils.error('Controllib:plots:axesgrid1')
else
    hndl = handle(hndl);
end

if ishghandle(hndl,'figure')
    % Create axes
    Visibility = hndl.Visible;
    hndl = handle(axes('Parent',double(hndl),'Units', 'Normalized', ...
        'Visible','off','ContentsVisible','off'));
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hndl.Position;
elseif ishghandle(hndl,'axes')
    Visibility = hndl(1).Visible;
    % Disable Default Interactions
    disableDefaultInteractivity(hndl(1));
    % Position in Normalized units
    Position = hgconvertunits(ancestor(hndl(1),'figure'), ...
        hndl(1).Position, hndl(1).Units, 'normalized', hndl(1).Parent);
    % Hide axes, consistently with h.Visible=off initially
    set(hndl,'Visible','off','ContentsVisible','off')
else
    ctrlMsgUtils.error('Controllib:plots:axesgrid1')
end
GridState = hndl(1).XGrid;

% Size-independent settings
h.Parent = hndl(1).Parent;
h.AxesStyle = ctrluis.axesstyle(hndl(1));
h.UIContextMenu = uicontextmenu('Parent',ancestor(h.Parent,'figure'));
h.Title = get(hndl(1).Title,'String');
h.XLabel = get(hndl(1).XLabel,'String');
h.YLabel = get(hndl(1).YLabel,'String');
hTitle = hndl(1).Title;
hXLabel = hndl(1).XLabel;
hYLabel = hndl(1).YLabel;
h.TitleStyle = ctrluis.labelstyle(hTitle);
h.XLabelStyle = ctrluis.labelstyle(hXLabel);
h.YLabelStyle = ctrluis.labelstyle(hYLabel);
if gridsize(4)==1
    h.XUnits = '';
else
    h.XUnits = repmat({''},[gridsize(4) 1]);
end
if gridsize(3)==1
    h.YUnits = '';
else
    h.YUnits = repmat({''},[gridsize(3) 1]);
end
h.XUnits = repmat({''},[gridsize(4) 1]);
h.YUnits = repmat({''},[gridsize(3) 1]);
h.XScale = hndl(1).XScale;
h.YScale = hndl(1).YScale;
h.ColumnVisible = repmat({'on'},[gridsize(2)*gridsize(4) 1]);
h.ColumnLabelStyle = ctrluis.labelstyle(hTitle);
if strcmp(h.AxesStyle.XColorMode,'manual')
    h.ColumnLabelStyle.Color = h.AxesStyle.XColor;
end
h.ColumnLabelStyle.FontSize = h.AxesStyle.FontSize;
h.ColumnLabelStyle.Location = 'top';
h.RowVisible = repmat({'on'},[gridsize(1)*gridsize(3) 1]);
h.RowLabelStyle = ctrluis.labelstyle(hYLabel);
h.RowLabelStyle.FontWeight = hTitle.FontWeight;
if strcmp(h.AxesStyle.YColorMode,'manual')
    h.RowLabelStyle.Color = h.AxesStyle.YColor;
end
h.RowLabelStyle.FontSize = h.AxesStyle.FontSize;
h.RowLabelStyle.Location = 'top';
h.Position = Position; % RE: may be overwritten by SET below
h.LimitFcn = {@updatelims h};  % install default limit picker
h.LabelFcn = {@DefaultLabelFcn h};

% Turn DoubleBuffer=on to eliminate flashing with grids, labels,...
set(ancestor(h.Parent,'figure'),'DoubleBuffer','on')

% Size-dependent settings
initialize(h,hndl)

% Background axes (create last so that SUBPLOT does not pick it first)
h.BackgroundAxes = handle(axes('Parent',double(h.Parent),'Visible','off','HandleVisibility','off',...
    'Xlim',[0 1],'Ylim',[0 1],'XTick',[],'YTick',[],'XTickLabel',[],'YTickLabel',[],...
    'Position',Position,'HitTest','off'));
% Disable Default Interactions
disableDefaultInteractivity(h.BackgroundAxes);
% Labels
Labels = get(h.BackgroundAxes,{'Title','XLabel','YLabel'});
set([Labels{:}],'HorizontalAlignment','center','HitTest','off',...
    'Units','pixel')   % to facilitate position adjustment

% Add print behavior object to the background axes
bh = hggetbehavior(h.BackgroundAxes,'print');
bh.PrePrintCallback = {@LocalPrintCleanup h};
bh.PostPrintCallback = {@LocalPrintCleanup h};
% Do not serialize this behavior object during saves (g368390)
set(bh,'Serialize',false);

% User-defined properties
% RE: Maintain h.Visible=off in order to bypass all layout/visibility computations
% (achieved by removing Visible settings from prop/value list and factoring them into
%  the VISIBILITY variable)
[Visibility,varargin] = utGetVisibleSettings(h,Visibility,varargin);
h.set('Grid',GridState,varargin{:});

% Set visibility (if Visibility=on, this initializes the position/visibility of the HG axes)
h.Visible = Visibility;

% Activate limit manager
addlimitmgr(h)


%************Local Functions***********
function LocalPrintCleanup(~,data,h)
% Local function for print cleanup

if ishandle(h) % Protect against empty handle (g368390)
    if strcmpi(data,'PrePrintCallback')
        h.PrintLayoutManager = 'on';
    else
        h.PrintLayoutManager = 'off';
    end
end
