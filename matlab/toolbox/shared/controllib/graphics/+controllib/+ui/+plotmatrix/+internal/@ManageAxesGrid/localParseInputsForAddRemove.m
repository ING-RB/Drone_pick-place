function p = localParseInputsForAddRemove(varargin)
% Parse the inputs passed to addAxes(), removeAxes() methods
%   Properties: 'NumRows', 'NumColumns'

%   Copyright 2015-2020 The MathWorks, Inc.

p = inputParser;

paramName = 'NumRows';
default = 0;
addParameter(p, paramName, default, @controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn);

paramName = 'NumColumns';
default = 0;
addParameter(p, paramName, default, @controllib.ui.plotmatrix.internal.ManageAxesGrid.localCheckFcn);

parse(p, varargin{:});
end
