function E = mape(F,A,varargin)
%MAPE Mean absolute percentage error for tall arrays.
%   E = MAPE(F,A)
%   E = MAPE(F,A,"all")
%   E = MAPE(F,A,DIM)
%   E = MAPE(F,A,VECDIM)
%   E = MAPE(...,NANFLAG)
%   E = MAPE(...,ZEROFLAG)
%   E = MAPE(...,"Weights",W)
%
%   See also MAPE, TALL.

%   Copyright 2022-2023 The MathWorks, Inc.

[D,isDimSet,dim,omitnan,omitzero,isWeighted,w] = parseTallErrorMetricsInput(true,F,A,varargin{:});

X = abs(D./A); % abs guarantees a real result

if omitnan || omitzero
    nanflag = 'omitnan';
else
    nanflag = 'includenan';
end

if omitzero
    isInfMade = ~isfinite(X) & isfinite(D);
    X = elementfun(@iSetToNaN, X, isInfMade);
    if isWeighted
        w = elementfun(@iSetToNaN, w, isInfMade);
    end
end

% Compute MAPE
if isWeighted
    X = w.*X;
    if isDimSet
        % Branching due to the edge case where X is empty.
        E = sum(X,dim,nanflag) ./ sum(w,dim,nanflag);
    else
        E = sum(X,nanflag) ./ sum(w,nanflag);
    end
else
    if isDimSet
        % Branching due to the edge case where X is empty.
        E = mean(X,dim,nanflag);
    else
        E = mean(X,nanflag);
    end
end
E = E.*100;

if omitnan
    % Check if new NaNs were created during computation,
    % e.g. Inf - Inf, 0 * Inf, Inf / Inf, etc.
    % Do not omit NaNs caused by this computation (not missing data).
    if omitzero
        XisNaN = isnan(X) & ~isInfMade;
    else
        XisNaN = isnan(X);
    end
    if isWeighted
        isNaNMade = XisNaN & ~isnan(w) & ~isnan(F) & ~isnan(A); 
    else
        isNaNMade = XisNaN & ~isnan(F) & ~isnan(A);
    end
    if isDimSet
        setToNan = any(isNaNMade,dim);
    else
        setToNan = any(isNaNMade);
    end
    E = elementfun(@iSetToNaN, E, setToNan);
elseif omitzero
    % Include NaNs
    if isDimSet
        setToNan = any(isnan(X) & ~isInfMade,dim);
    else
        setToNan = any(isnan(X) & ~isInfMade);
    end
    E = elementfun(@iSetToNaN, E, setToNan);
end
end


function E = iSetToNaN(E, setToNan)
% Helper to set elements of E to NaN where setToNaN is true.
E(setToNan) = NaN;
end
