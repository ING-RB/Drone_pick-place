classdef ImportGenerateFunctionAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportSelectionChangedAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportGenerateFunctionAction, ?internal.matlab.importtool.Actions.ImportActions, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportGenerateFunctionAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'GenerateFunction';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setImportAction(varargin{:}, 'generateFunction');
        end
    end
end

