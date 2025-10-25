function c = conv(a, b, shape)
%   Syntax:
%      w = conv(u,v)
%      w = conv(u,v,shape)
%
%   For more information, see documentation

%   Copyright 1984-2024 The MathWorks, Inc.

if ~isvector(a) || ~isvector(b)
    error(message('MATLAB:conv:AorBNotVector'));
end

if nargin < 3
    % compute as if both inputs are column vectors
    c = conv2(a(:),b(:));
else
    if ~ischar(shape) && ~(isstring(shape) && isscalar(shape))
        error(message('MATLAB:conv:unknownShapeParameter'));
    end
    if isstring(shape)
        shape = char(shape);
    end
    % compute as if both inputs are column vectors
    c = conv2(a(:),b(:),shape);
end

% restore orientation
if nargin < 3 || (shape(1) == 'f' || shape(1) == 'F') % shape 'full'
    if numel(a) > numel(b)
        if isrow(a)
            c = c.';
        end
    else
        if isrow(b)
            c = c.';
        end
    end
else
    if isrow(a)
        c = c.';
    end
end
