classdef ColumnParametersProvider < matlab.io.internal.FunctionInterface
% This class is undocumented and will change in a future release.

% Copyright 2021 The MathWorks, Inc.

    properties (Parameter)
%%        %RowNamesColumn  the column that contains row names describing the
%%        % data.
%%        % RowNamesColumn must be a non-negative scalar integer.
%%        RowNamesColumn = 0;

%%        %ExtraColumnsRule what to do with extra columns of data that appear
%%        % after the expected variables.
%%        %
%%        %   Possible values:
%%        %       addvars: Create a new variable in the resulting table
%%        %                containing the data from the extra columns. The
%%        %                new variables are named 'ExtraVar1', 'ExtraVar2',
%%        %                etc..
%%        %
%%        %        ignore: Ignore the extra columns of data.
%%        %
%%        %         error: Error during import and abort the operation.
%%        ExtraColumnsRule = "addvars";

        %EmptyColumnRule  what to do with empty columns in the table.
        %
        %   Possible values:
        %          skip: Skip empty columns.
        %
        %          read: Read empty columns as you would non-empty columns.
        %
        %         error: Error during import and abort the operation.
        EmptyColumnRule = "skip";
    end

    methods
%%        function opts = set.ExtraColumnsRule(opts,rhs)
%%            rules = ["addvars","ignore","wrap","error"];
%%            opts.ExtraColumnsRule = validatestring(rhs,rules);
%%        end

        function obj = set.EmptyColumnRule(obj,rhs)
            % rules = matlab.io.internal.replacementRules;
            rules = ["skip","read","error"];
            obj.EmptyColumnRule = validatestring(rhs,rules);
        end
    end
end
