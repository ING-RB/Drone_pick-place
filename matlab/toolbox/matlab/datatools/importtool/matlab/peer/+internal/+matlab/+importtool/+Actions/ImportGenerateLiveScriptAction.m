classdef ImportGenerateLiveScriptAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportVariableNamesRowChanged
    % Action to track the header row of the data in the Import Tool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportGenerateLiveScriptAction, ?internal.matlab.importtool.Actions.ImportActions, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportGenerateLiveScriptAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'GenerateLiveScript';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setImportAction(varargin{:}, 'generateLiveScript');
        end
    end
end

