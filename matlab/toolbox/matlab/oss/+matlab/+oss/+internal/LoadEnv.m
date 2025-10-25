classdef LoadEnv < handle
    %LOADENV Load environment variables from .env file.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        filename
        dict
        opts
    end

    methods
        function obj = LoadEnv(filename,opts)
            arguments
                filename(1,:) string
                opts struct
            end
            obj.validateFilename(filename,opts);
            obj.dict = dictionary(string.empty(0, 1), string.empty(0, 1));
            obj.opts = opts;
        end

        function out = validateAndExecute(obj, outputRequested)
            obj.parseDotenv;
            if obj.opts.ExpandVariables
                obj.processVariableExpansion;
            end
            % MATLAB's environment is modified only when nargout == 0.
            if ~outputRequested
                obj.loadEnvVariables;
            end
            out = obj.dict;
        end
    end

    methods(Access=private)
        function parseDotenv(obj)
            encoding = obj.opts.Encoding;
            if strcmpi(encoding,"auto")
                encoding = '';
            end
            % Forward all options to readlines..it also handles filename validation & works with remote data
            lines = readlines(obj.filename,"EmptyLineRule","skip","WhitespaceRule","trim","Encoding",encoding);
            pattern1 = "(?:^|^)\s*";
            pattern2 = "(?:export\s+)?";
            pattern3 = "([\w.-]+)";
            pattern4 = "(?:\s*=\s*?|:\s+?)";
            pattern5 = "(\s*'(?:\\'|[^'])*'|\s*\""(?:\\""|[^""])*""|\s*`(?:\\`|[^`])*`|[^#\r\n]+)?\s*";
            pattern6 = "(?:#.*)?";
            pattern7 = "(?:$|$)";
            patternMatch = pattern1 + pattern2 + pattern3 + pattern4 + pattern5 + pattern6 + pattern7;
            for idx = 1:numel(lines)
                matchStrCellStr = regexp(lines(idx),patternMatch,"tokens");
                if ~isempty(matchStrCellStr)
                    keyValue = matchStrCellStr{1};
                    if length(keyValue) == 2
                        keyValue = obj.processKeyValueWhitespace(keyValue);
                        keyValue = obj.processKeyValueQuotes(keyValue);
                        key = keyValue(1);
                        value = keyValue(2);
                        obj.dict(key) = value;
                    end
                end
            end
        end

        function loadEnvVariables(obj)
            numvars = obj.dict.numEntries;
            if obj.dict.numEntries > 0
                keys = obj.dict.keys;
                values = obj.dict.values;
            else
                return;
            end
            for idx = 1:numvars
                if obj.opts.OverwriteEnvironmentVariable
                    setenv(keys(idx),values(idx));
                else
                    if isenv(keys(idx))
                        continue;
                    else
                        setenv(keys(idx),values(idx));
                    end
                end
            end
        end

        function keyValue = processKeyValueQuotes(~,keyValue)
            value = keyValue(2);
            if value ~= ""
                checkDoubleQuote = value.extract(1);
                value = regexprep(value,"^(['`""])([\s\S]*)\1$", '$2');
                if checkDoubleQuote == '"'
                    % Match sprintf behavior for CRLF.
                    value = regexprep(value, "(?<!\\)(\\n)", '\n');
                    value = regexprep(value, "(?<!\\)(\\r)", '\r');
                    value = regexprep(value,"\\\\","\");
                end
            end
            keyValue(2) = value;
        end

        function keyValue = processKeyValueWhitespace(~,keyValue)
            % trim all whitespace from keys and values
            keyValue(1) = strip(keyValue(1));
            keyValue(2) = strip(keyValue(2));
        end

        function validateFilename(obj, filename, opts)
            [~,~,extension] = fileparts(filename);
            extension = lower(extension);
            fileType = opts.FileType;

            % We should not try to infer "FileType" for files without extensions.
            if (extension == "") && (~strcmpi(fileType,"env"))
                if opts.ExplicitFileType
                    error(message("MATLAB:oss:loadenv:FileTypeAutoWithNoFileExtension", filename));
                else
                    error(message("MATLAB:oss:loadenv:NoFileExtension", filename));
                end
            end

            if (~strcmpi(extension,".env")) && (~strcmpi(fileType,"env"))
                error(message('MATLAB:oss:loadenv:UnrecognizedExtension',extension));
            end

            % For file specified without extension, prefer a file with an "env" extension if such a file exists.
            if (extension == "") && (strcmpi(fileType,"env"))
                exts = {'.env'};
                validFileNames =  matlab.io.internal.validators.validateFileName(filename, exts, true);
                filename = convertCharsToStrings(validFileNames{1});
            end

            obj.filename = filename;
        end

        function valueFound = findValueForKey(obj, key, defaultValue)
            if obj.dict.isKey(key)
                valueFound = obj.dict(key);
            elseif isenv(key)
                valueFound = getenv(key);
            elseif ~isempty(defaultValue)
                valueFound = defaultValue;
            else
                valueFound = "";
            end
        end

        function inputValue = expandVariables(obj,inputKey,inputValue)
            expandVarsPattern1 = "(.?\${{1}[\w]*(?::-[\w\s/-]*)?}{1})";
            matchesCellStr1 = regexp(inputValue,expandVarsPattern1,"tokens");
            expandVarsPattern2 = "(.?)\${{1}([\w]*(?::-[\w\s/-]*)?)?}{1}";
            splitDelim = ":-";
            if ~isempty(matchesCellStr1)
                len = length(matchesCellStr1);
                for idx = 1:len
                    matchesCellStr2 = regexp(matchesCellStr1{idx},expandVarsPattern2,"tokens");
                    matchesCellStr3 = regexp(inputValue,expandVarsPattern1,"tokens");
                    if(~isequal(matchesCellStr1,matchesCellStr3))
                        return;
                    end
                    if isempty(matchesCellStr2)
                        return;
                    end
                    keyArray = matchesCellStr2{1};
                    needsReplacement = matchesCellStr1{idx};
                    if keyArray(1) ~= ""
                        needsReplacement = extractAfter(needsReplacement,length(keyArray(1)));
                    end
                    keyParts = split(keyArray(2),splitDelim);
                    if length(keyParts) == 2
                        keyToBeReplaced = keyParts(1);
                        defaultValue = keyParts(2);
                    else
                        keyToBeReplaced = keyParts(1);
                        defaultValue = '';
                    end
                    if(inputKey == keyToBeReplaced)
                        if(idx==len)
                            return;
                        else
                            continue;
                        end
                    end
                    valueFound = obj.findValueForKey(keyToBeReplaced,defaultValue);
                    inputValue = inputValue.replace(needsReplacement,valueFound);
                    if(contains(valueFound,strcat("$","{",keyToBeReplaced,"}")))
                        return;
                    end
                    % recursively replace nested variables
                    inputValue = obj.expandVariables(inputKey,inputValue);
                end
            end
        end

        function processVariableExpansion(obj)
            numvars = obj.dict.numEntries;
            if obj.dict.numEntries > 0
                keys = obj.dict.keys;
                values = obj.dict.values;
            end
            for idx = 1:numvars
                value = obj.expandVariables(keys(idx),values(idx));
                obj.dict(keys(idx)) = value;
            end
        end

    end
end
