function E = rmse(F,A,varargin)
% Syntax:
%     E = rmse(F,A)
%     E = rmse(F,A,VECDIM)
%     E = rmse(___,NANFLAG)
%     E = rmse(___,Weights=W)
%
% For more information, see documentation

% Copyright 2022-2023 The MathWorks, Inc.

[D,isDimSet,dim,omitnan,~,isWeighted,w] = ...
    matlab.internal.math.parseErrorMetricsInput(false,F,A,varargin{:});

if isreal(D)
    X = D.^2;
else
    % We return a real result
    X = real(D).^2 + imag(D).^2;
end

if omitnan
    nanflag = 'omitnan';
else
    nanflag = 'includenan';
end

% Compute RMSE
if isWeighted
    X = w.*X;
    if isDimSet
        % Branching due to the edge case where X is empty.
        E = sqrt(sum(X,dim,nanflag) ./ sum(w,dim,nanflag));
    else
        E = sqrt(sum(X,nanflag) ./ sum(w,nanflag));
    end
else
    if isDimSet
        % Branching due to the edge case where X is empty.
        E = sqrt(mean(X,dim,nanflag));
    else
        E = sqrt(mean(X,nanflag));
    end
end

if omitnan && anynan(X)
    % Check if new NaNs were created during computation,
    % e.g. Inf - Inf, 0 * Inf, etc.
    % Do not omit NaNs caused by this computation (not missing data).
    if isWeighted
        isNaNMade = isnan(X) & ~isnan(w) & ~isnan(F) & ~isnan(A); 
    else
        isNaNMade = isnan(X) & ~isnan(F) & ~isnan(A);
    end
    E(any(isNaNMade,dim)) = NaN;
end
end