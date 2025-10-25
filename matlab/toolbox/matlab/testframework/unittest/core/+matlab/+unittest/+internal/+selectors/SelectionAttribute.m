classdef SelectionAttribute < matlab.mixin.Heterogeneous
    % SelectionAttribute - Visitor interface for TestSuite selection attributes.
    %   By default, the result of visiting an attribute (i.e., calling an
    %   "accepts" method) is true (select). Each Visitor subclass can
    %   override one of the "accepts" methods to define its notion of what
    %   visiting that attribute means.
    
    % Copyright 2013-2022 The MathWorks, Inc.
    
    properties (SetAccess = ?matlab.unittest.internal.selectors.AttributeSet)
        Data
    end
    
    methods (Access=protected)
        function attribute = SelectionAttribute(data)
            attribute.Data = data;
        end
    end
    
    methods
        function result = acceptsBaseFolder(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsName(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsParameter(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsSharedTestFixture(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsTag(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsProcedureName(attribute,~)
            result = true(1, numel(attribute.Data));
        end
        
        function result = acceptsSuperclass(attribute,~)
            result = true(1, numel(attribute.Data));
        end

        function result = acceptsFilename(attribute,~)
            result = true(1, numel(attribute.Data));
        end
    end
end
