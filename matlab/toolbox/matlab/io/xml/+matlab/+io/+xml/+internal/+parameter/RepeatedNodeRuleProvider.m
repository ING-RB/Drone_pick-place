classdef RepeatedNodeRuleProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %RepeatedNodeRule
        %    Rule for managing repeated XML Element nodes in a given row of
        %    a table. Defaults to 'addcol'.
        %
        %    'addcol' - Add the repeated nodes as extra columns in the
        %               output table. This is the default behavior.
        %
        %    'ignore' - Ignore the repeated nodes in a given a row and
        %               include only the first instance of the node in the
        %               output table.
        %
        %    'error'  - Error if there are repeated nodes in a given row of
        %               the table.
        RepeatedNodeRule = "addcol";
    end

    methods
        function obj = set.RepeatedNodeRule(obj,val)
            obj.RepeatedNodeRule = validatestring(val,["error","addcol","ignore"]);
        end
    end

end
