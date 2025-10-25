classdef TextFileTypeAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % TextFileTypeAction for the Text Import Tool

    % Copyright 2019-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.TextFileTypeAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = TextFileTypeAction(props, manager)
            % TextFileTypeAction constructor
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'TextFileTypeChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setTextFileType(varargin{:});
        end

        function setTextFileType(this, varargin)
            import internal.matlab.importtool.Actions.TextFileTypeAction;

            newValue = TextFileTypeAction.getNewPropertyValue(varargin);
            doc = this.manager.FocusedDocument;

            if (newValue.value == "fixedwidth")
                doc.ViewModel.setState("FixedWidth", true);
            else
                doc.ViewModel.setState("FixedWidth", false);
            end
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(varargin)
            % varargin is a nested cell array where the inner cell contains
            % the event data and event type
            newValue.value = string(varargin{1}{1}.text);
        end
    end
end
