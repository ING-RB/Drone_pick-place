function[iqr,quartile1,quartile3] = datafuniqr(a)
% DATAFUNIQR Compute interquartile range for outlier functions and
% normalize. Return the iqr as well as the quartiles.  This implementation
% omits NaNs.

% Copyright 2020-2023 The MathWorks, Inc.

% Remove NaNs
b = filterslices(~isnan(a),a);

% Get the intervals containing the two quartiles via tall/histcounts.
[bins,posInBins] = percentileDataBin(b, [25,75]);

% We have reduced the problem to applying the quartiles formula on the
% first quartile interval and third quartile interval. This can be done
% in-memory, as we only need at most 4 entries of the tall column A.
[quartile1,quartile3] = clientfun(@iQuartilesClientfun, ...
    bins{1}, posInBins{1}, bins{2}, posInBins{2});

iqr = quartile3 - quartile1;
end
%--------------------------------------------------------------------------
function [quart1,quart3] = iQuartilesClientfun(b1,q1,b3,q3)
quart1 = iQuartileFormula(b1,q1); % First qartile
quart3 = iQuartileFormula(b3,q3); % Third quartile
end

%--------------------------------------------------------------------------
function quartile = iQuartileFormula(a12,xq)
if isempty(a12)
    % Empties: return same result as in-memory isoutlier.
    quartile = NaN(class(a12));
elseif isscalar(a12)
    % The quartile coincides with an actual entry of the tall column A, or
    % the data is scalar and so we just degenerate to that scalar value.
    quartile = a12;
else
    % The quartile is between two consecutive entries in the tall column A.
    quartile = interp1(a12,xq+1);
end
end