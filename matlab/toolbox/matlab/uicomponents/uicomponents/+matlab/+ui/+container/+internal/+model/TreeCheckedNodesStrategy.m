classdef TreeCheckedNodesStrategy < matlab.ui.container.internal.model.TreeNodeStrategy
    %TREECHECKEDNODESSTRATEGY This object performs validation for the
    %Tree component.  It will be subclassed to allow custom strategies
    %based on the selection state of the tree component.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    methods(Abstract)
        
       nodes = getCheckedDescendantsToAdd(obj, existingCheckedNodes)
       nodes = getCheckedAncestorsToAdd(obj, existingCheckedNodes, nodesToFilter)
    end
    
    methods
        function output = validateCheckedNodes(obj, checkedNodes)
            
            % Use Node utility for basic validation of nodes
            output = obj.validateTreeNodes(checkedNodes);
             
        end    
    end   
end

