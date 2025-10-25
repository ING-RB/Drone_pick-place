function resetRegressionLearnerState(stateFile)

% Resets the state of regression learner app based on stateFile data
% Copyright 2022 The MathWorks, Inc.

appProxy = mlearnapp.internal.adapterlayer.AppProxy('regression');
% Check to see if the file exists
if exist(stateFile, 'file') == 2
    appProxy.openSessionFromFile(stateFile);
else
    % For first task, there is no mat file. So, simply reset the app
    appProxy.resetApp();
end
end