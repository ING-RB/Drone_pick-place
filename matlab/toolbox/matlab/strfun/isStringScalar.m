function tf = isStringScalar(s)
%

%   Copyright 2017-2023 The MathWorks, Inc.
%#codegen

narginchk(1,1);

tf = isstring(s) && isscalar(s);

end
