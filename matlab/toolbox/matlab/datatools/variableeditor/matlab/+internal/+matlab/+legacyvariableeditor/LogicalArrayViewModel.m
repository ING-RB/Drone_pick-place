classdef LogicalArrayViewModel < ...
        internal.matlab.legacyvariableeditor.ArrayViewModel
    % LOGICALARRAYVIEWMODEL
    % Logical Array View Model

    % Copyright 2015 The MathWorks, Inc.

    % Public Abstract Methods
    methods (Access = public)
        % Constructor
        function this = LogicalArrayViewModel(dataModel, viewID)
            if nargin <= 1 
                viewID = '';
            end
            this@internal.matlab.legacyvariableeditor.ArrayViewModel(dataModel, viewID);
        end
    end
end