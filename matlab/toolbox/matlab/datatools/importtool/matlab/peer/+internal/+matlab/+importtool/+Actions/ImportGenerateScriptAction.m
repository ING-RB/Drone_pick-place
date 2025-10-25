classdef ImportGenerateScriptAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportGenerateScriptAction
    % Reacts to the generate script action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportGenerateScriptAction, ?internal.matlab.importtool.Actions.ImportActions, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportGenerateScriptAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'GenerateScript';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setImportAction(varargin{:}, 'generateScript');
        end
    end
end

