classdef InteractionCheck < handle & matlab.mixin.Heterogeneous
    %

    % Copyright 2018 The MathWorks, Inc.
    
    methods (Abstract)
        check(interactionCheck, actualInteraction);
        bool = isDone(interactionCheck);
        bool = isSatisfied(interactionCheck);
    end
end

