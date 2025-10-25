classdef (Abstract) CanvasLeaveMixin < handle
%

%   Copyright 2024 The MathWorks, Inc.

    methods (Abstract, Access=?matlab.graphics.primitive.world.SceneNode)
        doCanvasLeave(obj);
    end
end
