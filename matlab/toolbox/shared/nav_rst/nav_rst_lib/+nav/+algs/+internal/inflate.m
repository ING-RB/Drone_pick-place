function inflatedMap = inflate(map, se)
%This function is for internal use only. It may be removed in the future.

%INFLATE Inflate binary occupancy grid
%   IM = inflate(MAP, SE) returns an N-by-M logical array of inflated map
%   from the N-by-M array of logical input map and a P-by-Q array of
%   logical structuring element SE.

%   Copyright 2014-2019 The MathWorks, Inc.

%#codegen

% For simulation use the mex-file
if isempty(coder.target) && islogical(map)
    % Run mex
    inflatedMap = nav.algs.internal.mex.inflate_logical(map, se);
elseif isempty(coder.target) && isa(map, 'int16')
    % Run mex
    inflatedMap = nav.algs.internal.mex.inflate_int16(map, se);
else
    % Run MATLAB-code
    inflatedMap = nav.algs.internal.impl.inflate(map, se);
end
