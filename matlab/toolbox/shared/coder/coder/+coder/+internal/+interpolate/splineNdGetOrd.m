function [k, l] = splineNdGetOrd(nd, vals, varargin)
% evaluation at scattered points

%   Copyright 2022 The MathWorks, Inc.

%#codegen
coder.internal.prefer_const(nd);
AUTOGRID = isempty(varargin);

% number of pieces/intervals
l = coder.nullcopy(zeros(1, nd, 'like', coder.internal.indexInt(1)));

% order, always 4 for a cubic spline
k = 4*ones(1, nd, coder.internal.indexIntClass());

if AUTOGRID
    l(:) = coder.internal.indexInt(size(vals)-1);

    for i = 1:nd
        if size(vals, i) <= 3
            l(i) = 1;
        end
        % If a dimension has less than 4 points its a line or parabola.
        if size(vals, i) == 3
            k(i) = 3;
        elseif size(vals, i) == 2
            k(i) = 2;
        end
    end
    
else
    
    for i = 1:nd
        if  numel(varargin{i}) > 3
            l(i) = numel(varargin{i}) - 1;
        else
            l(i) = 1;
        end
        % If a dimension has less than 4 points its a line or parabola.
        if numel(varargin{i}) == 3
            k(i) = 3;
        elseif numel(varargin{i}) == 2
            k(i) = 2;
        end

    end
    
end
