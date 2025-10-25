% DisplayableItem - abstract base class for all displayable properties

% Copyright 2012-2020 The MathWorks, Inc.

classdef (Hidden) DisplayableItem
    % The display helper is a class shared by all PCT objects which 
    % contains information on how to format the object display.  
    properties (SetAccess = immutable, GetAccess = protected)
        DisplayHelper
    end
    % Non-default displayable items are often displayed in MATLAB with the
    % default formatting of the value turned off. This constant is used for
    % those non-default displayable items. 
    properties (Constant, GetAccess = protected)
        DoNotFormatValue = false;
    end
    % The base class constructor sets the display helper for all the
    % subclasses. 
    methods (Access = protected)
        function obj = DisplayableItem(displayHelper)
            obj.DisplayHelper = displayHelper;
        end
    end
    % This method must be defined for every displayable item. It uses the
    % display helper methods to format the display value and display the
    % name value pair. 
    methods (Abstract)
        displayInMATLAB(name)
    end
end
