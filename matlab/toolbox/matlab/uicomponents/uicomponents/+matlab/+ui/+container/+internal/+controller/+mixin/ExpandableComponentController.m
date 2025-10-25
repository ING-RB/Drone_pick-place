classdef (Hidden) ExpandableComponentController < handle & ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % ExpandableComponentController provides the functionality to 
    % expand or collapse TreeNodes
    
    % Copyright 2016 - 2023 The MathWorks, Inc.
    
    methods(Hidden, Access = 'public')
        function expand(obj, model, flag)
            % EXPAND(OBJ, flag) - expand nodes specified in
            % treeNodes.
            %
            % model - matlab.ui.container.TreeNode object or
            % matlab.ui.container.Tree
            %
            % flag - optional input, when value is 'all', all descendents
            % of the specified nodes will be expanded.
            
            
            func = @() obj.ClientEventSender.sendEventToClient(...
                'expand',...
                { ...
                'NodeId', model.NodeId, ...
                'Flag', flag, ...
                } ...
                );
            matlab.ui.internal.dialog.DialogHelper.dispatchWhenPeerNodeViewIsReady(obj.Model, obj.ViewModel, func);
            
        end
        
        function collapse(obj, model, flag)
            % COLLAPSE(OBJ, flag) - collapse nodes specified in
            % treeNodes.
            %
            % model - matlab.ui.container.TreeNode objects
            %
            % flag - optional input, when value is 'all', all descendents
            % of the specified nodes will be expanded.
            
            obj.ClientEventSender.sendEventToClient(...
                        'collapse',...
                        { ...
                    'NodeId', model.NodeId, ...
                    'Flag', flag, ...
                    } ...
                    );
        end

        function isChildOrderReversed = isChildOrderReversed(obj)
           isChildOrderReversed = false; 
        end
    end
end


