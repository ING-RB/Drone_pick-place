classdef RemoteCalendarDurationArrayAdapter < ...
        internal.matlab.variableeditor.MLCalendarDurationArrayAdapter
    %RemoteCalendarDurationArrayAdapter
    %   MATLAB Calendar Duration Array Variable Editor Mixin
    
    % Copyright 2015-2019 The MathWorks, Inc.

    
    % Constructor
    methods
        function this = RemoteCalendarDurationArrayAdapter(name, workspace, data)
            this@internal.matlab.variableeditor.MLCalendarDurationArrayAdapter( ...
                name, workspace, data);
        end
    end
    
    methods(Access='public')
        % getDataModel
        function dataModel = getDataModel(this, ~)
            dataModel = this.DataModel;
        end

        % getViewModel
        function viewModel = getViewModel(this, document)
            if (isempty(this.ViewModel_I) || ...
                    ~isa(this.ViewModel_I, 'internal.matlab.variableeditor.peer.RemoteCalendarDurationArrayViewModel')) ...
                    && ~isempty(document)
                delete(this.ViewModel_I);
                this.ViewModel_I = internal.matlab.variableeditor.peer.RemoteCalendarDurationArrayViewModel(...
                    document, this, document.getNextViewID(), document.UserContext);
            end
            viewModel = this.ViewModel;
        end
    end
end
