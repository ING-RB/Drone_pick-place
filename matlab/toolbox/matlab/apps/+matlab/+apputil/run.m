function run(appid)
% matlab.apputil.run Run an installed app.
% 
%   matlab.apputil.run(APPID) runs the specified app.  The app must be
%   installed.  APPID is a character vector or string containing the ID of
%   the app as returned by matlab.apputil.install when the app was
%   installed or by matlab.apputil.getInstalledAppInfo.
%
%   Example:
%
%     matlab.apputil.run('DataVisualizationAPP');
%
%   See also: matlab.apputil.create, matlab.apputil.install, matlab.apputil.getInstalledAppInfo.

% Copyright 2012-2018 The MathWorks, Inc.

narginchk(1,1);

validateattributes(appid,{'char','string'},{'scalartext'}, ...
    'matlab.apputil.run','APPID',1)
appid = char(appid);

infos = matlab.internal.apputil.AppUtil.getAllAppsInDefaultLocation;

if isempty(infos)
    error(message('MATLAB:apputil:run:notinstalled', appid));
end

appIndex = matlab.internal.apputil.AppUtil.findAppIDs({infos.id}, appid, false);

if ~any((appIndex))
    error(message('MATLAB:apputil:run:notinstalled', appid));
end

if numel(infos(appIndex)) > 1
    error(message('MATLAB:apputil:run:findappfailed'));
end

if ~matlab.addons.isAddonEnabled(infos(appIndex).GUID)
    error(message('MATLAB:apputil:run:appdisabled')); 
end

appLocation = infos(appIndex).location;
appName = matlab.internal.apputil.AppUtil.genwrapperfilename(appLocation);
appinstall.internal.runapp(appName, appLocation);

end

