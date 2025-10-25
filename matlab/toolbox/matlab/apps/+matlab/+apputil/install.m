function status = install(filename)
% matlab.apputil.install Install an mlappinstall file.
%
%   APPINFO = matlab.apputil.install(FILE) installs the mlappinstall file
%   specified by the FILE argument.  The FILE argument is a character
%   vector or string containing the name of the file to install.  The file
%   can be specified with either an absolute path or a path relative to the
%   current directory.
%
%   The app is installed into the current app installation directory and is
%   available on the APP tab within the MATLAB desktop.
% 
%   The return argument, APPINFO, is a struct that contains information
%   about the app.  The function matlab.apputil.getInstalledAppInfo
%   documents the fields of this struct.
% 
%   Example: Install an app downloaded from the MATLAB Central File Exchange.
% 
%       matlab.apputil.install('C:\Downloads\DataVisualization.mlappinstall')
% 
%       ans = 
% 
%             id: 'DataVisualizationAPP'
%           name: 'Surface Plot Visualization Examples'
%         status: 'installed'
%       Location: 'C:\users\Documents\MATLAB\MyApps\DataVisualization'
%
%   See also: matlab.apputil.uninstall, matlab.apputil.getInstalledAppInfo, matlab.apputil.package.

%Copyright 2012-2018 The MathWorks, Inc.

narginchk(1,1);

validateattributes(filename,{'char','string'},{'scalartext'}, ...
    'matlab.apputil.install','FILE',1)
filename = char(filename);

fullFileName = matlab.internal.apputil.AppUtil.locateFile(filename, ...
    matlab.internal.apputil.AppUtil.FileExtension);
if isempty(fullFileName)
    error(message('MATLAB:apputil:create:filenotfound', filename));
end
    
% Install the app.
% We get back an object of type com.mathworks.appmanagement.actions.AppInstaller.InstallResult.
installresultobj = com.mathworks.appmanagement.actions.AppInstaller.install(java.io.File(fullFileName));
if ~installresultobj.getSucceeded()
    failuremessage = installresultobj.getResultMessage();
    if ~isempty(failuremessage)
        error(message('MATLAB:apputil:install:installfailed', ...
            char(failuremessage)));
    else
        error(message('MATLAB:apputil:install:installfailureunknown', ...
            fullFileName));
    end
end
appinfo = appinstall.internal.getappmetadata(fullFileName);

infos = matlab.internal.apputil.getAllAppInfo(char(com.mathworks.appmanagement.MlappinstallUtil.getAppInstallationFolder.getAbsolutePath));

appIndex = strncmp(appinfo.GUID, {infos.GUID}, length(appinfo.GUID));

if ~any(appIndex)
    error(message('MATLAB:apputil:install:unknownfailure'));
end

status = rmfield(infos(appIndex), 'GUID');

if installresultobj.getUpdated()
   status.status = 'updated';
end
