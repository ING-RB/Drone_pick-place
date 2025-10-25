classdef IView < handle
    %IController contains abstract methods and properties that all Read
    %Section View classes must implement.

    % Copyright 2022 The MathWorks, Inc.

    methods (Abstract)
        addFlushButtonToToolstrip(obj)
    end
end