function [xi, inbounds, outUpper] = areEvalPointsInBounds(xi, L, U)
%AREEVALPOINTSINBOUNDS Determine if evaluation points for KDE are in the support bounds
%   [XI, INBOUNDS] = AREEVALPOINTSINBOUNDS(XI, NUMPOINTS, L, U) determines 
%   which points in the vector/matrix XI are between the lower and upper bounds 
%   defined by vectors L and U. XI contains NUMPOINTS observations. This
%   syntax returns XI with all points outside of the bounds removed, and a 
%   logical vector INBOUNDS indicating which rows of the original XI were 
%   in bounds.
%
%   [XI, INBOUNDS, OUTUPPER] = AREEVALPOINTSINBOUNDS(XI, NUMPOINTS, L, U)
%   returns a logical vector, OUTUPPER, which indicates if points are
%   outside the upper bound.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2023 The MathWorks, Inc.

% Even for data that are unbounded, verify that data are 'in bounds'. This
% is to standardize behavior when the data are unbounded in one direction
% but one of the query points is Inf/-Inf
outUpper = ~all(xi<U,2);
inbounds = all(xi>L,2) & ~outUpper;
xi = xi(inbounds, :);
end