classdef (Hidden) AbstractComponent < ...
        appdesservices.internal.interfaces.model.AbstractModel & ...
        matlab.ui.internal.componentframework.services.optional.HGCommonPropertiesInterface & ...
        matlab.ui.control.internal.model.mixin.ParentableComponent & ...
        matlab.mixin.CustomDisplay & ...
        matlab.graphics.mixin.internal.GraphicsDataTypeContainer
    
    % AbstractComponent is the most basic "component" class.
    %
    % It is the parent of both App Windows and leaf components
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (Hidden, AbortSet)
        Serializable matlab.internal.datatype.matlab.graphics.datatype.on_off = 'on';
    end
    
    % Controller methods / properties
    
    methods (Access = protected)
        
        % Components must return a cell array of strings that will be used
        % to create the property group for the custom display of components
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This class can be customized in the
            % component subclasses
            
            names = setdiff(fields(obj), {'Position', 'InnerPosition', 'OuterPosition'}, 'stable')';
        end
        
        function str = getComponentDescriptiveLabel(~)
            % GETCOMPONENTDESCRIPTIVELABEL - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            str = ''; 

        end
    end

    methods (Hidden, Static)
        function names = getLastPropertiesToSet(~)
            % GETLASTPROPERTIESTOSET - Returns a column vector of
            % properties that will be moved to the end of the list 
            % when setting PV pairs during constuction 
            % (via the informal or formal interface)
            
            % Generally speaking, the Value property of a component is
            % dependent on other settings of the component.  We will move
            % 'Value' property to the end so it will be set last. Most (but
            % not all) components have a Value property.  If a
            % component does not have a Value property, the shift will
            % have no affect.
            
            % For mutual exclusive components, set Parent after Value so
            % that the following doesn't error out:
            % r = uiradiobutton(btngroup, 'Value', 0);
            % We don't want this to error out for backwards compatibility.
            names = ["Value"; "Parent"];
        end
    end
    
    
    % Model - related methods
    methods(Access = {...
            ?appdesservices.internal.interfaces.model.AbstractModel, ...
            ?appdesservices.internal.interfaces.model.AbstractModelMixin})
        
        function parsePVPairs(obj, varargin)
            % Helper method to be used by Model subclasses to:
            %
            % - handle PV Pairs
            % - after, mark the model as fully constructed
            
            import matlab.ui.control.internal.model.*;

            % Here are the rules for parsing PV Pairs:
            %
            % 1. If there are no elements in varargin, then we return
            % because there are no properties to set.
            %
            % 2. Otherwise, loop through each argument to check if:
            %
            %   - a struct? look at the field names for order dependent
            %   props
            %
            %   - assume its a PV pair, and see if the property name is
            %   order dependent
            %
            %  If we ever find an order dependent property, shift them.
            %  Otherwise avoid the shift for performance reasons

            pvPairLength = numel(varargin);

            if pvPairLength == 0
                return;
            end

            orderDependentProperties = obj.getLastPropertiesToSet();
            idx = 1;
            while(idx <= pvPairLength)

                if(isstruct(varargin{idx}))
                    if(any(contains(fieldnames(varargin{idx}), orderDependentProperties)))
                        varargin = PropertyHandling.shiftOrderDependentProperties(varargin, obj);
                        break;
                    end

                    % Move onto the next to check
                    idx = idx+1;
                else
                    % a PV pair, look at the current input
                    if((ischar(varargin{idx}) || isstring(varargin{idx})) && contains(varargin{idx}, orderDependentProperties))
                        % a match for order dependency
                        varargin = PropertyHandling.shiftOrderDependentProperties(varargin, obj);
                        break;
                    else
                        % not a match
                        % move onto the next name, skipping the value
                        idx = idx+2;                   
                    end
                end
            end            

            % Call into the AbstractModel to do the property sets
            parsePVPairs@appdesservices.internal.interfaces.model.AbstractModel(obj, varargin{:});

        end

    end

    methods(Sealed, Access = protected)
        % There's no need for this method to be implemented by subclasses
        % Subclasses can customize by implementing 'getPropertyGroupNames'
        function groups = getPropertyGroups(obj)
            % GETPROPERTYGROUPS - Used for custom display of UI Components.
            % This function returns a group containing the properties that
            % will show up by default when the component displays.
            names = getPropertyGroupNames(obj);

            % Only show Position if it exists and is not hidden
            if (obj.isprop('Position') && ~findprop(obj, 'Position').Hidden)
                names = [names, ...
                    ... Position related properties should
                    ... go on the end of all components
                    {'Position'}];                
            end
            
            groups = matlab.mixin.util.PropertyGroup(names);
            
        end
        
        function str = getDescriptiveLabelForDisplay(obj)
            % GETDESCRIPTIVELABELFORDISPLAY - This function returns a
            % string that will represent this component when the component
            % is displayed in a vector of ui components.
            
            if ~isempty(obj.Tag)
                str = obj.Tag;
            else
                str = getComponentDescriptiveLabel(obj);
            end
        end
        
    end
end





