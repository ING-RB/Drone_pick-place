function showPeaksTable(p,state)
%showPeaksTable Show or hide peak marker table.
%   showPeaksTable(P,VIS) shows a table of peak values when VIS is true.
%   When VIS is false, the table is hidden and peak marker readouts are
%   made visible.  If omitted, VIS is true.

% Only show/hide for specified dataset if datasetIdx specified.
% If datasetIdx is empty or omitted, show/hide for all datasets.
%
% Set peak marker readout visibility
if nargin < 2
    state = true;
end
mAll = p.hPeakAngleMarkers;
if ~isempty(mAll)
    set(mAll,'Visible',~state);
end

% Show peak table
peakTabularReadout(p,state);
