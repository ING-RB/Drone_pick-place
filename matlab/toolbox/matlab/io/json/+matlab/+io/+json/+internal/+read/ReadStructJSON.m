classdef ReadStructJSON < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.json.internal.read.parameter.ParsingModeProvider ...
        & matlab.io.json.internal.read.parameter.AllowCommentsProvider ...
        & matlab.io.json.internal.read.parameter.AllowInfAndNaNProvider ...
        & matlab.io.json.internal.read.parameter.AllowTrailingCommasProvider ...
        & matlab.io.json.internal.read.parameter.OverflowToInfinityProvider ...
        & matlab.io.json.internal.read.parameter.UseFullPrecisionProvider ...
        & matlab.io.json.internal.read.parameter.HomogenizeArrayElementsProvider
%

%   Copyright 2023-2024 The MathWorks, Inc.

    methods
        function func = validate(func, supplied)
        % Error if unsupported NV arguments are passed to readstruct
        % for JSON.
            unsupportedNVPairs = ["RegisteredNamespaces", "ImportAttributes", ...
                                  "AttributeSuffix"];
            for idx = 1:length(unsupportedNVPairs)
                if supplied.(unsupportedNVPairs(idx))
                    error(message("MATLAB:io:json:readstruct:UnsupportedNVPair", unsupportedNVPairs(idx)));
                end
            end

            % ParsingMode sets the following nv arguments if they have
            % not already been explicitly supplied:
            %  - AllowComments
            %  - AllowInfAndNaN
            %  - AllowTrailingCommas

            % Only modify the nv arguments if ParsingMode is set to
            % 'strict', as the default values for all three are 'true'
            if supplied.ParsingMode && (func.ParsingMode=="strict")
                if (~supplied.AllowComments)
                    func.AllowComments = false;
                end
                if (~supplied.AllowInfAndNaN)
                    func.AllowInfAndNaN = false;
                end
                if (~supplied.AllowTrailingCommas)
                    func.AllowTrailingCommas = false;
                end
            end
        end

        function S = execute(func, ~)
        % Build the options struct.
            opts = matlab.io.json.internal.read.buildJSONStructOptions(func);

            try
                % Call into the builtin implementation.
                S = matlab.io.json.internal.read_struct(func.Filename, opts);
            catch ME
                if ME.identifier == "MATLAB:io:json:common:InvalidJSONFile"
                    error(message("MATLAB:io:json:common:InvalidJSONFile", func.InputFilename));
                else
                    rethrow(ME);
                end
            end

            % Post processing step to convert all string(missing) values,
            % representing "null" values, to MATLAB 'missing'.
            % Also converts datetime/duration placeholder values to actual MATLAB
            % types.
            S = matlab.io.json.internal.read.buildStruct(S, missing);
        end
    end
end
