%

% Copyright 2014-2018 The MathWorks, Inc.

classdef DataTipEvent < matlab.mixin.SetGet
    properties
        Target
        Position
    end

    properties(Hidden)
        DataIndex
        InterpolationFactor
        % Interpreter property of the datacursor tip
        Interpreter
    end

    properties(SetAccess = private, Hidden)
        DataTipHandle
    end

    methods
        function hThis = DataTipEvent(hDatatip)
            if nargin > 1
                hThis.DataTipHandle = hDatatip;
            end
        end
    end
end
