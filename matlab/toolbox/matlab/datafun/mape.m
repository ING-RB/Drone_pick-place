function E = mape(F,A,varargin)
% Syntax:
%     E = mape(F,A)
%     E = mape(F,A,VECDIM)
%     E = mape(___,NANFLAG)
%     E = mape(___,ZEROFLAG)
%     E = mape(___,Weights=W)
%
% For more information, see documentation

% Copyright 2022-2023 The MathWorks, Inc.

[D,isDimSet,dim,omitnan,omitzero,isWeighted,w] = ...
    matlab.internal.math.parseErrorMetricsInput(true,F,A,varargin{:});

X = abs(D./A); % abs guarantees a real result

if omitnan || omitzero
    nanflag = 'omitnan';
else
    nanflag = 'includenan';
end

if omitzero
    isInfMade = ~isfinite(X) & isfinite(D);
    X(isInfMade) = NaN;
    w(isInfMade) = NaN;
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

if omitnan && anynan(X)
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
    E(any(isNaNMade,dim)) = NaN;
elseif omitzero
    % Include NaNs
    E(any(isnan(X) & ~isInfMade,dim)) = NaN;
end
end