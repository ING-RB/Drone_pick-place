function y = bitsliceget(u, lidx, ridx)
%

%   Copyright 2024 The MathWorks, Inc.
    
% support for integer input to bitsliceget

%#codegen
 
y = bitsliceget(fi(u), lidx, ridx);

end

