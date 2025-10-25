function checkCompatibleHeight(varargin)
% Check whether a collection of non-tall input arguments have compatible
% height. Two arrays have compatible height if they have the same height,
% or one input has height one.

%   Copyright 2018 The MathWorks, Inc.

height = size(varargin{1}, 1);
for ii = 2:nargin
    newHeight = size(varargin{ii}, 1);
    if newHeight == 1
        % Do nothing
    elseif height == 1
       height = newHeight;
    elseif newHeight ~= height
        matlab.bigdata.internal.throw(...
            message('MATLAB:bigdata:array:IncompatibleTallSize'));
    end
end
end
