function [Xout, Yout] = checkPointArray(param, varargin)
%MATLAB Code Generation Library Function
% Validate size and type of the input vertices to the polyshape

%   Copyright 2022-2023 The MathWorks, Inc.

%#codegen

narginchk(2, 5);
count_extra = 0;
extra_args = cell(2, 1);
for i=1:numel(varargin)
    coder.internal.assert(isnumeric(varargin{i}), param.errorValue);
    coder.internal.errorIf(issparse(varargin{i}), 'MATLAB:polyshape:sparseError');
    count_extra = count_extra+1;
    extra_args{count_extra} = varargin{i};
end

if count_extra == 1
    XY = extra_args{1};
    sz = size(XY);

    coder.internal.errorIf(numel(XY)==0,param.errorOneInput);
    if param.one_point_only
        coder.internal.assert(isequal(sz, [1 2]), param.errorOneInput);
    else
        coder.internal.assert(numel(sz)==2 && sz(2) == 2, param.errorOneInput);
    end
    X = XY(:, 1);
    Y = XY(:, 2);
else
    X1 = extra_args{1};
    Y1 = extra_args{2};
    coder.internal.assert(isequal(size(X1), size(Y1)), param.errorTwoInput);
    coder.internal.errorIf(isempty(X1), param.errorTwoInput);
    coder.internal.errorIf(~isscalar(X1) && param.one_point_only, param.errorTwoInput);

    if coder.internal.isConstTrue(isvector(X1))
        if coder.internal.isConstTrue(isrow(X1))
            X = X1';
            Y = Y1';
        else
            X = X1;
            Y = Y1;
        end
    else
        if isrow(X1)
            X = X1';
            Y = Y1';
        else
            X = X1;
            Y = Y1;
        end
    end
    coder.internal.assert(iscolumn(X), param.errorTwoInput);

end
coder.internal.assert(isnumeric(X) && isnumeric(Y) && isreal(X) && ...
    isreal(Y), param.errorValue);

coder.internal.assert(param.allow_inf || ...
    coder.internal.vAllOrAny('all', X, @(x)~isinf(x), true) && ...
    coder.internal.vAllOrAny('all', Y, @(x)~isinf(x), true), ...
    param.errorValue);

coder.internal.assert(param.allow_nan || ...
    coder.internal.vAllOrAny('all', X, @(x)~isnan(x), true) && ...
    coder.internal.vAllOrAny('all', Y, @(x)~isnan(x), true), ...
    param.errorValue);

Xout = double(X);
Yout = double(Y);
