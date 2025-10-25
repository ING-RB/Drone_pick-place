function str = createAlertDisplayString(id, msg, args)
%

% Copyright 2020 The MathWorks, Inc.

import matlab.unittest.internal.diagnostics.getValueDisplay;

str = ...
    "Identifier: """ + id + """" + newline + ...
    "   Message: " + formatMessage(msg, "            ");

if nargin > 2
    argumentsStruct.Arguments = args;
    argumentsDisplay = getValueDisplay(argumentsStruct);
    argumentsDisplayLines = splitlines(argumentsDisplay.Text);
    str = " " + strtrim(argumentsDisplayLines(end)) + newline + str;
end
end

function str = formatMessage(msg, indention)
import matlab.unittest.internal.diagnostics.indent;

messageLines = splitlines(string(msg));

if numel(messageLines) == 1
    str = msg;
    return;
end

% Message may contain a stack. Trim test framework frames.
mask = contains(messageLines, "matlab.unittest.internal.constraints.FunctionHandleConstraint/invoke");
messageLines(find(mask, 1, "first"):end) = [];

% Indent all lines except the first
str = messageLines(1) + newline + indent(join(messageLines(2:end), newline), indention);
end

