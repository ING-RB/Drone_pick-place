function [tS, tE] = uniqueColonForm(tX)
% Reduce a tall column vector of numeric integers into a sequence of colon
% start/stop points [s1:e1, s2:e2, ..]' representing the unique values of
% tX concisely.
%
%  [tS, tE] = uniqueColonForm(tX) returns a sequence of colon start/stop
%  points representing the unique values of tX. For each n, tX will contain
%  all of tS(n):tE(n). For example, if unique(tX) is 1:N, then tS will be 1
%  and tE will be N.

%   Copyright 2018 The MathWorks, Inc.

import matlab.bigdata.internal.adaptors.getAdaptorForType;
[tS, tE] = aggregatefun(@iGetColonFormForBlock, @iReduceColonForm, tX);
tS.Adaptor = setSmallSizes(getAdaptorForType('double'), 1);
tE.Adaptor = setSmallSizes(getAdaptorForType('double'), 1);
end

function [s, e] = iGetColonFormForBlock(x)
% Convert a block of raw data into a sequence of column forms.
assert(isnumeric(x) && iscolumn(x), ...
    'Assertion Failed: tX must be a numeric column vector');
x = unique(x);
if isempty(x)
    s = zeros(0,1);
    e = zeros(0,1);
    return;
end
gnumDiff = diff(x, 1, 1);
idx = [0; find(gnumDiff > 1); numel(x)];
s = x(idx(1:end-1) + 1);
e = x(idx(2:end));
end

function [s, e] = iReduceColonForm(s, e)
% Combine sequence forms from different origins together
if isempty(s)
    return;
end

[s, idx] = sort(s);
e = e(idx);

n = 1;
sCur = s(1);
eCur = e(1);
for ii = 2:numel(s)
    if s(ii) > eCur + 1
        s(n) = sCur;
        e(n) = eCur;
        n = n + 1;
        sCur = s(ii);
        eCur = e(ii);
    else
        eCur = max(eCur, e(ii));
    end
end
s(n) = sCur;
e(n) = eCur;
s(n+1:end) = [];
e(n+1:end) = [];
end
