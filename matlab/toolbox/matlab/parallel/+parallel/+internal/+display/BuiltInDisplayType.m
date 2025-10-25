% BuiltInDisplayType - Used to format built-in types for display

% Copyright 2012-2020 The MathWorks, Inc.

classdef ( Hidden ) BuiltInDisplayType < parallel.internal.display.DisplayType
    methods
        
        function obj = BuiltInDisplayType(displayValue)
            obj@parallel.internal.display.DisplayType(displayValue);
        end
        
        function displayText = char(obj)
            % We do not use the message catalog for this assert, as it is
            % causing performance issues, and it is not necessary for
            % internal messages.            
            assert ( isscalar(obj), 'Cannot call char on a vector of displayable items.' );
            if (~ischar(obj.DisplayValue))
                error(message('MATLAB:parallel:display:UnexpectedFormatError'));
            end
            
            displayText = obj.DisplayValue;
        end
        
        function displayValueLength = length(obj)
            % We do not use the message catalog for this assert, as it is
            % causing performance issues, and it is not necessary for
            % internal messages.
            assert ( isscalar(obj), 'Cannot get display value length by calling length on a vector of displayable items.' );
            % To make this support I18n we need to use a function that can
            % take into account the width of unicode characters.
            % wrappedLength in general returns a non-integer value. The
            % length of a string should be an integer so use ceil to get a
            % length that can accomodate the whole string.
            displayValueLength = ceil(matlab.internal.display.wrappedLength(obj.DisplayValue));
        end
        
        function obj = formatDispatcher(obj, displayHelper, valDisplayLength, formatter)
            for i = 1:numel(obj)
                obj(i).DisplayValue = formatter(displayHelper,  obj(i).DisplayValue , valDisplayLength);
            end
        end
        
    end
end
