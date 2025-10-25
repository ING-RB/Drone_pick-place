function E = rmse(F,A,varargin)
%RMSE Root-mean-square error for tall arrays.
%   E = RMSE(F,A)
%   E = RMSE(F,A,"all")
%   E = RMSE(F,A,DIM)
%   E = RMSE(F,A,VECDIM)
%   E = RMSE(...,NANFLAG)
%   E = RMSE(...,"Weights",W)
%
%   See also RMSE, TALL.

%   Copyright 2022-2023 The MathWorks, Inc.

[D,isDimSet,dim,omitnan,~,isWeighted,w] = parseTallErrorMetricsInput(false,F,A,varargin{:});

if omitnan
    nanflag = 'omitnan';
else
    nanflag = 'includenan';
end

% Start by calculating the error and squaring it.
X = elementfun(@iRealSquare, D);

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

if omitnan
    % Check if new NaNs were created during computation,
    % e.g. Inf - Inf, 0 * Inf, etc.
    % Do not omit NaNs caused by this computation (not missing data).
    if isWeighted
        isNaNMade = isnan(X) & ~isnan(w) & ~isnan(F) & ~isnan(A); 
    else
        isNaNMade = isnan(X) & ~isnan(F) & ~isnan(A);
    end
    if isDimSet
        setToNan = any(isNaNMade,dim);
    else
        setToNan = any(isNaNMade);
    end
    E = elementfun(@iRestoreNaNs, E, setToNan);
end

end


function X = iRealSquare(D)
% Get the squared magnitude, ensuring a real result.
if isreal(D)
    X = D.^2;
else
    X = real(D).^2 + imag(D).^2;
end
end

function E = iRestoreNaNs(E, setToNan)
% Helper to set elements of E to NaN where setToNaN is true.
E(setToNan) = NaN;
end
