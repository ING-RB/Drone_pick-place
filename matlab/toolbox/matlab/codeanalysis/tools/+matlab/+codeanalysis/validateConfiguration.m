function messages = validateConfiguration(input)
%

%   Copyright 2022-2024 The MathWorks, Inc.

    arguments
        input {mustBeTextScalar} = pwd;
    end
    try
        input = matlab.codeanalyzer.internal.resolvePaths(input, ...
            ".json", ...
            'MATLAB:codeanalyzer:InvalidConfigFile', ...
            'MATLAB:codeanalyzer:ConfigFileNotFound');
    catch e
        throw(e);
    end
    input = input{1};
    m = mf.zero.Model;
    if isfolder(input)
        config = matlab.codeanalyzer.internal.datamodel.ConfigValidator.createForFolder(m, input);
        if ~config.found
            % No configuration is found
            error(message("MATLAB:codeanalyzer:ConfigFileNotFoundForFolder", input));
        end
    else
        config = matlab.codeanalyzer.internal.datamodel.ConfigValidator.createFromFile(m, input);
    end
    messages = createTable(config.messages.toArray);
end

function ret = createTable(msgArray)
    fullfilename = string({msgArray.filename})';
    lineStart = double([msgArray.startLine]');
    lineEnd = double([msgArray.endLine]');
    columnStart = double([msgArray.startColumn]');
    columnEnd = double([msgArray.endColumn]');
    severity = matlab.codeanalysis.IssueSeverity({msgArray.severityId})';
    checkID = categorical({msgArray.tag})';
    description = string({msgArray.message})';

    % Create a hyperlink to a specific line in the file.
    if ~isempty(msgArray)
        [~, filename, fileExtension] = fileparts(fullfilename);
        filename = filename + fileExtension;
        filename = "<a href = ""matlab:opentoline('" + fullfilename + "', " + lineStart + ")"">" + filename + "</a>";
    else
        filename = string.empty(0, 0);
    end
    ret = table(filename, severity, description, checkID, lineStart, lineEnd, columnStart, columnEnd, fullfilename, ...
                'VariableNames', ...
                {'Location', 'Severity', 'Message', 'MessageID', 'LineStart', 'LineEnd', 'ColumnStart', 'ColumnEnd', 'FullFilename'});
end
