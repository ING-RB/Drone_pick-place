% This class is unsupported and might change or be removed without notice
% in a future version.

classdef ImportSelectionChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportSelectionChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportSelectionChangedAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportSelectionChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'SelectionChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setSelectionAction(varargin{:});
        end

        function setSelectionAction(this, varargin)
            newValue = internal.matlab.importtool.Actions.ImportSelectionChangedAction.getNewPropertyValue(varargin);
            doc = this.manager.FocusedDocument;

            % Pass in 'server' as the source, so the table will update.  This is
            % the result of a user typing into the toolstrip, so we still need
            % the table to update it's display of selection.
            doc.ViewModel.setImportSelection(newValue.value, 'server');
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(varargin)
            newValue = struct();
            newValue.property = 'Selection';
            % varargin is a nested cell array where the inner cell contains
            % the event data and event type
            newValue.value = varargin{1}{1}.text;
        end
    end
end

