function initialize(this,hgaxes)
%INITIALIZE  Configures axes grid.

%   Copyright 2013-2022 The MathWorks, Inc.
nr = prod(this.Size([1 3]));  % total number of rows in axes grid
nc = prod(this.Size([2 4]));  % total number of columns in axes grid

% Create supporting plotarray instances
this.Axes = iodatapack.plotrows([this.RowLen, this.Size(2:4)], hgaxes(:));   % private
this.Axes4d = getaxes(this.Axes);  % array of HG axes of size GRIDSIZE
this.Axes2d = reshape(permute(this.Axes4d,[3 1 4 2]),[nr,nc]);

% Disable rotate 3D for the axes
this.disableRotate3D;

% Settings inherited from template axes
this.XLimMode = hgaxes(1).XLimMode;
this.YLimMode = hgaxes(1).YLimMode;
this.NextPlot = hgaxes(1).NextPlot;
this.ColumnLabel = repmat({''},[nc 1]);
this.RowLabel = repmat({''},[nr 1]);
this.RowLabelStyle.Interpreter = 'none';
this.ColumnLabelStyle.Interpreter = 'none';

% Configure axes
for k = 1:numel(this.Axes2d)
   if ~isa(this.Axes2d(k),'matlab.graphics.axis.decorator.NumericRuler')
      cla(this.Axes2d(k),'reset')
   end
end

Props = struct(this.AxesStyle);
Props = rmfield(Props,{'Color','XColor','YColor','GridColor'});

set(this.Axes2d,'Units','normalized','Box','on',...
   'linewidth', hgaxes(1).LineWidth, ...  
   'XtickMode','auto','YtickMode','auto',...
   'XScale',hgaxes(1).XScale,'YScale',hgaxes(1).YScale,...
   'Xlim',hgaxes(1).XLim,'Ylim',hgaxes(1).YLim,...
   'NextPlot',this.NextPlot,'UIContextMenu',this.UIContextMenu,...
   'XGrid','off','YGrid','off',Props);

% Set XColor
if strcmp(this.AxesStyle.XColorMode,"auto")
    xColor = "--mw-color-secondary";
else
    xColor = this.AxesStyle.XColor;
end
controllib.plot.internal.utils.setColorProperty(this.Axes2d(:),"XColor",xColor);

% Set YColor
if strcmp(this.AxesStyle.YColorMode,"auto")
    yColor = "--mw-color-secondary";
else
    yColor = this.AxesStyle.YColor;
end
controllib.plot.internal.utils.setColorProperty(this.Axes2d(:),"YColor",yColor);

% Set GridColor
if ~strcmp(this.AxesStyle.GridColorMode,"auto")
    controllib.plot.internal.utils.setColorProperty(this.Axes2d(:),"GridColor",this.AxesStyle.GridColor);
end


% Add listeners
addlisteners(this)

% Add bypass for TITLE, AXIS,...
addbypass(this)
