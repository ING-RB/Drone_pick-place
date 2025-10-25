function collinear = checkCollinear(next_arg)
%MATLAB Code Generation Library Function
% Parses keepcollinearpoints value.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

coder.inline('always')
coder.internal.assert(isscalar(next_arg) && (islogical(next_arg) || ...
        isnumeric(next_arg)), 'MATLAB:polyshape:collinearValue');

coder.internal.assert(double(next_arg)==1 || double(next_arg)==0, ...
            'MATLAB:polyshape:collinearValue');

if double(next_arg) == 1
    collinear = 't';
else
    collinear = 'f';
end
