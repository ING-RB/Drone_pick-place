function out = tail(in, k)
%TAIL  Get last rows of tall array.
%   TAIL(X) displays the last eight rows of the tall array X in the
%   command window without storing a value.
%
%   TAIL(X,K) displays up to K rows from the end of the tall array X. If X
%   contains fewer than K rows, then the entire array is displayed.
%
%   Y = TAIL(X) or Y = TAIL(X,K) returns the last eight rows, or up to K
%   rows, of the tall array X.
%
%   Example:
%      % Create a datastore.
%      varnames = {'ArrDelay', 'DepDelay', 'Origin', 'Dest'};
%      ds = datastore('airlinesmall.csv', 'TreatAsMissing', 'NA', ...
%            'SelectedVariableNames', varnames)
%
%      % Create a tall table from the datastore.
%      tt = tall(ds);
%
%      % Extract the last 10 rows of the variable ArrDelay. 
%      l10 = tail(tt.ArrDelay,10)
%
%      % Collect the results into memory.
%      last10 = gather(l10)
%
%   See also: TAIL, TALL, TALL/HEAD, TALL/GATHER, TALL/TOPKROWS.

% Copyright 2016-2022 The MathWorks, Inc.


if nargin<2
    k = matlab.bigdata.internal.util.defaultHeadTailRows();
else
    % Check that k is a non-negative integer-valued scalar
    validateattributes(k, ...
        {'numeric'}, {'real','scalar','nonnegative','finite','integer'}, ...
        'tail', 'k')
end

outPA = matlab.bigdata.internal.lazyeval.extractTail(in.ValueImpl, k);
outAdapt = resetTallSize(in.Adaptor);

t = tall(outPA, outAdapt);

% As of R2023a, tail is also available for numeric arrays. It follows the
% same startegy to display and not set ANS when no output is requested.
if nargout==0
    disp(t)
else
    % Try to cache the result so that we don't have to revisit the original
    % data again in future.
    out = markforreuse(t);
end

end

