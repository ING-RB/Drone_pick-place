function checkSameTallSize(varargin)
% Check whether a collection of non-tall input arguments have same tall
% size. Two arrays have same tall size if they have the same height.

%   Copyright 2019 The MathWorks, Inc.

height = size(varargin{1}, 1);
for ii = 2:nargin
    newHeight = size(varargin{ii}, 1);
    if newHeight ~= height
        matlab.bigdata.internal.throw(...
            message('MATLAB:bigdata:array:IncompatibleTallStrictSize'));
    end
end
end