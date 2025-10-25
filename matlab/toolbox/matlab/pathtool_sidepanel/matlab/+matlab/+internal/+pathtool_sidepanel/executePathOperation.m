function executePathOperation(commandTemplate, varargin)
    %

    % Copyright 2025 The MathWorks, Inc.
    lastwarn('');
    messageStruct = struct('type', '', 'details', []);
    try
        % Ensure each element in varargin is a string or character vector
        formattedArgs = cellfun(@(arg) sprintf('"%s"', arg), varargin, 'UniformOutput', false);
        command = sprintf(commandTemplate, strjoin(formattedArgs, ', '));
        
        operationOutput = evalc(command);
        [~, warnID] = lastwarn;
    catch ME
        messageStruct = struct('type', 'error', 'details', struct('msg', ME.message, 'id', ME.identifier));
        matlab.internal.pathtool_sidepanel.publishToFrontEnd(messageStruct);
        return
    end

    % Define a regex pattern to match backspace with adjacent brackets
    pattern = '\[\b\]|\[\b|\b\]|\]\b';

    % Remove unwanted sequences
    cleanedStr = regexprep(operationOutput, pattern, '');

    % Further clean newlines and carriage returns if needed
    cleanedStr = regexprep(cleanedStr, '[\n\r]', ' ');

    warningPattern = 'Warning: [^\n\r>]+';

    % Use regexp to extract the warning messages
    warningMessages = regexp(cleanedStr, warningPattern, 'match');
    combinedMessage = strjoin(warningMessages, '\n');

    if isempty(warnID)
        messageStruct.type = 'success';
    else
        messageStruct.type = 'warning';
        messageStruct.details = struct('msg', combinedMessage, 'id', warnID);
    end
    matlab.internal.pathtool_sidepanel.publishToFrontEnd(messageStruct);
end
