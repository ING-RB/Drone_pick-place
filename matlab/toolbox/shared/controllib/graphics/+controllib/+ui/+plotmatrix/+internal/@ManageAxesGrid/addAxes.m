function addAxes(this, varargin)
% ADDAXES Append a given number of rows and columns to the end
% of the existing Axes Grid
%
% addAxes(AG, Property, Value)
%   Properties: 'NumRows', 'NumColumns'

%   Copyright 2015-2020 The MathWorks, Inc.

p = controllib.ui.plotmatrix.internal.ManageAxesGrid.localParseInputsForAddRemove(varargin{:});

addAxes_(this, p.Results.NumRows, p.Results.NumColumns);
end
