classdef TimeTableViewModel < internal.matlab.legacyvariableeditor.TableViewModel
    %TimeTableViewModel
    %   TimeTable View Model

    % Copyright 2013-2018 The MathWorks, Inc.
    
    % Public Abstract Methods
    methods(Access='public')
        % Constructor
        function this = TimeTableViewModel(dataModel, viewID)
            if nargin <= 1 
                viewID = '';
            end
            this@internal.matlab.legacyvariableeditor.TableViewModel(dataModel, viewID);
        end
        
        % Overrides getDisplaySize from ViewModel
        % For timetables, return the size of the cloneData as that contains
        % the TimeTable data.
        function displaySize = getDisplaySize(this)
            displaySize = matlab.internal.display.dimensionString(this.DataModel.getCloneData);
        end       
    end
end
