classdef ReadStructXML < matlab.io.internal.functions.ExecutableFunction ...
        & matlab.io.xml.internal.parameter.AttributeSuffixProvider ...
        & matlab.io.xml.internal.parameter.ImportAttributesProvider ...
        & matlab.io.xml.internal.parameter.RegisteredNamespacesProvider ...
        & matlab.io.xml.internal.parameter.DetectNamespacesProvider
    %

    %   Copyright 2020-2024 The MathWorks, Inc.

    methods
        function func = validate(func, supplied)
            % Validate that if supplied, StructNodeName is not a zero
            % length string/char
            if supplied.StructNodeName
                isNonEmptyString = isstring(func.StructNodeName) ...
                    && func.StructNodeName ~= "";
                isNonEmptyChar = ischar(func.StructNodeName) ...
                    && ~isempty(func.StructNodeName);

                if ~isNonEmptyChar && ~isNonEmptyString
                    error(message("MATLAB:io:xml:readstruct:UnsupportedStructNodeNameType"));
                end
            end

            % Error if unsupported NV arguments are passed to readstruct
            % for XML.
            unsupportedNVPairs = ["AllowComments", "AllowInfAndNaN", ...
                "AllowTrailingCommas", "ParsingMode", ...
                "HomogenizeArrayElements", "OverflowToInfinity", "UseFullPrecision"];
            for idx = 1:length(unsupportedNVPairs)
                if supplied.(unsupportedNVPairs(idx))
                    error(message("MATLAB:io:xml:readstruct:UnsupportedNVPair", unsupportedNVPairs(idx)));
                end
            end

        end

        function S = execute(func, ~)
            % Build the options struct.
            opts = matlab.io.xml.internal.reader.buildXMLStructOptions(func);

            try
                % Call into the builtin implementation.
                S = matlab.io.xml.internal.reader.readstruct(func.Filename, opts);
            catch ME
                if ME.identifier == "MATLAB:io:xml:common:InvalidXMLFile"
                    error(message("MATLAB:io:xml:common:InvalidXMLFile", func.InputFilename));
                else
                    rethrow(ME);
                end
            end

            % Fix any datetime/duration/missing values.
            S = matlab.io.xml.internal.reader.buildStruct(S, missing);
        end
    end
end

