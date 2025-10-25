function removeAxes(this, varargin)
% REMOVEAXES Remove a given number of rows and columns from the
% end of the existing Axes Grid
%
% removeAxes(AG, Property, Value)
%   Properties: 'NumRows', 'NumColumns'

%   Copyright 2015-2020 The MathWorks, Inc.

p = controllib.ui.plotmatrix.internal.ManageAxesGrid.localParseInputsForAddRemove(varargin{:});

addAxes_(this, -p.Results.NumRows, -p.Results.NumColumns);
end
