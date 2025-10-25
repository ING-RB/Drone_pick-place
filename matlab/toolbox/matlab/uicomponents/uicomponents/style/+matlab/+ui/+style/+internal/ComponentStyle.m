classdef (Hidden) ComponentStyle < ...
        matlab.mixin.CustomDisplay & ...
        matlab.mixin.Heterogeneous
    %COMPONENTSTYLE Common base class for all styles in
    % uicomponent area.
    
    % Copyright 2021 The MathWorks, Inc.
    
    methods
        function obj = ComponentStyle(varargin)
            if nargin > 0
                obj = setPropertiesFromPVPairs(obj, varargin{:});
            end
        end
    end
    
    methods (Access = private)
        function obj = setPropertiesFromPVPairs(obj, varargin)

            parser = matlab.ui.control.internal.model.getComponentCreationInputParser(obj);
            parser.parse(varargin{:});
            parameterList = parser.Parameters;
                                 
            % Apply recognized properties within the pvpairs
            for index = 1:numel(parameterList)
                propName = parameterList{index};
                % Check if property value was provided in pvpairs
                if ~any(propName == string(parser.UsingDefaults))
                    obj.(propName) = parser.Results.(propName);
                end
            end
            
            % Apply unmatched content to trigger informative error
            if ~isempty(parser.Unmatched)                
                unmatchedFields = fields(parser.Unmatched);
                for index = 1:numel(unmatchedFields)
                    propName = unmatchedFields{index};
                    obj.(propName) = parser.Unmatched.(propName);
                end               
            end
        end

        function nonEmptyPropList = getAllNonEmptyPropertyNames(obj)
            % GETALLNONEMPTYPROPERTYNAMES - String array of property names
            % associated with non empty values
            nonEmptyPropList = string.empty;
            
            if ~isprop(obj, 'DisplayPropertyOrder')
                return
            end

            for prop = obj.DisplayPropertyOrder
                if ~isempty(obj.(prop))                    
                    nonEmptyPropList(end + 1) = prop;
                end
            end
        end
    end

    % These must be defined and Sealed here for heterogenous arrays
    methods (Access = protected, Sealed = true)
        function displayNonScalarObject(obj)
            displayNonScalarObject@matlab.mixin.CustomDisplay(obj);
        end

        function str = getHeader(obj)
            str = getHeader@matlab.mixin.CustomDisplay(obj);
        end

        function footer = getFooter(obj)
            footer = '';
            if  isscalar(obj)
                names = obj.getPropertyGroupNames();
                footer = matlab.ui.internal.SetGetDisplayAdapter.getFooter(obj, names, inputname(1));
            end
        end
        
        function names = getPropertyGroupNames(obj)
            % GETPROPERTYGROUPNAMES - This function returns common
            % properties for this class that will be displayed in the
            % curated list properties for all components implementing this
            % class.
            
            % Add the super class properties to the end of the display
            names = obj.getAllNonEmptyPropertyNames();
                
        end
        
        function propgrp = getPropertyGroups(obj)
            % GETPROPERTYGROUPS - Specify property-value pairs to show in
            % the object display.
            if isscalar(obj)
                propsNonDefault = obj.getPropertyGroupNames();
                
                if ~isempty(propsNonDefault)                    
                    % Show just the set properties when they exist
                    propgrp = matlab.mixin.util.PropertyGroup(propsNonDefault);
                elseif isprop(obj, 'DisplayPropertyOrder')
                    % Show all (empty) properties when none are set
                    propgrp = matlab.mixin.util.PropertyGroup(obj.DisplayPropertyOrder);
                else
                    % Use default display for arrays of styles
                    propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
                end
            else
                % Use default display for arrays of styles
                propgrp = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            end
        end
    end
end

