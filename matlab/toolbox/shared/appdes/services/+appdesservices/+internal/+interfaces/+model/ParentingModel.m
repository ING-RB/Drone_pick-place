classdef (Hidden) ParentingModel <  ...
        appdesservices.internal.interfaces.model.AbstractModelMixin
    
    % A general mixin - class used by any class that can be the Parent of
    % other objects
    %
    % This Parent stores the objects in the 'Children' property
    
    % Copyright 2012-2015 The MathWorks, Inc.
    
    properties(Dependent)
        % An array of handles to other components
        Children;
    end
    
    properties(Access = 'protected')
        % Internal properties
        %
        % These exist to provide:
        % - fine grained control to each properties
        % - circumvent the setter, because sometimes multiple properties
        %   need to be set at once, and the object will be in an
        %   inconsistent state between properties being set
        PrivateChildren = [];
    end
    
    methods
        function obj = ParentingModel(varargin)
            % Creates a ParentComponent
        end
        
        function delete(obj)
            % Deletes this component
            
            % To prevent updates to the list we are iterating
            % over, make a separate array holding the children in case
            % deleting those children have a side effect
            childrenToDelete = obj.PrivateChildren;
            
            % Explicitly delete all children
            for idx = 1:length(childrenToDelete)
                if(isvalid(childrenToDelete(idx)))
                    delete(childrenToDelete(idx));
                end
            end
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Property Getters / Setters
    % ---------------------------------------------------------------------
    methods
        function value = get.Children(obj)
            value = obj.PrivateChildren;
        end
    end
    
    % ---------------------------------------------------------------------
    % Methods for use by other models
    % ---------------------------------------------------------------------
    
    methods(Access = {...
            ?appdesservices.internal.interfaces.model.ParentingModel, ... % give access to subclasses
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin, ...
            ?matlab.ui.control.internal.model.DesignTimeComponentFactory, ...
            ?appdesservices.internal.interfaces.controller.AppDesignerParentingController })
        
        function addChild(obj, childObject)
            % Adds a child component to this Parent
            %
            % Inputs:
            %
            %   A scalar component to add to the Parent
            
            % Error Checking
            validateattributes(childObject, ...
                {'appdesservices.internal.interfaces.model.AbstractModel', 'matlab.ui.control.WebComponent'}, ...
                {'scalar'});
            
            % Store the child
            if ~isempty(obj.PrivateChildren)
                obj.PrivateChildren(end+1) = childObject;
            else
                obj.PrivateChildren = [childObject];
            end
            
        end
        
        function removeChild(obj, childObject, newParent)
            % Removes a child component from this Parent
            %
            % Inputs:
            %
            %   childObject  A scalar component to remove from the Parent
            %
            %                This component is assumed to be in this Parent's Children already.
            %
            %   newParent    The new parent of the given childObject
            
            % Error Checking
            validateattributes(childObject, ...
                {'appdesservices.internal.interfaces.model.AbstractModel', 'matlab.ui.control.WebComponent' }, ...
                {'scalar'});
            
            % Remove the existing child
            for idx = 1:length(obj.PrivateChildren)
                if(obj.PrivateChildren(idx) == childObject)
                    obj.PrivateChildren(idx) = [];
                    break;
                end
            end            
            
            % Because removing the last index of an object array does not
            % yield [], but rather a 0x0 object array, do a special check
            % so to finesse a 0x0 to []
            if(isempty(obj.PrivateChildren))
                obj.PrivateChildren = [];
            end
        end
    end
    
    % methods added for GBT integration
    % GBT and Visual components have different parenting models so until
    % they share a common parenting scheme these checks are required
    methods (Access=protected)
        
        function isParentable = isParentable(~,component)
            isParentable =  isa(component, 'matlab.ui.control.internal.model.mixin.ParentableComponent') ||...
                isa(component, 'matlab.ui.container.Container');            
        end
        
        function parent = getComponentParent(~,component)
            if ( isa(component, 'matlab.ui.control.internal.model.mixin.ParentableComponent'))
                parent = component.getParent();
            else
                parent = component.Parent;
            end
        end
        
    end
end






