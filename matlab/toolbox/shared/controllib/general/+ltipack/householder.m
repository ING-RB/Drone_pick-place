function [v,w,tau] = householder(x)
% Computes v,w and tau such that P = I - v*w' is unitary and Px = -tau * e1.
% Note: In the form P = I - beta*v*v',
%       beta = 2/(v'*v) = 1/(mu*(mu+|x1|) = 1/(tau'*v1) with mu=||x||

%   Copyright 2020 The MathWorks, Inc.
%#codegen
mu = norm(x);
if mu==0
   v = x;  w = x;  tau = mu;
else
   % Normalize x to keep norms of v,w close to 1 and avoid underflow/overflow
   x = x/mu;
   x1 = x(1);
   mx1 = abs(x1);
   if mx1==0
      s = ones(1,'like',x);
   else
      s = x1/mx1;  % watch for complex x1
   end
   v = x;
   v(1) = x1 + s;
   w = v/(1+mx1);
   tau = s * mu;
end