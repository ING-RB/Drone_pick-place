function obj = setProperties(obj, narg, varargin)
%   This class is for internal use only. It may be removed in the future. 
%SETPROPERTIES set properties of obj using the PV pairs in varargin
%   A code generation compatible mechanism for setting constructor supplied
%   property value pairs or function name value pairs. Inputs are defined
%   below for constructor and function usage.
%
%   Constructor
%
%       obj      - Instance of the object
%       narg     - number of arguments passed to the constructor
%       varargin - Constructor arguments and, optionally, value-only
%                  properties
%
%   Function
%
%       obj      - Struct with parameter fields and default values
%       narg     - number of arguments passed to the function
%       varargin - Function arguments and, optionally, value-only inputs
%
%   % EXAMPLE 1: Assign object properties from PV pairs.
%   matlabshared.fusionutils.internal.setProperties(obj, nargin, ...
%       varargin{:});
%
%   % EXAMPLE 2: Assign object properties from PV pairs with two value-only
%   % inputs.
%   matlabshared.fusionutils.internal.setProperties(obj, nargin, ...
%       varargin{:}, 'Prop1', 'Prop2');
%
%   % EXAMPLE 3: Set values for function arguments from PV pairs.
%   paramStruct = matlabshared.fusionutils.internal.setProperties( ...
%       defaultStruct, nargin, varargin{:});
%
%   % EXAMPLE 4: Set values for function arguments from PV pairs with one
%   value-only input.
%   paramStruct = matlabshared.fusionutils.internal.setProperties( ...
%       defaultStruct, nargin, varargin{:}, 'Param1');

%   Copyright 2018-2020 The MathWorks, Inc.    

%#codegen

if (nargin > 1) && (narg > 0)
    nvoarg = numel(varargin) - narg;
    invalidSyntax = (nvoarg < 0) || ~isscalar(obj);
    coder.internal.errorIf(invalidSyntax, ...
        'MATLAB:system:invalidSetPropertiesSyntax');
    
    % Parse value-only properties.
    % Value-only properties of type char or string are NOT supported.
    for i=1:nvoarg
        arg = varargin{i};
        isValidParam = checkparameter(arg, obj);
        if isValidParam
            nvoarg = i - 1;
            break;
        end
        obj.(varargin{narg+i}) = arg;
    end
    
    % Parse PV-pair properties.
    oddNumOfPVArgs = (rem((narg-nvoarg), 2) ~= 0);
    coder.internal.errorIf(oddNumOfPVArgs, ...
        'MATLAB:system:invalidPVPairs');
   for i=(nvoarg+1):2:narg
       param = varargin{i};
       param = validateparameter(param, obj);
       obj.(param) = varargin{i+1};
   end
end

end

function param = validateparameter(param, obj)

[isValidParam, param] = checkparameter(param, obj);
coder.internal.errorIf(~isValidParam, 'MATLAB:system:invalidPVPairs');
end

function [isValidParam, param] = checkparameter(param, obj)

isValidParam = (isa(param, 'char') && (size(param, 1) == 1)) ...
    || (isa(param, 'string') && isscalar(param) && (param ~= ""));

% If the parameter is already invalid, it is not a string scalar, return
% immediately.
if ~isValidParam
    return;
end

if isstruct(obj)
    isValidParam = isValidParam && isfield(obj, param);
end

% Partial parameter string matching in MATLAB.
% Only check for partial string matching if one has not already been found.
if ~isValidParam && isempty(coder.target)
    [isValidParam, param] = checkPartialMatch(obj, param);
end

end

function [isValidParam, param] = checkPartialMatch(obj, param)
isValidParam = false;
if isstruct(obj)
    paramsList = fieldnames(obj);
else
    paramsList = properties(obj);
end
isMatch = startsWith(paramsList, param, 'IgnoreCase', true);
% Only allow for exactly one match. If the partial input matches 
% multiple parameters, the input is invalid.
isEmptyString = isempty(param) || (param == "");
if (nnz(isMatch) == 1) && ~isEmptyString
    param = paramsList{find(isMatch)};
    isValidParam = true;
end
end
