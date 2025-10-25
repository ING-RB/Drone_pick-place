classdef ImportColumnNameChangedAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportVariableWidthsChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2024 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportColumnNameChangedAction, ?matlab.unittest.TestCase})
        manager;
    end

    methods
        function this = ImportColumnNameChangedAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'HeaderNameChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.updateHeaderName(varargin{:});
        end

        function updateHeaderName(this, varargin)
            newValue = varargin{1}.actionInfo.value;
            colIndex = varargin{1}.actionInfo.index + 1;
            doc = this.manager.FocusedDocument;

            doc.ViewModel.setImportColumnNames(colIndex, newValue);
            doc.ViewModel.EditedColNames(colIndex) = newValue;
        end
    end
end
