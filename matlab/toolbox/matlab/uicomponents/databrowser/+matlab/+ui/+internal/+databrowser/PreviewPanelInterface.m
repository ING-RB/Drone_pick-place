classdef PreviewPanelInterface < handle
    % Interface class to use PreviewPanel.
    %
    % To make your data browser (which is a subclass of AbstractDataBrowser
    % or TableDataBrowser) work with PreviewPanel, your data browser
    % subclass must inherit from the PreviewPanelInterface class, which
    % acts as an interface to communiocate with the PreviewPanel.
    %
    % In your subclass, you must implement the "getData" and "getName"
    % methods required by the interface.
    
    % Copyright 2020 The MathWorks, Inc.
    
    events
        % Event "PreviewRequested": 
        %
        %   Fire this event when a PreviewPanel needs to be refreshed.  For
        %   example, use it in the selection changed callback.
        %
        %   The event must be fired with the following event data:
        %   "matlab.ui.internal.databrowser.PreviewEventData".  If its
        %   "Index" field is a scalar, the PreviewPanel will use "getName"
        %   and "getData" to obtain information to refresh display.
        %   Otherwise, PreviewPanel display will be reset to blank.
        %
        PreviewRequested
    end
    
    methods (Abstract)
        % Method "getData": 
        %
        %   Implement this method to return the data object corresponding
        %   to a specific row.
        %
        %       data = getData(this, row)
        %
        %   "row" is the index of the requested row (a scalar).
        %
        %   "data" should be an object.
        getData(this, row) 
        % Method "getName": 
        %
        %   Implement this method to return the name corresponding
        %   to a specific row.
        %
        %       name = getName(this, row)
        %
        %   "row" is the index of the requested row (a scalar).
        %
        %   "name" should be a char array.
        getName(this, row)
    end
    
end

