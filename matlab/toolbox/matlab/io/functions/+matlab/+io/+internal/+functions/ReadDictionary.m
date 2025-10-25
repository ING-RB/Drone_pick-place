classdef ReadDictionary < matlab.io.internal.functions.AcceptsReadableFilename ...
        & matlab.io.internal.functions.AcceptsFileType ...
        & matlab.io.internal.functions.AcceptsDateLocale ...
        & matlab.io.internal.parameters.DictionaryNodeNameProvider ...
        & matlab.io.internal.parameters.DictionarySelectorProvider ...
        & matlab.io.json.internal.read.parameter.DuplicateKeyRuleProvider ...
        & matlab.io.internal.parameters.RequireTopLevelObjectProvider ...
        & matlab.io.internal.parameters.ValueTypeProvider ...
        & matlab.io.internal.parameters.ValueImportOptionsProvider ...
        & matlab.io.json.internal.read.ReadDictionaryJSON
    %

    %   Copyright 2024 The MathWorks, Inc.

    properties (Constant, Access = protected)
        SupportedFileTypes = ["auto", "json"]; % required by AcceptsFileType
        FunctionName = "readdictionary"; % required by GetFunctionNameProvider
    end

    methods
        function [func,supplied,additionalArgs] = validate(func,varargin)
            % We should only match the *exact* filename that was provided.
            % We should *not* follow the legacy readtable behavior of appending
            % known file extensions (e.g. .xml) to the filename and then
            % checking for files on the MATLAB path that match the modified
            % filename.
            func.LegacyFilenameValidation = false;

            [func, supplied, additionalArgs] = ...
                validate@matlab.io.internal.functions.ExecutableFunction(func,varargin{:});

            % Use the FileExtension to set the FileType value if its
            % provided as "auto"
            if ~supplied.FileType || func.FileType == "auto"
                func.FileType = func.getFileTypeFromExtension();
            end

            if supplied.DictionaryNodeName && supplied.DictionarySelector
                error(message("MATLAB:io:dictionary:readdictionary:DictionarySelAndDictionaryNodeName"));
            end

            % Dispatch to the FileType-specific validation function.
            switch func.FileType
                case "json"
                    func = func.validate@matlab.io.json.internal.read.ReadDictionaryJSON(supplied);
            end
        end

        function D = execute(func, supplied)

            origState = warning("off", "MATLAB:textio:io:UnableToGuessFormat");
            [msg, id] = lastwarn();
            cleanup = onCleanup(@() cleanUpWarningState(origState, msg, id));

            % Set DateLocale on the variable options.
            % System is the default so it doesn't have to be set.
            if supplied.DateLocale && func.DateLocale ~= "system"
                func.ValueImportOptions{"datetime"}.DatetimeLocale = func.DateLocale;
            end

            % Dispatch to the FileType-specific readdictionary function.
            switch func.FileType
                case "json"
                    D = func.execute@matlab.io.json.internal.read.ReadDictionaryJSON(supplied);
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
