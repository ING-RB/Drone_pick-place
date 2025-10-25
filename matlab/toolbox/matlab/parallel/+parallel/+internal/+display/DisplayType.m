% DisplayType - Abstract base class for formatting different display types

% Copyright 2012-2020 The MathWorks, Inc.

classdef ( Hidden, Abstract ) DisplayType
    % All display types must have a value to be displayed
    properties 
        DisplayValue
    end
    
    % The base class constructor sets the display value for all the
    % subclasses.
    methods ( Access = protected )
        
        function obj = DisplayType(displayValue)
            obj.DisplayValue = displayValue;
        end
        
    end
    
    methods ( Abstract )
        
        % All display types must have a method which guarantees to return
        % a char for display
        char(obj)
        % The length of the displayable part of the item
        length(obj)
        % Determines the formatter to use for the type
        formatDispatcher(obj, displayHelper, valDisplayLength, formatter)
        
    end
end