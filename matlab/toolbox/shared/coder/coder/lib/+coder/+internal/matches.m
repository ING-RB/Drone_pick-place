function y = matches(str,pattern,varargin)
%MATLAB Code Generation Private Function

%   Copyright 1984-2021 The MathWorks, Inc.
%#codegen

narginchk(2,4);
% Determine if any of the inputs has an ambiguous type from usage in
% Simulink (MATLAB Function block or a Stateflow chart)
if isAmbiguousType(str, pattern, varargin{:})
    y = coder.ignoreConst(false(1)); % Return scalar output
    return
end
if nargin > 2
    coder.internal.assert(nargin == 4,'MATLAB:string:OddNumberNVPairs');
    arg3 = varargin{1};
    arg4 = varargin{2};
    coder.internal.assert((isstring(arg3) && isscalar(arg3)) || ...
        (ischar(arg3) && isvector(arg3)), ...
        'MATLAB:string:ParameterNameMustBeTextScalar');
    coder.internal.assert( ...
        strncmpi(arg3,'IgnoreCase',eml_max(1,strlength(arg3))), ...
        'MATLAB:string:UnrecognizedParameterName',arg3,'''IgnoreCase''');
    coder.internal.assert((isnumeric(arg4) || islogical(arg4)) && ...
        isscalar(arg4), ...
        'MATLAB:string:MustBeScalarLogical','IgnoreCase');
    ignoreCase = arg4(1) ~= 0;
else
    ignoreCase = false;
end
assertSupported(str,'First argument');
assertSupported(pattern,'Search term');
if ischar(str)
    y = smatches(str,pattern,ignoreCase);
elseif iscell(str)
    y = false(size(str));
    for k = 1:numel(str)
        y(k) = smatches(str{k},pattern,ignoreCase);
    end
elseif isstring(str)
    y = false(size(str));
    for k = 1:numel(str)
        y(k) = smatches(str(k),pattern,ignoreCase);
    end
else
    y = false(size(str));
end

%--------------------------------------------------------------------------

function y = smatches(str,pattern,ignoreCase)
% Matches where str is a char array or string scalar. Pattern can be a cell
% array or string array.
coder.inline('always');
coder.internal.prefer_const(str,pattern,ignoreCase)
y = false;
if ischar(pattern)
    y = cmp(str,pattern,ignoreCase);
elseif iscell(pattern)
    for k = 1:numel(pattern)
        if cmp(str,pattern{k},ignoreCase)
            y = true;
            break
        end
    end
elseif isstring(pattern)
    for k = 1:numel(pattern)
        if cmp(str,pattern(k),ignoreCase)
            y = true;
            break
        end
    end
end

%--------------------------------------------------------------------------

function p = cmp(a,b,ignoreCase)
% Call strcmp or strcmpi.
coder.inline('always');
coder.internal.prefer_const(a,b,ignoreCase)
if ignoreCase
    p = strcmpi(a,b);
else
    p = strcmp(a,b);
end

%--------------------------------------------------------------------------

function assertSupported(str,argtxt)
coder.internal.prefer_const(str,argtxt);
coder.internal.assert(ischar(str) || isstring(str) || ...
    isCellArrayOfCharacterVectors(str), ...
    'MATLAB:string:MustBeCharCellArrayOrString',argtxt);

%--------------------------------------------------------------------------

function p = isCellArrayOfCharacterVectors(c)
% Determine if c is a cell array of character vectors.
% (Note that iscellstr(c) does not require elements to vectors.)
p = iscell(c);
if p
    for k = 1:numel(c)
        p = p & ischar(c{k}) & (isvector(c{k}) || isequal(c{k},''));
    end
end

%--------------------------------------------------------------------------

function result = isAmbiguousType(varargin)
for i = 1:nargin
    if isa(varargin{i}, 'double')
        result = coder.internal.isAmbiguousTypes;
        return
    end
end
result = false;

%--------------------------------------------------------------------------