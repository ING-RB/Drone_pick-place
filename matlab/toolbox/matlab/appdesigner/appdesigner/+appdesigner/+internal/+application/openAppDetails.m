function openAppDetails(inputFileName)
% OPENAPPDETAILS Opens the App Details dialog for the passed app.
% Will start App Designer if it is not already open.

% Copyright 2018-2020 The MathWorks, Inc.
    narginchk(1, 1);

    filePath = appdesigner.internal.application.getValidatedInputAppFileName(inputFileName);
    appDesignEnvironment = appdesigner.internal.application.getAppDesignEnvironment();
    appDesignEnvironment.openAppDetails(filePath);
end
