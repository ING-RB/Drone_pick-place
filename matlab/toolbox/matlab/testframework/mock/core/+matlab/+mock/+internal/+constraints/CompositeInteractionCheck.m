classdef CompositeInteractionCheck < matlab.mock.internal.constraints.InteractionCheck
    %

    % Copyright 2018 The MathWorks, Inc.
    
    properties (SetAccess=private)
        InteractionChecks (1,:) matlab.mock.internal.constraints.InteractionCheck;
    end
    
    methods
        function addInteractionCheck(composite, check)
            composite.InteractionChecks(end+1) = check;
        end
        
        function check(composite, actualInteraction)
            arrayfun(@(interactionCheck)interactionCheck.check(actualInteraction), composite.InteractionChecks);
        end
        
        function bool = isSatisfied(composite)
            bool = all(arrayfun(@isSatisfied, composite.InteractionChecks));
        end
        
        function bool = isDone(composite)
            bool = all(arrayfun(@isDone, composite.InteractionChecks));
        end
    end
end

