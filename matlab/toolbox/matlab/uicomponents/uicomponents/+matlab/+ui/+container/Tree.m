classdef (Sealed, ConstructOnLoad=true) Tree < ...
        ... Shared tree functionality
        matlab.ui.container.internal.model.TreeComponent
    %
    
    % Do not remove above white space
    % Copyright 2016-2021 The MathWorks, Inc.
    
    properties(Dependent, AbortSet)
        Multiselect matlab.internal.datatype.matlab.graphics.datatype.on_off = 'off';
    end
    
    % ---------------------------------------------------------------------
    % Constructor
    % ---------------------------------------------------------------------
    methods
        function obj = Tree(varargin)
            %
            
            % Do not remove above white space
            % Override the default values
            
            % Super
            obj = obj@matlab.ui.container.internal.model.TreeComponent(varargin{:});

            obj.Type = 'uitree';
        end
    

        function set.Multiselect(obj, newValue)
            
            % Property Setting
            doSetMultiselect(obj, newValue)
            
            % Change in multiselect may result in change of SelectedNodes
            calibratedNodes = obj.SelectionStrategy.calibrateSelectedNodesAfterSelectionStrategyChange();
            
            if isequal(obj.SelectedNodes, calibratedNodes)
                obj.markPropertiesDirty({'Multiselect'});
            else
                doSetSelectedNodes(obj, calibratedNodes);
                obj.markPropertiesDirty({'Multiselect', 'SelectedNodes'});
            end
        end
        
        function value = get.Multiselect(obj)
            value = obj.PrivateMultiselect;
        end
        
    end 
    
    methods(Access = protected)
        
        % Update the Selection Strategy property
        function updateSelectionStrategy(obj)
            if(strcmp(obj.PrivateMultiselect, 'on'))
                obj.SelectionStrategy = matlab.ui.container.internal.model.ZeroToManyTreeSelectionStrategy(obj);
            else
                obj.SelectionStrategy = matlab.ui.container.internal.model.ZeroToOneTreeSelectionStrategy(obj);
            end
        end
    end
    % ---------------------------------------------------------------------
    % Custom Display Functions
    % ---------------------------------------------------------------------
    methods(Access = protected)
        
        function names = getPropertyGroupNames(~)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            names = {'SelectedNodes',...
                'Multiselect',...
                'SelectionChangedFcn'};
            
        end
        
        function str = getComponentDescriptiveLabel(~)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            
            % There's no strong property in Tree representing the visual
            % for the component. 
            str = '';
        end
    end
    methods (Hidden, Static) 
        function modifyOutgoingSerializationContent(sObj, obj) 

           % sObj is the serialization content for obj 
           modifyOutgoingSerializationContent@matlab.ui.container.internal.model.TreeComponent(sObj, obj);
        end
        function modifyIncomingSerializationContent(sObj) 

           % sObj is the serialization content that was saved for obj 
           modifyIncomingSerializationContent@matlab.ui.container.internal.model.TreeComponent(sObj);
        end 
    end
end



