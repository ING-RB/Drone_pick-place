function E = createValidatorException(errorID, varargin)
% Create a MException object with the specified error ID and message arguments.

%   Copyright 2020-2024 The MathWorks, Inc.

    messageObject = message(errorID, varargin{1:end});
    E = MException(messageObject);
end
