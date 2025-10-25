classdef RowParametersProvider < matlab.io.internal.FunctionInterface
% This class is undocumented and will change in a future release.

% Copyright 2021 The MathWorks, Inc.

    properties (Parameter)
        %DataRows  the rows in the table where the data is located.
        % DataRows must be a non-negative scalar integer or a Nx2 array of
        % non-negative integers.
        DataRows = [1, inf];

        %VariableNamesRow  the row in the table that contains the variable
        % names.
        % VariableNamesRow must be a non-negative scalar integer.
        VariableNamesRow = 0;

        %VariableUnitsRow  the row in the table that contains the variable
        % units.
        % VariableUnitsRow must be a non-negative scalar integer.
        VariableUnitsRow = 0;

        %VariableDescriptionsRow the row in the table that contains the
        % variable descriptions.
        % VariableDescriptionsRow must be a non-negative scalar integer.
        VariableDescriptionsRow = 0;

        %EmptyRowRule what to do with empty rows in the table.
        %
        %   Possible values:
        %          skip: Skip empty rows.
        %
        %          read: Read empty rows as you would non-empty rows.
        %
        %         error: Error during import and abort the operation.
        EmptyRowRule = "skip";
    end

    methods
        function opts = set.DataRows(opts,rhs)
            if isscalar(rhs)
                try
                    opts.DataRows = matlab.io.internal.common.validateNonNegativeScalarInt(rhs);
                catch ME
                    error(message('MATLAB:textio:io:InvalidDataLines','DataRows'));
                end
            else
                if ~isnumeric(rhs)
                    error(message('MATLAB:textio:io:InvalidDataLines','DataRows'));
                end
                try
                    opts.DataRows = matlab.io.internal.validators.validateLineIntervals(rhs,'DataRows');
                catch ME
                    throwAsCaller(ME);
                end
            end
        end

        function opts = set.VariableNamesRow(opts,rhs)
            try
                opts.VariableNamesRow = validateRowNumber(rhs);
            catch ME
                throwAsCaller(ME)
            end
        end

        function opts = set.VariableUnitsRow(opts,rhs)
            try
                opts.VariableUnitsRow = validateRowNumber(rhs);
            catch ME
                throwAsCaller(ME)
            end
        end
        function opts = set.VariableDescriptionsRow(opts,rhs)
            try
                opts.VariableDescriptionsRow = validateRowNumber(rhs);
            catch ME
                throwAsCaller(ME)
            end
        end

        function obj = set.EmptyRowRule(obj,rhs)
            % rules = matlab.io.internal.replacementRules;
            rules = ["skip", "read", "error"];
            obj.EmptyRowRule = validatestring(rhs, rules);
        end
    end
end

function rhs = validateRowNumber(rhs)
    if ~isnumeric(rhs) || ~isscalar(rhs) || floor(rhs) ~= rhs || rhs < 0 || isinf(rhs)
        error(message('MATLAB:textio:textio:ExpectedScalarInt'));
    end
    rhs = double(rhs);
end
