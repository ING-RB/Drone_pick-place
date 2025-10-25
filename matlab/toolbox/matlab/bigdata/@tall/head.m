function out = head(in, k)
%HEAD  Get first rows of tall array.
%   HEAD(X) displays the first eight rows of the tall array X in the
%   command window without storing a value.
%
%   HEAD(X,K) displays up to K rows from the beginning of the tall array X.
%   If X contains fewer than K rows, then the entire array is displayed.
%
%   Y = HEAD(X) or Y = HEAD(X,K) returns the first eight rows, or up to K
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
%      % Extract the first 10 rows of the variable ArrDelay. 
%      f10 = head(tt.ArrDelay,10)
%
%      % Collect the results into memory.
%      first10 = gather(f10)
%
%   See also: HEAD, TALL, TALL/TAIL, TALL/GATHER, TALL/TOPKROWS.

% Copyright 2016-2022 The MathWorks, Inc.

if nargin<2
    k = matlab.bigdata.internal.util.defaultHeadTailRows();
else
    % Check that k is a non-negative integer-valued scalar
    validateattributes(k, ...
        {'numeric'}, {'real','scalar','nonnegative','finite','integer'}, ...
        'head', 'k')
end

outPA = matlab.bigdata.internal.lazyeval.extractHead(in.ValueImpl, k);

% Try to propagate size information if we have any, otherwise leave unset
% in case there weren't 'k' rows.
outAdapt = resetTallSize(in.Adaptor);
if ~isnan(in.Adaptor.TallSize.Size)
    % Tall size known
    outAdapt.setTallSize(min(double(k), in.Adaptor.TallSize.Size));
    
elseif k==1 && in.Adaptor.isTallSizeGuaranteedNonZero()
    % Not known, but is at least 1
    outAdapt.setTallSize(1);
    
end

t = tall(outPA, outAdapt);

% As of R2023a, head is also available for numeric arrays. It follows the
% same startegy to display and not set ANS when no output is requested.
if nargout==0
    disp(t)
else
    % Try to cache the result so that we don't have to revisit the original
    % data again in future.
    out = markforreuse(t);
end

end
