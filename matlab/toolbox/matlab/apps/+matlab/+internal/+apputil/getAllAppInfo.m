function info = getAllAppInfo(appDir)

% INFO = matlab.internal.apputil.getAllAppInfo returns information about
% all app installed.  INFO is a struct with the following fields.
%
%   id       - The id of the app.
%   name     - The name of the app as displayed in the app gallery.
%   status   - Always 'installed'.  Calling functions should modify this if
%              necessary.
%   location - The install location.
%   GUID     - The apps GUID.
 
% Copyright 2012 - 2018 The MathWorks, Inc.

apps = com.mathworks.appmanagement.MlappinstallUtil.getInstalledApps(java.io.File(appDir));
info = [];
for i=1:length(apps)
    app = apps(i);
    [~,folderName,~] = fileparts(char(app.getInstallFolder));
    info(end+1).id = matlab.internal.apputil.AppUtil.makeAppID(folderName); %#ok<AGROW>
    info(end).name = char(app.getName);
    info(end).status = 'installed';
    info(end).location = char(app.getInstallFolder);
    info(end).GUID = char(app.getGuid);
end
end
