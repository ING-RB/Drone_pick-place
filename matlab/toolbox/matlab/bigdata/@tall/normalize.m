function N = normalize(A,varargin)
%NORMALIZE   Normalize tall data.
%   N = NORMALIZE(A,DIM)
%   N = NORMALIZE(...,METHOD)
%   N = NORMALIZE(...,METHOD,METHODTYPE)
%   N = NORMALIZE(...,"DataVariables",DV)
%   N = NORMALIZE(...,"ReplaceValues",TF)
%
%   Limitations:
%   1) Normalization methods that require calculation of median or iqr 
%      along the first dimension are only supported for tall column 
%      vectors A. This includes ["zscore", "robust"], ["scale", "mad"], 
%      ["center", "median"], ["medianiqr"], and ["scale","iqr"]. 
%   2) The value of "DataVariables" cannot be a function handle.
%   3) The outputs C and S are not supported.
%   4) The "center" and "scale" methods cannot be specified at the same 
%      time.
%   5) The supported method types for "center" are: "mean", "median", or
%      a numeric scalar.
%   6) The supported method types for "scale" are: "std", "mad", "first",
%      or a numeric scalar.
%
%   See also NORM, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% First input must be a tall array. The rest must not.
tall.checkIsTall(mfilename, 1, A);
tall.checkNotTall(mfilename, 1, varargin{:});

[dim,method,methodType,dataVars,AisTabular,replaceValues] = parseInputs(A,varargin{:});

if AisTabular
    % Form a new table N with normalized data
    N = A;
    for vj = dataVars
        Aj = subsref(A, substruct('.', vj));
        Nj = normalizeArray(Aj,method,methodType,dim);
        N = subsasgn(N, substruct('.', vj), Nj);
    end

    if ~replaceValues
        % If not replacing, create a new table using only the modified
        % variables and then append to the original input.
        N = subselectTabularVars(N, dataVars);
        N = matlab.internal.math.appendDataVariables(A,N,"normalized");
    end
else
    N = normalizeArray(A,method,methodType,dim);
end

end
%--------------------------------------------------------------------------
function N = normalizeArray(A,method,methodType,dim)
% Normalization for arrays - always omit NaNs

if isempty(dim)
    % Reduction dimension is unknown. We will need to calculate both tall
    % and small normalization and select once we know.
    tallN = normalizeArrayInTallDim(A,method,methodType,1);
    smallN = normalizeArrayInSmallDim(A,method,methodType,dim);
    N = ternaryfun( size(A,1) == 1, smallN, tallN );
else
    % Known dimension
    if dim>1
        N = normalizeArrayInSmallDim(A,method,methodType,dim);
    else
        N = normalizeArrayInTallDim(A,method,methodType,dim);
    end
end
end

%--------------------------------------------------------------------------
function N = normalizeArrayInSmallDim(A,method,methodType,dim)
% Normalization for arrays - always omit NaNs
if isempty(dim)
    if isempty(methodType)
        N = slicefun(@(x) normalize(x,method), A);
    else
        N = slicefun(@(x) normalize(x,method,methodType), A);
    end
else
    if isempty(methodType)
        N = slicefun(@(x) normalize(x,dim,method), A);
    else
        N = slicefun(@(x) normalize(x,dim,method,methodType), A);
    end
end
N.Adaptor = A.Adaptor;
end

%--------------------------------------------------------------------------
function N = normalizeArrayInTallDim(A,method,methodType,dim)
% Normalization for arrays - always omit NaNs

if isequal("zscore", method)
    if isequal("std",methodType)
        N = (A - mean(A,dim,'omitnan')) ./ std(A,0,dim,'omitnan');
    else % "robust"
        % We are going to access A mutliple times (up to 13!), so cache it
        A = A.markforreuse();
        medA = A - median(A,dim,'omitnan');
        N = medA ./ median(abs(medA),dim,'omitnan');
    end
    
elseif isequal("norm", method)
    % In order to omit NaNs in this case fill NaNs with 0 to compute norms
    fillA = elementfun( @nan2zero, A );
    fillA.Adaptor = A.Adaptor;
    N = A./vecnorm(fillA,methodType,dim);
    
elseif isequal("center", method)
    if isequal("mean",methodType)
        N = A - mean(A,dim,'omitnan');
    elseif isequal("median",methodType)
        N = A - median(A,dim,'omitnan');
    else % numeric
        N = A - methodType;
    end
    
elseif isequal("scale", method)
    if isequal("std",methodType)
        N = A ./ std(A,0,dim,'omitnan');
    elseif isequal("mad",methodType)
        N = A ./ median(abs(A - median(A,dim,'omitnan')),dim,'omitnan');
    elseif isequal("first",methodType)
        Afirst = matlab.bigdata.internal.broadcast(head(A, 1));
        N = slicefun(@rdivide, A, Afirst);
    elseif isequal("iqr",methodType)
        N = A ./ datafuniqr(A);
    else % numeric
        N = A ./ methodType;
    end
    
elseif isequal("range", method)
    minA = min(A,[],dim);
    maxA = max(A,[],dim);
    N = rescale(A,methodType(1),methodType(2),'InputMin',minA,'InputMax',maxA);
    
elseif isequal("medianiqr", method)
    N = (A - median(A,dim,'omitnan')) ./ datafuniqr(A);
end

end

%--------------------------------------------------------------------------
function [dim,method,methodType,dataVars,aIsTabular,replaceValues] = parseInputs(A,varargin)
% Use in-memory data to check the syntax
tall.validateSyntax(@normalize, [{A},varargin], 'DefaultType', 'double');

% We only support double, single, table, timetable (just in case the type
% was unkown in validateSyntax).
allowedTypes = ["float", "table", "timetable"];
A = tall.validateTypeWithError(A, mfilename, 1, allowedTypes, "MATLAB:normalize:InvalidFirstInput");

argIdx = 1;
aIsTabular = ismember(A.Adaptor.Class, ["table" "timetable"]);
replaceValues = true;
if aIsTabular
    dim = 1;
    dataVars = 1:width(A);
else
    % Look for the dimension
    if nargin>=2 && (isnumeric(varargin{1}) || islogical(varargin{1}))
        dim = varargin{1};
        argIdx = argIdx + 1;
    else
        % Not specified. Must deduce.
        dim = matlab.bigdata.internal.util.deduceReductionDimension(A.Adaptor);
    end
    dataVars = [];
end

method = "zscore";
methodType = iGetDefaultMethodType(method);
while argIdx<=numel(varargin)
    if iMatchNameArg(varargin{argIdx}, "DataVariables")
        % Must be followed by variable specifiers
        dataVars = varargin{argIdx+1};
        dataVars = checkDataVariables(A, dataVars, 'normalize');
        argIdx = argIdx + 2;
    elseif iMatchNameArg(varargin{argIdx}, "ReplaceValues")
        if ~aIsTabular
            error(message("MATLAB:fillmissing:ReplaceValuesArray"))
        end
        replaceValues = matlab.internal.datatypes.validateLogical(varargin{argIdx+1}, "Replacevalues");
        argIdx = argIdx + 2;
    else
        % Must be a method.
        method = iCanonicalizeMethod(varargin{argIdx});
        argIdx = argIdx + 1;
        % See if the next arg specifies the type. This is the case so long
        % as the next argument is not 'datavariables'
        if argIdx <= numel(varargin) && ~iMatchNameArg(varargin{argIdx}, ["DataVariables","ReplaceValues"])
            methodType = iCanonicalizeMethodType(varargin{argIdx});
            argIdx = argIdx + 1;
        else
            % Set default methodType for this method
            methodType = iGetDefaultMethodType(method);
        end
    end
end

end

function x = nan2zero(x)
% Helper to force NaN's in the data to be zero
x(isnan(x)) = 0;
end

function methodType = iGetDefaultMethodType(method)
% Return the default methodType to use for a given method
switch lower(method)
    case "norm"
        methodType = 2;
    case "zscore"
        methodType = "std";
    case "center"
        methodType = "mean";
    case "scale"
        methodType = "std";
    case "range"
        methodType = [0,1];
    case "medianiqr" % "medianiqr" doesn't allow a type
        methodType = [];
end
end

function method = iCanonicalizeMethod(method)
% Canonicalize method names (validaetSyntax should already have weeded out
% illegal ones).
allowedMethods = ["norm" "zscore" "center" "scale" "range" "medianiqr"];
method = allowedMethods(startsWith(allowedMethods, method, "ignorecase", true));
assert(isscalar(method), "Shouldn't be possible to get here with an invalid method: "+string(method))
end

function methodType = iCanonicalizeMethodType(methodType)
% Canonicalize method type (validateSyntax should already have weeded out
% illegal ones).
if matlab.internal.datatypes.isScalarText(methodType)
    allowedTypes = ["std" "mean" "mad" "median" "first" "robust" "iqr"];
    methodType = allowedTypes(startsWith(allowedTypes, methodType, "ignorecase", true));
    assert(isscalar(methodType), "Shouldn't be possible to get here with an invalid methodType")
end
end

function tf = iMatchNameArg(arg, name)
% Performs case-insensitive partial matching of arg to name
tf = isNonTallScalarString(arg) && any(startsWith(name, arg, 'IgnoreCase', true));
end
