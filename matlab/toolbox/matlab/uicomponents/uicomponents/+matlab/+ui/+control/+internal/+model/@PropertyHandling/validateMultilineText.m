function newText = validateMultilineText(text)
% Validates that TEXT is a valid multiline string
% representation:
%
% - Regular String
% - Cell array of strings:
%		A Nx1 cell of strings will be accepted as is
%		A 1xN cell of strings will be transposed
%		A MxN cell of strings will throw an error

% Convert categoricals to string array to maintain
% consistency of behavior.
if (iscategorical(text))
    text = string(text);
end

% convert string array to cell array of char vectors before
% validating
text = convertStringsToChars(text);

if(iscellstr(text) && isvector(text))
    % at this point, it is a valid cell array
    % transpose to Nx1
    newText = matlab.ui.control.internal.model.PropertyHandling.getOrientedVectorArray(text,'vertical');
else
    % validate as a regular string
    newText = matlab.ui.control.internal.model.PropertyHandling.validateText(text);
end
end