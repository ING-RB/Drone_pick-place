%#codegen
    
% Copyright 2016-2020 The MathWorks, Inc.
    
function f = normalizedDistance(z, mu, sigma)
% normalize the distance z relative to the mean mu and the standard
% deviation sigma
  zd = z - mu;
  mahalanobisDistance = zd' / sigma * zd;
  f = mahalanobisDistance + matlabshared.tracking.internal.logDet(sigma);
end