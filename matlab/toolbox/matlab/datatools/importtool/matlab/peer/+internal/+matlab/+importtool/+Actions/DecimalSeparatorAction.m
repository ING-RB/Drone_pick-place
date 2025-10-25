classdef DecimalSeparatorAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % DecimalSeparatorAction for the Text Import Tool

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.DecimalSeparatorAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = DecimalSeparatorAction(props, manager)
            % DecimalSeparatorAction constructor
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'DecimalSeparatorChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setDecimalSeparator(varargin{:});
        end

        function setDecimalSeparator(this, varargin)
            % Called to set the new decimal separator
            import internal.matlab.importtool.Actions.DecimalSeparatorAction;

            newValue = DecimalSeparatorAction.getNewPropertyValue(varargin);
            doc = this.manager.FocusedDocument;

            % Change delimiter if the new decimal separator is comma and one of
            % the delimiters is comma.  The user would have already been
            % prompted about changing the delimiter.
            if strcmp(newValue.value, ",")
                delimiters = doc.ViewModel.getTableModelProperty("Delimiter");
                commaIdx = cellfun(@(x) x == ",", delimiters);
                if any(commaIdx)
                    delimiters(commaIdx) = [];

                    if isempty(delimiters)
                        doc.ViewModel.setState("Delimiter", '');
                    else
                        doc.ViewModel.setState("Delimiter", string(delimiters));
                    end
                end
            end
            doc.ViewModel.setState("DecimalSeparator", newValue.value);
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(varargin)
            newValue = struct();
            newValue.property = 'DecimalSeparator';

            % varargin is a nested cell array where the inner cell contains
            % the event data and event type
            newValue.value = varargin{1}{1}.text;
        end
    end
end
