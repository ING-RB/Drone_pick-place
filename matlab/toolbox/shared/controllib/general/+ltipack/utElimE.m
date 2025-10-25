function [a,b] = utElimE(a,b,e)
% Helper to go from descriptor to explicit
% (assuming E is nonsingular)

%   Copyright 1986-2020 The MathWorks, Inc.
%#codegen
if ~isempty(e)
   [nx,nu] = size(b);
   if isempty(coder.target)
      x = matlab.internal.math.nowarn.mldivide(e,[a,b]);
   else
      x = e\[a,b];
   end
   a = x(:,1:nx);
   b = x(:,nx+1:nx+nu);
end
