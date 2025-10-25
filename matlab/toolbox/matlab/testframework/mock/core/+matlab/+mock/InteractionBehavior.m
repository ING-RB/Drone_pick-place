classdef (Abstract) InteractionBehavior < matlab.mixin.Heterogeneous & matlab.mixin.CustomDisplay
    % InteractionBehavior - Interface for mock object interaction specification.
    %
    %   The framework creates instances of this class, so there is no need for
    %   test authors to construct instances of the class directly.
    %
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties (Hidden, SetAccess=immutable)
        % Name - String indicating the method or property name
        %
        %   The Name property is a scalar string that indicates the name of the method or property.
        %
        Name (1,1) string;
    end
    
    properties (Abstract, Hidden, SetAccess=private)
        % Count - Number of times the interaction occurred
        %
        %   The Count property is a scalar double that indicates the number of
        %   times the mock object method was called with the specified input and
        %   output criteria, the number of times the mock object property was
        %   accessed, or the number of times the mock object property was set to
        %   the specified value.
        Count (1,1) double;
    end
    
    properties (Hidden, SetAccess=immutable, GetAccess=protected, WeakHandle)
        InteractionCatalog (1,1) matlab.mock.internal.InteractionCatalog;
    end
    
    properties (Hidden)
        Action;
    end
    
    properties (Abstract, Hidden, Constant, Access=protected)
        ActionClassName (1,1) string;
    end
    
    methods (Abstract, Hidden, Access=protected)
        summary = getElementDisplaySummary(behaviorElement);
    end
    
    methods (Hidden)
        function bool = describesPropertyAccess(~, ~)
            bool = false;
        end
        function bool = describesSuccessfulPropertyAccess(~, ~)
            bool = false;
        end
        function bool = describesPropertyModification(~, ~)
            bool = false;
        end
        function bool = describesSuccessfulPropertyModification(~, ~)
            bool = false;
        end
        function bool = describesMethodCall(~, ~)
            bool = false;
        end
        function bool = describesSuccessfulMethodCall(~, ~)
            bool = false;
        end
    end
    
    methods (Hidden, Access=protected)
        function validateElementUnambiguousSpecification(~)
        end
    end
    
    methods (Hidden, Sealed)
        function applyInteractionCheck(behavior, check)
            if isempty(behavior)
                return;
            end
            
            arrayfun(@validateElementUnambiguousSpecification, behavior);
            
            % Use the first catalog to validate all interactions. This is
            % only valid if all elements use the same catalog.
            catalog = behavior(1).InteractionCatalog;
            for idx = 2:numel(behavior)
                if behavior(idx).InteractionCatalog ~= catalog
                    error(message("MATLAB:mock:InteractionBehavior:ArrayContainsDifferentMocks"));
                end
            end
            
            catalog.applyCheckToAllOrderedRecords(check);
        end
        
        function summary = getDisplaySummary(behavior)
            if isempty(behavior)
                summary = '';
                return;
            end
            
            summary = [string.empty(1,0), arrayfun(@getElementDisplaySummary, behavior(:).')];
        end
    end
    
    methods (Hidden, Sealed, Access=protected)
        function behavior = InteractionBehavior(catalog, name)
            behavior.InteractionCatalog = catalog;
            behavior.Name = name;
        end
        
        function groups = getPropertyGroups(behavior)
            groups = getPropertyGroups@matlab.mixin.CustomDisplay(behavior);
        end
        
        function header = getHeader(behavior)
            if isscalar(behavior)
                header = behavior.getClassNameForHeader(behavior);
            else
                header = getHeader@matlab.mixin.CustomDisplay(behavior);
            end
        end
        
        function displayNonScalarObject(behavior)
            displayNonScalarObject@matlab.mixin.CustomDisplay(behavior);
        end
        
        function footer = getFooter(behavior)
            import matlab.unittest.internal.diagnostics.indent;
            footer = char(string + indent(join(behavior.getDisplaySummary, newline)) + newline);
        end
    end
    
    methods
        function behavior = set.Action(behavior, action)
            validateattributes(action, behavior.ActionClassName, {});
            action.applyToAllActionsInList(@(a)validateattributes(a, ...
                behavior.ActionClassName, {}));
            behavior.Action = action;
        end
    end
end

% LocalWords:  unittest
