function tol = getTolerance(Description)
% Centralized definition of default tolerances.

%   Copyright 1986-2018 The MathWorks, Inc.

%#codegen
switch Description
   case 'rank'
      % ltipack.getTolerance('rank')
      % Tolerance for rank decisions
      tol = pow2(-39);  % eps^(3/4);
end
