function zoomcp(this)
% zoomcp: Zoom on the critical point(-1,0) for the Nyquist plot
%
%   Example:
%       % Create Nyquist plot
%       h = nyquistplot(tf(100,[1,2,1]));
%       % Zoom on the critical point(-1,0)
%       zoomcp(h)
%       
%   See also: nyquistPlot

%   Copyright 2019 The MathWorks, Inc.

AxGrid = this.AxesGrid;
AxGrid.LimitManager = 'off';  %  disable listeners to HG axes limits
% Frame scene
updatelims(this,'critical')
% Notify of limit change
AxGrid.send('PostLimitChanged')
AxGrid.LimitManager = 'on';