function flag = isPositiveDefinite(B)
%This function is for internal use only. It may be removed in the future.

%ISPOSITIVEDEFINITE Returns a flag that indicates whether B is a positive 
%   definite matrix (true) or not (false)

%   Copyright 2016-2019 The MathWorks, Inc.

%#codegen

[~, p] = chol(B, 'lower');
flag = (p == 0);    

end
