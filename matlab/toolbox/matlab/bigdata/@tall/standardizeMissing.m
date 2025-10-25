function B = standardizeMissing(A, indicators, varargin)
%STANDARDIZEMISSING  Convert to standard missing data
%
%   B = STANDARDIZEMISSING(A,INDICATORS)
%   B = STANDARDIZEMISSING(...,"DataVariables",DATAVARS)
%   B = STANDARDIZEMISSING(...,"ReplaceValues",TF)
%
%   Limitations:
%   1) 'DataVariables' cannot be specified as a function_handle
%   2) STANDARDIZEMISSING(A,___) does not support character vector variables
%   when A is a tall table or tall timetable.

%   See also: STANDARDIZEMISSING, TALL/ISMISSING.

% Copyright 2015-2021 The MathWorks, Inc.

tall.checkIsTall(upper(mfilename), 1, A);
narginchk(2, iMaxArgsForInput(A));

% Use the in-memory function to do basic syntax checking and tell us the
% expected output prototype
outProto = tall.validateSyntax(@standardizeMissing, [{A},{indicators},varargin], 'DefaultType', 'double');

A = tall.validateType(A, mfilename, ...
    {'numeric', 'logical', 'categorical', ... 
    'datetime', 'duration', ...
    'string', 'char', 'cellstr', ...
    'table', 'timetable'}, 1); 

tall.checkNotTall(upper(mfilename), 1, indicators, varargin{:});
checkMissingIndicators(indicators, mfilename);

if iIsTabular(A)
    % Validate the table variables selected by the DataVariables filter are
    % not character vectors
    [dataVars,replaceValues] = iGetParams(A, varargin{:});
    validateFcn = @(t) iErrorIfChar(t, dataVars);
    adaptor = A.Adaptor;
    A = elementfun(validateFcn, A);
    A.Adaptor = adaptor;
else 
    replaceValues = true;
end

% All inputs except the first are broadcast and the operation is
% effectively elementwise or slicewise in that it preserves non-tall dimensions.
if replaceValues
    % If replacing then B and A have same size and type (elementwise).
    B = elementfun(@(x) standardizeMissing(x, indicators, varargin{:}), A);
else
    % If not replacing then B will have variables appended but is still
    % slicewise.
    B = slicefun(@(x) standardizeMissing(x, indicators, varargin{:}), A);
end
B.Adaptor = matlab.bigdata.internal.adaptors.getAdaptor(outProto);
B.Adaptor = B.Adaptor.copyTallSize(A.Adaptor);
end

%--------------------------------------------------------------------------
function tf = iIsTabular(A)
inputClass = A.Adaptor.Class;
tf = any(strcmpi(inputClass, ["table", "timetable"]));
end

%--------------------------------------------------------------------------
function n = iMaxArgsForInput(in)
% Determine how many inputs are allowed for this input argument type
% (time)tables allow up to four inputs while all other types allow two.
if iIsTabular(in)
    n = 4;
else
    n = 2;
end
end

%--------------------------------------------------------------------------
function [dataVars,replaceValues] = iGetParams(A, varargin)
replaceValues = true;
dataVars = 1:width(A);
if isempty(varargin)
    return;
end

if rem(numel(varargin),2) ~= 0
    error(message('MATLAB:standardizeMissing:NameValuePairs'));
end

for i = 1:2:numel(varargin)
    if matlab.internal.math.checkInputName(varargin{i},'DataVariables')
        dataVars = checkDataVariables(A, varargin{i+1}, mfilename);
    elseif matlab.internal.math.checkInputName(varargin{i},'ReplaceValues')
        replaceValues = matlab.internal.datatypes.validateLogical(varargin{i+1}, "Replacevalues");
    else
        error(message('MATLAB:standardizeMissing:NameValueNames'));
    end
end
end

%--------------------------------------------------------------------------
function A = iErrorIfChar(A, dataVars)
isCharVar = varfun(...
    @ischar, A, ...
    'InputVariables', dataVars, ...
    'OutputFormat', 'uniform');

if any(isCharVar)
    error(message('MATLAB:bigdata:array:UnsupportedCharVar', upper(mfilename)));
end
end