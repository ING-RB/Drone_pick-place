classdef CommonHTMLData < handle
    % OptimTableData is the main data source for building a optimtable
    % webpage
    properties
        % Data coming from JS telling MATLAB which cells have been edited
        % (this should not be edited from the MATLAB side)
        JSEventData struct
        % Data to push to JS from MATLAB for testing purposes
        QEHTMLData = []
        % Is the HTML page built
        HTMLIsBuilt (1,1) logical = false
    end
    events
        TableUpdated
    end
    methods
        function updateUI(this)
            % notify the UI the data is updated
            notify(this,'TableUpdated');
        end
    end
end