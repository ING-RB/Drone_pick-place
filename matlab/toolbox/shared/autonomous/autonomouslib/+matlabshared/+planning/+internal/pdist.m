function pairWiseDist = pdist(X, Y)
%This function is for internal use only. It may be removed in the future.

%pdist Utility function to compute pairwise Euclidean distances. This code  
%   has been used by the matlabshared.planning.internal.StraightLineConnection
%   & matlabshared.planning.internal.StraightLinePathSegment.

% Copyright 2018 The MathWorks, Inc.

pairWiseDist = sqrt(sum((X - Y).^2, 2));
end