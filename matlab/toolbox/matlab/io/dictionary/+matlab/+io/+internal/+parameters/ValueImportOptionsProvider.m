classdef ValueImportOptionsProvider < matlab.io.internal.FunctionInterface
%ValueImportOptionsProvider   Class for the undocumented ValueImportOptions
%   parameter on readdictionary.

%   Copyright 2024 The MathWorks, Inc.

    properties (Parameter, Hidden)
        ValueImportOptions (1, 1) dictionary = ...
            matlab.io.internal.parameters.ValueImportOptionsProvider.defaultValues();
    end

    methods (Static)
        function opts = defaultValues()
            persistent persistentOpts

            if isempty(persistentOpts)
                commonOpts = {"QuoteRule", "keep"};
                d = dictionary("datetime", matlab.io.DatetimeVariableImportOptions(commonOpts{:}), ...
                               "duration", matlab.io.DurationVariableImportOptions(commonOpts{:}), ...
                               "logical", matlab.io.LogicalVariableImportOptions(commonOpts{:}), ...
                               "double", matlab.io.NumericVariableImportOptions("Type", "double", commonOpts{:}), ...
                               "single", matlab.io.NumericVariableImportOptions("Type", "single", commonOpts{:}), ...
                               "uint8", matlab.io.NumericVariableImportOptions("Type", "uint8", commonOpts{:}), ...
                               "uint16", matlab.io.NumericVariableImportOptions("Type", "uint16", commonOpts{:}), ...
                               "uint32", matlab.io.NumericVariableImportOptions("Type", "uint32", commonOpts{:}), ...
                               "uint64", matlab.io.NumericVariableImportOptions("Type", "uint64", commonOpts{:}), ...
                               "int8", matlab.io.NumericVariableImportOptions("Type", "int8", commonOpts{:}), ...
                               "int16", matlab.io.NumericVariableImportOptions("Type", "int16", commonOpts{:}), ...
                               "int32", matlab.io.NumericVariableImportOptions("Type", "int32", commonOpts{:}), ...
                               "int64", matlab.io.NumericVariableImportOptions("Type", "int64", commonOpts{:}));

                % Convert to raw struct form to improve performance.
                persistentOpts = appendOptsStructs(dictionary(), d);
            end

            opts = persistentOpts;
        end
    end

    methods
        function obj = set.ValueImportOptions(obj, vio)
            arguments
                obj
                vio (1, 1) dictionary
            end
            validateattributes(vio.keys(), "string", {}, "readdictionary", "ValueImportOptions Key");
            validateattributes(vio.values(), ["matlab.io.VariableImportOptions" "cell"], {}, "readdictionary", "ValueImportOptions Value");

            % Append the new keys and values to the old dictionary.
            if iscell(vio.values())
                obj.ValueImportOptions = obj.ValueImportOptions.insert(vio.keys(), vio.values());
            else
                obj.ValueImportOptions = appendOptsStructs(obj.ValueImportOptions, vio);
            end
        end
    end
end

function d1 = appendOptsStructs(d1, d2)

    newKeys = d2.keys();
    newValues = d2.values();
    newValuesCell = arrayfun(@(opts) opts.makeOptsStruct(), newValues, UniformOutput=false);
    d1 = d1.insert(newKeys, newValuesCell);
end