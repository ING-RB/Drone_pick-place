function formatSpecificInputParser = generateFormatSpecificInputParser(parameters)
%generateFormatSpecificInputParser    Generate InputParser to parse the
%   additional parameters that are specific to each file format.

%   Copyright 2023 The MathWorks, Inc.
    formatSpecificInputParser = inputParser;

    % Add each recognized parameter to the inputParser.
    for parameter = parameters
        % Use empty double array as the default value here, since the
        % default value won't be used here anyway. The underlying writer
        % will re-validate and set its own default behavior instead.
        addParameter(formatSpecificInputParser, parameter, []);
    end
end