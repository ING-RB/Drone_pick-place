% Default - Normal property value pairs are displayed this way.

% Copyright 2012-2020 The MathWorks, Inc.

classdef (Hidden) Default < parallel.internal.display.DisplayableItem
    properties (SetAccess = immutable, GetAccess = private)
        Value
    end
    
    methods
    
        function obj = Default(displayHelper, value)
            obj@parallel.internal.display.DisplayableItem(displayHelper);
            obj.Value = value;
        end
        
        function displayInMATLAB(obj, name)
            obj.DisplayHelper.displayProperty(name, obj.Value);
        end
        
        % We need to get the value when checking license requirements
        % to decide whether to display license number
        function value = getValue(obj)
            value = obj.Value;
        end
    end
end