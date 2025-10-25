% HTMLDisplayType - Used to format and build hyperlinks for display

% Copyright 2012-2020 The MathWorks, Inc.

classdef ( Hidden ) HTMLDisplayType < parallel.internal.display.DisplayType
   
    properties ( SetAccess = immutable, GetAccess = private )
        % If we create an HTML display type without a matlab command, then 
        % we are using MATLAB without links. Matlab commands are usually 
        % commands which, when evaluated, do a vector display or a single 
        % display for a cluster, a job or a task.
        MatlabCommand 
    end
    
    methods
        
        function obj = HTMLDisplayType(displayValue, matlabCommand)
            obj@parallel.internal.display.DisplayType(displayValue);
            % If we are using links, we should be given a command to
            % build into the link. 
            if nargin >1
                obj.MatlabCommand = matlabCommand;
            end
        end
        
        function stringToDisplay = char(obj)
            assert ( isscalar(obj), getString(message('MATLAB:parallel:display:CharOnVector')) );
            % The only things we will display is hyperlinks that have been
            % formatted. If you try to use a type that has NOT been
            % formatted this method will error
            if (~ischar(obj.DisplayValue))
                error(message('MATLAB:parallel:display:UnexpectedFormatError'));
            end
           
            % The hard limit from MW command window managers is 8092 chars.
            % Therefore, our safety limit for the size of the string we put
            % into the command window is 4kB of chars.
            commandSize = numel(obj.MatlabCommand);
            
            if commandSize < 4096 && ~isempty(obj.MatlabCommand)                                                                      
                stringToDisplay = sprintf('<a href="matlab: %s">%s</a>', obj.MatlabCommand, obj.DisplayValue);
            else
                stringToDisplay = obj.DisplayValue;
            end
            
        end
        
        function displayValueLength = length(obj)
            assert ( isscalar(obj), getString(message('MATLAB:parallel:display:LengthOnVector')) );
            displayValueLength = length(obj.DisplayValue);
        end
        
        function obj = formatDispatcher(obj, displayHelper, valDisplayLength, formatter)
            % Unlike other objects, for HTML objects, we never want to send
            % an array directly to the Formatter, instead we format the 
            % objects one by one and form the array later. 
            for i = 1:numel(obj)
                obj(i).DisplayValue = formatter(displayHelper, obj(i).DisplayValue, valDisplayLength);
            end
        end
        
    end
end
