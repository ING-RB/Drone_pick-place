function Axes = getAxes(this,flag)
% GETAXES Return a handle to all the axes in the core axes
% grid.

%   Copyright 2015-2020 The MathWorks, Inc.

% If Flag is passed in, the background axes is returned
if nargin == 2
    Axes = this.BackgroundAxes;
else
    Axes = getaxes(this.AxesGrid);
    
    if strcmpi(this.DiagonalAxesSharing,'XOnly')
        HistAx = getHistogramAxes(this);
        for ct = 1:length(HistAx)
            Axes(ct,ct) = HistAx(ct);
        end
    end
end
end
