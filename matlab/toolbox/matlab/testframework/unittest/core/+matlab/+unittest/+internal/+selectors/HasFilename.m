classdef (Sealed) HasFilename < matlab.unittest.internal.selectors.SingleAttributeSelector
    %

    % Copyright 2022 The MathWorks, Inc.
    
    properties (SetAccess=immutable)
        Constraint;
    end
    
    properties (Constant, Hidden, Access=protected)
        AttributeClassName = "matlab.unittest.internal.selectors.FilenameAttribute";
        AttributeAcceptMethodName = "acceptsFilename";
    end
    
    methods
        function selector = HasFilename(filename)
            import matlab.unittest.constraints.IsEqualTo;
            selector.Constraint = IsEqualTo(string(filename));
        end
    end
end

