function validVerbosity = validateVerbosityInput(verbosity,varargin)
% This function is undocumented and may change in a future release.

% Copyright 2018 The MathWorks, Inc.

if isstring(verbosity) || ischar(verbosity)
    validateattributes(verbosity, {'char','string'}, {'scalartext'},'',varargin{:});
else
    validateattributes(verbosity,{'numeric','matlab.unittest.Verbosity'},{'scalar'},'',varargin{:});
end

% Validate that the verbosity value is valid
validVerbosity = matlab.unittest.Verbosity(verbosity); 
end

