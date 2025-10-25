classdef ReadStruct < matlab.io.internal.functions.AcceptsReadableFilename ...
                    & matlab.io.internal.functions.AcceptsFileType ...
                    & matlab.io.internal.functions.AcceptsDateLocale ...
                    & matlab.io.internal.common.properties.GetFunctionNameProvider ...
                    & matlab.io.xml.internal.parameter.StructSelectorProvider ...
                    & matlab.io.xml.internal.parameter.StructNodeNameProvider ...
                    & matlab.io.xml.internal.parameter.DetectTypesProvider ...
                    & matlab.io.internal.functions.ReadStructXML ...
                    & matlab.io.json.internal.read.ReadStructJSON
    %

    %   Copyright 2020-2024 The MathWorks, Inc.

   properties (Constant, Access = protected)
        SupportedFileTypes = ["auto", "json", "xml"]; % required by AcceptsFileType
        FunctionName = "readstruct"; % required by GetFunctionNameProvider
   end

    methods
        function [func,supplied,additionalArgs] = validate(func,varargin)
            % We should only match the *exact* filename that was provided.
            % We should *not* follow the legacy readtable behavior of appending
            % known file extensions (e.g. .xml) to the filename and then
            % checking for files on the MATLAB path that match the modified
            % filename.

            [func,varargin] = extractArg(func,"WebOptions",varargin,1);

            func.LegacyFilenameValidation = false;

            [func, supplied, additionalArgs] = ...
                validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});

            % Use the FileExtension to set the FileType value if its
            % provided as "auto"
            if ~supplied.FileType || func.FileType == "auto"
                func.FileType = func.getFileTypeFromExtension();
            end

            if supplied.StructNodeName && supplied.StructSelector
                error(message("MATLAB:io:xml:readstruct:StructSelAndStructNodeName"));
            end

            % Dispatch to the FileType-specific validation function.
            switch func.FileType
              case "xml"
                func = func.validate@matlab.io.internal.functions.ReadStructXML(supplied);
              case "json"
                func = func.validate@matlab.io.json.internal.read.ReadStructJSON(supplied);
            end
        end

        function S = execute(func, supplied)

            origState = warning("off", "MATLAB:textio:io:UnableToGuessFormat");
            [msg, id] = lastwarn();
            cleanup = onCleanup(@() cleanUpWarningState(origState, msg, id));

            % Dispatch to the FileType-specific readstruct function.
            switch func.FileType
              case "xml"
                S = func.execute@matlab.io.internal.functions.ReadStructXML(supplied);
              case "json"
                S = func.execute@matlab.io.json.internal.read.ReadStructJSON(supplied);
              otherwise
                assert(false)
            end
        end
    end
end

function cleanUpWarningState(state, msg, id)
    lastwarn(msg, id);
    warning(state);
end
