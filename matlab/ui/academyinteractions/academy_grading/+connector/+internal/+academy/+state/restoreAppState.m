function restoreAppState(stateName, resetFunction)
%RESTOREAPPSTATE Restores the state of a MATLAB App using a mat file.
%   The restore logic is different for each app whose state needs to be restored. This
%   function switches off the appName and invokes the restore logic custom to the
%   app.
%   
% Copyright 2020 The MathWorks, Inc.

%Folder that contains the saved session
wd = fullfile(tempdir,'.state');

% Load the file where the state is saved.
stateFile = load([wd filesep 'appState_' stateName '.mat']);
stateFile = stateFile.state; % MATLAB save saves the variable as a struct

% Call the helper function that knows how to update app State.
feval(resetFunction, stateFile);
end