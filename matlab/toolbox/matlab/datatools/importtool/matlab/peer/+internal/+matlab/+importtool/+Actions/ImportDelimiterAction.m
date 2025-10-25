classdef ImportDelimiterAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ImportDelimiterAction
    % Reacts to the selection changed action on importtool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ImportDelimiterAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ImportDelimiterAction(props, manager)
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'DelimiterChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setDelimiter(varargin{:});
        end

        function setDelimiter(this, varargin)
            newValue = cell(1,0);
            if ~isempty(varargin{1}.text)
                newValue = cell(varargin{1}.text)';
            end

            doc = this.manager.FocusedDocument;

            % Pass in as a string since the NameValueArgs back/forth converstion
            % to struct end up with a multi-dimension struct array if we pass in
            % a cell array.

            doc.ViewModel.setState("Delimiter", string(newValue));
        end
    end
end
