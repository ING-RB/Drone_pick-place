classdef ZeroToOneCheckBoxTreeSelectionStrategy < matlab.ui.container.internal.model.TreeSelectedNodesStrategy
    %ZEROTOONECHECKBOXTREESELECTIONSTRATEGY Selection strategy for check
    %box tree
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties
        MaximumNumberOfSelectedNodes = 1;
    end
    
    methods
        function obj = ZeroToOneCheckBoxTreeSelectionStrategy(tree)
            obj@matlab.ui.container.internal.model.TreeSelectedNodesStrategy(tree);
        end
        
    end
    methods(Access = {  ?matlab.ui.container.internal.model.TreeSelectedNodesStrategy, ... ...
            ?matlab.ui.container.internal.model.TreeComponent})
        

        function calibratedNodes = calibrateSelectedNodesAfterSelectionStrategyChange(obj)
            % Restrict the SelectedNodes to one.  This is unlikely to get
            % called since Multiselect is not implemented for CheckBoxTree
            
            calibratedNodes = obj.Tree.SelectedNodes;
            
            if numel(calibratedNodes) > 1
                % If there are more than one selected nodes filter out all
                % but first node.
                calibratedNodes = calibratedNodes(1);
            end
        end
        
        function exceptionObject = getExceptionObject(obj)
            % GETEXCEPTIONOBJECT - object to throw when there
            % are errors setting the SelectedNodes property
            messageObj = message('MATLAB:ui:components:selectedCheckBoxTreeNodes', 'SelectedNodes');
            
            % MnemonicField is last section of error id
            mnemonicField = 'selectedCheckBoxTreeNodes';
            
            % Use string from object
            messageText = getString(messageObj);
            
            % Create and throw exception
            exceptionObject = matlab.ui.control.internal.model.PropertyHandling.createException(obj.Tree, mnemonicField, messageText);
            
        end
                
    end
end

