classdef Tokenization
%TOKENIZATION Tokenize MATLAB file or feature queue.

%   Copyright 2021-2023 The MathWorks, Inc.

    methods(Static)
        function tokens = tokenize(opts)
        %TOKENIZE Tokenize file or feature queue into a string tokens vector.

            arguments
                opts.FileName string {mustBeFile} = [];
                opts.FeatureQueue (:, 1) string = [];
            end

            % Generate tokens for either MATLAB file or feature queue.
            if isempty(opts.FileName) && isempty(opts.FeatureQueue)
                % Return empty tokens if no MATLAB file nor feature queue was given.
                tokens = "";
            elseif ~isempty(opts.FileName)
                % Tokenize the MATLAB file if it is not empty.
                featureQueue = matlab.internal.codesuggest.codingSuggestion.Tokenization.generateFeatureQueue(opts.FileName);
                if isempty(featureQueue)
                    tokens = "";
                else
                    tokens = matlab.internal.codesuggest.codingSuggestion.Tokenization.getTokens(featureQueue);
                end
            elseif ~isempty(opts.FeatureQueue)
                % Tokenize the feature queue if it is not empty.
                tokens = matlab.internal.codesuggest.codingSuggestion.Tokenization.getTokens(opts.FeatureQueue);
            end
        end
    end

    methods(Static, Access = 'private')
        function featureQueue = generateFeatureQueue(fileName)
        %GENERATEFEATUREQUEUE Generate feature queue from MATLAB file.
        % Uses built-in "_getFunctionCallAnalytics" to generate feature queue.

            [~, featureQueue] = builtin('_getFunctionCallAnalytics', matlab.internal.getCode(convertStringsToChars(fileName)));
        end

        function tokens = getTokens(featureQueue)
        %GETTOKENS Parse function calls and variables.
        % Returns MATLAB tokens as a string vector.

            % Pre-allocate the tokens vector to store the MATLAB tokens.
            tokens = strings(numel(featureQueue), 1);

            functionCallToken = extractBefore(featureQueue, '{');
            remains = extractAfter(featureQueue, '{');

            for tokenIndex = 1:numel(tokens)
                % Split the "functionCall" or "variable" from the remaining
                % of the MATLAB token features.
                thisToken = functionCallToken(tokenIndex);
                remain = remains(tokenIndex);

                % Determine the type of the "functionCall".
                if matches(thisToken, "functionCall")
                    % Get the "functionCall" name if exist, othwerwise,
                    % mark the function as "unknown".
                    functionName = extractBetween(remain, "name:", ",");
                    if isempty(functionName) || strlength(functionName) == 0
                        functionName = "unknown";
                    else
                        % The parenthesis distinguishes the documented
                        % functionCall "unknown" from unknown functions.
                        functionName = functionName + "()";
                    end

                    % Mark whether the type of the "functionCall" is MATLAB
                    % documented function, deprecated function, or unknown
                    % function. If no providor is given, assign unknown to
                    % the function call.
                    provider = extractBetween(remain, "provider:", "}");
                    if matches(provider, "matlabDocumentedFunction")
                        % Mark MATLAB documented function.
                        thisToken = append("f_", functionName);
                    elseif matches(provider, "matlabDeprecatedFunction")
                        % Mark MATLAB deprecated function.
                        thisToken = append("fd_", functionName);
                    else
                        % Mark unknown function.
                        thisToken = "f_unknown";
                    end

                elseif matches(thisToken, "variable")
                    % Determine the type to the "variable" if available, 
                    % otherwise, add "_?".
                    varclass = extractBetween(remain, "class:", "}");
                    if isempty(varclass)
                        thisToken = "v_?";
                    else
                        thisToken = append("v_", varclass);
                    end
                end

                if ismissing(thisToken)
                    tokens(tokenIndex) = "";
                else
                    tokens(tokenIndex) = thisToken;
                end
            end
        end
    end
end
