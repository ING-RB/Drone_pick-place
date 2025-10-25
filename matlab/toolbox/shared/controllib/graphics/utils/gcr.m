function h = gcr(ax)
%GCR  Gets @respplot handle associate with given HG axes.
%
%   H = GCR returns a @respplot handle if the current axes (GCA)
%   contains a response plot, and H=[] otherwise.
%
%   H = GCR(AX) returns the handle of the response plot contained
%   in the HG axes AX.
%
%   See also GCA.

%   Copyright 1986-2002 The MathWorks, Inc.

if nargin==0
    ax = gca;
end
if isappdata(ax,'WaveRespPlot')
    % Find a wrfc (resppack) based plot that contains gca
    h = getappdata(ax,'WaveRespPlot');
    if ~isa(h,'wrfc.plot')
        h = [];
    end
elseif ~isempty(ancestor(ax,'controllib.chart.internal.foundation.AbstractPlot'))
    % Find a controllib.chart.* based plot that contains gca
    h = ancestor(ax,'controllib.chart.internal.foundation.AbstractPlot');
else
    h = [];
end