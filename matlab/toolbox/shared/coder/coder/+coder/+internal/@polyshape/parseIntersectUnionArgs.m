function [has_clip, collinear, simplify] = parseIntersectUnionArgs(clipCanBeLine, varargin)
%MATLAB Code Generation Library Function
% Parse input args used in intersect and union operations

% Copyright 2022-2024 The MathWorks, Inc.

%#codegen

has_clip = false;
collinear = 'd';
simplify = true;
ninputs = numel(varargin);
if ninputs > 0
    if isa(varargin{1}, 'coder.internal.polyshape') || ...
            (clipCanBeLine && isnumeric(varargin{1}))
        %positional, must be the first entry
        has_clip = true;
        next_inp = 2;
    else
        next_inp = 1;
    end
    if ninputs >= next_inp
        [collinear, simplify] = coder.internal.polyshape.parseCollinear(varargin{next_inp:end});
    end
end