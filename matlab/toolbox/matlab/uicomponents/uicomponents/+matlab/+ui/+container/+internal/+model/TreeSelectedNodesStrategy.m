classdef TreeSelectedNodesStrategy < matlab.ui.container.internal.model.TreeNodeStrategy
    %TREESELECTEDNODESSTRATEGY This object performs validation for the
    %Tree component.  It will be subclassed to allow custom strategies
    %based on the selection state of the tree component.
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    properties (Abstract)
        MaximumNumberOfSelectedNodes;
    end
    
    methods (Abstract, Access = {  ?matlab.ui.container.internal.model.TreeSelectedNodesStrategy, ... ...
            ?matlab.ui.container.internal.model.TreeComponent})
        
        % returns exception to be thrown when there is an issue with
        % validation of the SelectedNodes
        exceptionObject = getExceptionObject(obj);
        
        % Returns new valid of selected nodes valid after a strategy change
        calibratedNodes = calibrateSelectedNodesAfterSelectionStrategyChange(obj)
    end
    
    methods(Access = {  ?matlab.ui.container.internal.model.TreeSelectedNodesStrategy, ... ...
            ?matlab.ui.container.internal.model.TreeComponent})
        function output = validateSelectedNodes(obj, selectedNodes)
            
            % Use Node utility for basic validation of nodes
            output = obj.validateTreeNodes(selectedNodes, obj.MaximumNumberOfSelectedNodes);
             
        end    
    end   
end

