classdef (Abstract) CustomChildrenContainer < handle
%

%   Copyright 2023 The MathWorks, Inc.

    methods (Abstract, Access=?matlab.graphics.primitive.world.GroupBase)
        actualContainer = getContainerForChild(obj, child)
    end
end
