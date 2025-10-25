classdef ReadDictionaryJSON < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.json.internal.read.parameter.ParsingModeProvider ...
        & matlab.io.json.internal.read.parameter.AllowCommentsProvider ...
        & matlab.io.json.internal.read.parameter.AllowInfAndNaNProvider ...
        & matlab.io.json.internal.read.parameter.AllowTrailingCommasProvider ...
        & matlab.io.json.internal.read.parameter.OverflowToInfinityProvider ...
        & matlab.io.json.internal.read.parameter.UseFullPrecisionProvider
%

%   Copyright 2024 The MathWorks, Inc.

    methods
        function func = validate(func, supplied)
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

        function D = execute(func, ~)
        % Build the options struct.
            opts = matlab.io.json.internal.read.buildJSONDictionaryOptions(func);

            try
                D = matlab.io.json.internal.read.readdictionary(func.Filename, opts);
            catch ME
                if ME.identifier == "MATLAB:io:json:common:InvalidJSONFile"
                    error(message("MATLAB:io:json:common:InvalidJSONFile", func.InputFilename));
                else
                    rethrow(ME);
                end
            end
        end
    end
end
