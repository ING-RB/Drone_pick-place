function command = prepareCommand(fullFileName)
    % Get the fully qualified MATLAB command that will run the app.
    % This command will include any package or method directories
    % as appropriate.

%   Copyright 2024 The MathWorks, Inc.

    command = appdesigner.internal.service.util.PathUtil.getAppRunCommandFromFileName(fullFileName);

    % The app to be run may have different properties, and functions
    % from last time running. We have to clear the class defintion
    % so that the new properties, and functions are updated into the
    % the MCOS class definition in MATLAB.
    clear(command);
end
