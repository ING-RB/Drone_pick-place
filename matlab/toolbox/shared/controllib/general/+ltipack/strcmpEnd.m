function isMatch = strcmpEnd(str,S,N)
% Matches STR against end of the strings in S. N specifies
% the minimum number of characters to be matched for each 
% string in S.

%   Copyright 2011-2012 The MathWorks, Inc.
nS = numel(S);
if nargin<3
   N = repmat(numel(str),[nS,1]);
else
   N = max(N,numel(str));
end
str = fliplr(str);
isMatch = false(nS,1);
for ct=1:nS
   isMatch(ct) = strncmp(str,fliplr(S{ct}),N(ct));
end