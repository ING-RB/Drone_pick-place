function [collinear, simplify] = parseCollinear(varargin)
%MATLAB Code Generation Library Function
% Parses keepcollinearpoints value.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

ninputs = numel(varargin);
coder.internal.assert(mod(ninputs, 2) == 0, 'MATLAB:polyshape:nameValuePairError');
collinear = 'd';
simplify = true;
for k=1:2:ninputs
    this_arg = varargin{k};
    next_arg = varargin{k+1};
    coder.internal.assert(coder.internal.isConst(this_arg) && coder.internal.isCharOrScalarString(this_arg), ...
        'MATLAB:polyshape:collinearParameter');

    %requires minimum 1 char for matching
    isSimplifyNV = strncmpi(this_arg, 'Simplify', max(1, strlength(this_arg)));
    isKCPtsNV = strncmpi(this_arg, 'KeepCollinearPoints', max(1, strlength(this_arg)));
    coder.internal.assert(isSimplifyNV || isKCPtsNV, ...
        'MATLAB:polyshape:collinearParameter');
    
    if isSimplifyNV
        coder.internal.assert(isscalar(next_arg) && ...
            (islogical(next_arg) || isnumeric(next_arg)), ...
            'MATLAB:polyshape:simplifyValue');
        coder.internal.assert(double(next_arg)==0 || double(next_arg)==1, ...
            'MATLAB:polyshape:simplifyValue');
        simplify = logical(next_arg);
    end
    if isKCPtsNV
        collinear = coder.internal.polyshape.checkCollinear(next_arg);
    end
end