% Duration - Used for determining running duration

% Copyright 2012-2021 The MathWorks, Inc.

classdef (Hidden) Duration < parallel.internal.display.DisplayableItem
   
    properties (SetAccess = immutable, GetAccess = private)
        duration
    end
    
    methods
    
        function obj = Duration(displayHelper, duration)
            if isempty(duration)
                duration = seconds(0);
            end
            obj@parallel.internal.display.DisplayableItem(displayHelper);
            obj.duration = duration;
        end
        
        function displayInMATLAB(obj, name)
            runningDuration = obj.DisplayHelper.getRunningDuration(obj.duration);
            obj.DisplayHelper.displayProperty(name, runningDuration);
        end
        
    end
    
end
