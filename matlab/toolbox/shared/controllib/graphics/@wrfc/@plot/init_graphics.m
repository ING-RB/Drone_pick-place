function init_graphics(this)
%INIT_GRAPHICS  Generic initialization of plot graphics.

%   Author(s): Bora Eryilmaz
%   Copyright 1986-2008 The MathWorks, Inc.

% Tag low-level HG axes
% RE: Needed to know if given axes associated with response (HOLD,..)
hgaxes = double(getaxes(this.AxesGrid));
for ct=1:numel(hgaxes)
   setappdata(hgaxes(ct),'WaveRespPlot',this);
end

% Initialize row/column labels
rclabel(this)

% Initialize the behavor of property editor and plot tool
this.initializeBehavior;

% Set response plot visibility
this.AxesGrid.Visible = this.Visible;

