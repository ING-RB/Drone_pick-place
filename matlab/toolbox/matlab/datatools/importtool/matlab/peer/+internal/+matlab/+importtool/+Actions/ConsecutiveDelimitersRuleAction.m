classdef ConsecutiveDelimitersRuleAction < internal.matlab.datatoolsservices.actiondataservice.Action & internal.matlab.importtool.Actions.ImportActions
    % ConsecutiveDelimitersRuleAction for the text import tool.

    % Copyright 2018-2023 The MathWorks, Inc.
    properties(Access = {?internal.matlab.importtool.Actions.ConsecutiveDelimitersRuleAction, ?matlab.unittest.TestCase})
        manager;
        props;
    end

    methods
        function this = ConsecutiveDelimitersRuleAction(props, manager)
            % ConsecutiveDelimitersRuleAction constructor
            if nargin < 1 || isempty(props)
                props = struct();
            end
            this@internal.matlab.datatoolsservices.actiondataservice.Action(props);
            this.ID = 'ConsecutiveDelimiterRuleChanged';
            this.Enabled = true;
            this.manager = manager;
            this.Callback = @(varargin)this.setConsecutiveDelimitersRule(varargin{:});
        end

        function setConsecutiveDelimitersRule(this, varargin)
            % Called to set the new consecutive delimiters rule
            newValue = internal.matlab.importtool.Actions.ConsecutiveDelimitersRuleAction.getNewPropertyValue(varargin);
            doc = this.manager.FocusedDocument;
            doc.ViewModel.setState("ConsecutiveDelimitersRule", newValue.value);
        end
    end

    methods(Static)
        function newValue = getNewPropertyValue(varargin)
            newValue = struct();
            newValue.property = "ConsecutiveDelimitersRule";

            % varargin is a nested cell array where the inner cell contains
            % the event data and event type
            consecDelimiterEnabled = varargin{1}{1}.text;
            if consecDelimiterEnabled
                newValue.value = "join";
            else
                newValue.value = "split";
            end
        end
    end
end

