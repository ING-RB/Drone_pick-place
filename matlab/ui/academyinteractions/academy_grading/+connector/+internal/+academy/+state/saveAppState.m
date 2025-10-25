function saveAppState(stateName, stateFile, appName, workFolder)
%SAVEAPPSTATE Saves the state of a MATLAB App in a mat file.
%   The save logic is different for each app whose state needs to be saved. We only save the name of the mat file
%   that contains the state. This mat file is the either the template file (if
%   this is the first task) or it is the solution for the previous task.
%
% Copyright 2020-2022 The MathWorks, Inc.

%Folder for storing saved session
wd = fullfile(tempdir,'.state');
if ~exist(wd,'file')
    mkdir(wd);
end

% Switch based on the app state name and gather app state.
state = [workFolder stateFile];

% Save the returned state in the .state folder.
fileName = [wd filesep 'appState_' stateName '.mat'];
save(fileName, 'state');
end