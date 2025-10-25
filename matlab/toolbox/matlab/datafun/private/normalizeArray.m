function [N,C,S] = normalizeArray(A,method,methodType,dim,method2,methodType2,AisTabular)
% Shared normalization computation function for NORMALIZE and GROUPTRANSFORM

%   Copyright 2021-2024 The MathWorks, Inc.

% Only check first method since "center" and "scale" have same requirements
checkSupportedArray(A,method,methodType,AisTabular);
if ~isempty(method2)
    if method == "center"
        % Find center
        C = centerArray(A,methodType,dim);
        % Find scale
        S = scaleArray(A,methodType2,dim);
    else
        % Find center
        C = centerArray(A,methodType2,dim);
        % Find scale
        S = scaleArray(A,methodType,dim);
    end
    N = (A - C) ./ S;
elseif isequal("zscore", method)
    if isequal("std",methodType)
        [S, C] = std(A,0,dim,'omitnan');
    else % "robust"
        C = median(A,dim,'omitnan');
        S = median(abs(A - C),dim,'omitnan');
    end
    N = (A - C) ./ S;
elseif isequal("norm", method)
    % In order to omit NaNs in this case fill NaNs with 0 to compute norms
    fillA = A;
    fillA(isnan(fillA)) = 0;
    S = vecnorm(fillA,methodType,dim);
    C = zeros("like",S);
    N = A./S;
elseif isequal("center", method)
    C = centerArray(A,methodType,dim);
    S = ones("like",C);
    N = A - C;
elseif isequal("scale", method)
    S = scaleArray(A,methodType,dim);
    C = zeros("like",S);
    N = A ./ S;
elseif isequal("range", method)
    minA = min(A,[],dim);
    maxA = max(A,[],dim);
    if ~isfloat(A)
        minA = double(minA);
        maxA = double(maxA);
    end
    if ~isfloat(methodType)
        methodType = double(methodType);
    end
    a = methodType(1);
    b = methodType(2);
    [N,C,S] = matlab.internal.math.rescaleKernel(A,a,b,minA,maxA);
elseif isequal("medianiqr", method)
    C = median(A,dim,'omitnan');
    S = iqr(A,dim);
    N = (A - C) ./ S;
end
end

%--------------------------------------------------------------------------
function C = centerArray(A,methodType,dim)
if isequal("mean",methodType)
    C = mean(A,dim,'omitnan');
elseif isequal("median",methodType)
    C = median(A,dim,'omitnan');
else % numeric
    C = methodType;
end
end

%--------------------------------------------------------------------------
function S = scaleArray(A,methodType,dim)
if isequal("std",methodType)
    S = std(A,0,dim,'omitnan');
elseif isequal("mad",methodType)
    S = median(abs(A - median(A,dim,'omitnan')),dim,'omitnan');
elseif isequal("first",methodType)
    if isempty(A)
        S = 1;
    else
        ind = repmat({':'},ndims(A),1);
        ind{dim} = 1;
        S = A(ind{:});
    end
elseif isequal("iqr",methodType)
    S = iqr(A,dim);
else % numeric
    S = methodType;
end
end

%--------------------------------------------------------------------------
function checkSupportedArray(A,method,methodType,AisTabular)
% Parse input A
if isequal("range",method)
    if (~(isnumeric(A) || islogical(A)) || ~isreal(A))
        if AisTabular
            error(message('MATLAB:normalize:UnsupportedTableVariableRange'));
        else
            error(message('MATLAB:normalize:InvalidFirstInputRange'));
        end
    end
elseif isequal("zscore",method) && isequal("robust",methodType)
    if ~isfloat(A) || ~isreal(A)
        if AisTabular
            error(message('MATLAB:normalize:UnsupportedTableVariableRobust'));
        else
            error(message('MATLAB:normalize:InvalidFirstInputRobust'));
        end
    end
else
    if ~isfloat(A)
        if AisTabular
            error(message('MATLAB:normalize:UnsupportedTableVariable'));
        else
            error(message('MATLAB:normalize:InvalidFirstInput'));
        end
    end
end
end