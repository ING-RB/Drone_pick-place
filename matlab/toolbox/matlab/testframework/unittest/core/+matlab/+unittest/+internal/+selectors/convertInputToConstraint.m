function constraint = convertInputToConstraint(input,varargin)
%

% Copyright 2013-2017 The MathWorks, Inc.

import matlab.unittest.internal.mustBeTextScalar;
import matlab.unittest.internal.mustContainCharacters;

validateattributes(input,{'char','matlab.unittest.constraints.Constraint','string'},{});

if ~isa(input,'matlab.unittest.constraints.Constraint')
    mustBeTextScalar(input,varargin{:});
    mustContainCharacters(input,varargin{:});
    input=char(input);
end

constraint = matlab.unittest.internal.selectors.convertValueToConstraint(input);
end