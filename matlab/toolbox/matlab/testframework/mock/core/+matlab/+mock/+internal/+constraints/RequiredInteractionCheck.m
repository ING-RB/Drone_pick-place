classdef RequiredInteractionCheck < matlab.mock.internal.constraints.InteractionCheck
    %

    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess=private)
        InteractionsThatDidNotOccur;
    end
    
    methods
        function check = RequiredInteractionCheck(requiredInteractions)
            check.InteractionsThatDidNotOccur = requiredInteractions;
        end
        
        function check(interactionCheck, actualInteraction)
            remainingInteractions = interactionCheck.InteractionsThatDidNotOccur;
            mask = false(size(remainingInteractions));
            
            for idx = 1:numel(remainingInteractions)
                mask(idx) = actualInteraction.describedBy(remainingInteractions(idx));
            end
            
            interactionCheck.InteractionsThatDidNotOccur(mask) = [];
        end
        
        function bool = isDone(interactionCheck)
            bool = interactionCheck.isSatisfied;
        end
        
        function bool = isSatisfied(interactionCheck)
            bool = isempty(interactionCheck.InteractionsThatDidNotOccur);
        end
    end
end

