function mustBeASCIICharRowVector(value, propName)
% mustBeASCIICharRowVector is for internal use only and may be removed or
% modified at any time

% mustBeASCIICharRowVector checks if the input scalar text data contains 
% ascii characters. It issues an error if the text contains non-ascii
% characters

%   Copyright 2019-2020 The MathWorks, Inc.
    matlab.internal.validation.mustBeCharRowVector(value, propName);
    
    if ~isempty(value) && ~(all(abs(char(value(:))) <= 127))
        errorID = 'MATLAB:class:RequireAscii';
        messageObject = message(errorID);
        E = MException(errorID, messageObject.getString);
        throw(E);
    end
end
