function validateArgs(functionName, varargin)

% validateArgs Private function to validate args across functions.
%   Assumes that the function is functionName(identifier, version)
%
%   See also: matlab.addons.disableAddon,
%   matlab.addons.installedAddons,
%   matlab.addons.isAddonEnabled

% Copyright 2018 The MathWorks Inc.
try
narginchk(2, 3);
validateArg(varargin{1}, 'IDENTIFIER', 1);
if nargin > 2
validateArg(varargin{2}, 'VERSION', 2);
end
catch ME
    throwAsCaller(ME);
end

function validateArg(arg, name, inputnumber)
    if isa(arg, 'java.lang.String')
        validateattributes(arg, {'java.lang.String'}, {'scalar'}, functionName, name, inputnumber)
    else
        validateattributes(arg, {'char', 'string'}, {'scalartext'}, functionName, name, inputnumber)
    end
end

end