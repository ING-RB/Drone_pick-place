function [clearRMW, resetDDSEnv,resetPath,cleanPlatformPath] = setRMWImplPathEnv(rmwImplementation, ...
                                                                                 orgPathEnvValue, ...
                                                                                 archSpecificEnv, ...
                                                                                 orgArchSpecificPathEnvValue)
% setRMWImplPathEnv - Set the RMW implementation environment

% Copyright 2022 The MathWorks, Inc.

resetDDSEnv = [];
resetPath = []; %#ok<NASGU>
cleanPlatformPath = []; %#ok<NASGU>

if strcmp(rmwImplementation, 'rmw_connextdds')
    [resetDDSEnv,resetPath,cleanPlatformPath] = ...
        setRMWImplPathEnvForConnext(orgPathEnvValue, archSpecificEnv, orgArchSpecificPathEnvValue);
elseif strcmp(rmwImplementation, 'rmw_iceoryx_cpp')
    [resetPath,cleanPlatformPath] = ...
        setRMWImplPathEnvForIceoryx(orgPathEnvValue, archSpecificEnv, orgArchSpecificPathEnvValue);
else
    [resetPath, cleanPlatformPath] = ...
        setRMWImplPathEnvForCustomRMW(rmwImplementation, orgPathEnvValue, archSpecificEnv, orgArchSpecificPathEnvValue);
end

rmwCurrentValue = getenv('RMW_IMPLEMENTATION');
setenv('RMW_IMPLEMENTATION', rmwImplementation);
clearRMW = onCleanup(...
    @() setenv('RMW_IMPLEMENTATION', rmwCurrentValue));

end

function [resetDDSEnv,resetPath,cleanPlatformPath] = setRMWImplPathEnvForConnext(orgPathEnvValue, ...
                                                                                 archSpecificEnv, ...
                                                                                 orgArchSpecificPathEnvValue)
% setRMWImplPathEnvForConnext - Set the platform specific environment variables
% for rmw_connextdds as RMW implementation.

ddsEnv = ros.internal.DDSEnvironment();
nddsHomeCurrentVal = getenv('NDDSHOME');
setenv('NDDSHOME', ddsEnv.DDSRoot);
resetDDSEnv = onCleanup(...
    @() setenv('NDDSHOME', nddsHomeCurrentVal));

customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance;
customRMWDirList = getBinDirList(customRMWRegistry);

resetPath = onCleanup(@() setenv('PATH', orgPathEnvValue));
setenv('PATH',[fullfile(getenv('NDDSHOME'),'bin'), pathsep, getenv('PATH')]);

setenv(archSpecificEnv, strjoin([customRMWDirList ...
    fullfile(getenv('NDDSHOME'),'lib', ddsEnv.DDSArchName) ...
    getenv(archSpecificEnv)], pathsep));

cleanPlatformPath = onCleanup(...
    @() setenv(archSpecificEnv, orgArchSpecificPathEnvValue));
end

function [resetPath,cleanPlatformPath] = setRMWImplPathEnvForIceoryx(orgPathEnvValue, ...
                                                                                 archSpecificEnv, ...
                                                                                 orgArchSpecificPathEnvValue)
% setRMWImplPathEnvForIceoryx - Set the platform specific environment variables
% for rmw_iceoryx_cpp as RMW implementation.

iceoryxEnv = ros.internal.IceoryxEnvironment();
customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance;
customRMWDirList = getBinDirList(customRMWRegistry);

resetPath = onCleanup(@() setenv('PATH', orgPathEnvValue));
setenv('PATH',[fullfile(iceoryxEnv.IceoryxRoot,'bin'), pathsep, getenv('PATH')]);

setenv(archSpecificEnv, strjoin([customRMWDirList ...
    fullfile(iceoryxEnv.IceoryxRoot,'lib') ...
    getenv(archSpecificEnv)], pathsep));

cleanPlatformPath = onCleanup(...
    @() setenv(archSpecificEnv, orgArchSpecificPathEnvValue));

ros.ros2.internal.RouDiExecutor.manageRouDiApplication("addNode");

end

function [resetPath,cleanPlatformPath] = setRMWImplPathEnvForCustomRMW(rmwImplementation, orgPathEnvValue, ...
                                                                                 archSpecificEnv, ...
                                                                                 orgArchSpecificPathEnvValue)
% setRMWImplPathEnvForCustomRMW - Set the platform specific environment variables
% for custom RMW implementation.

customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance;
customRMWDirList = getBinDirList(customRMWRegistry);

resetPath=[];
cleanPlatformPath = [];

if ~isempty(customRMWDirList)
    % Get the middleware installation for the selected RMW implementation
    rmwInfo = customRMWRegistry.getRMWInfo(rmwImplementation);

    if ~isempty(rmwInfo)
        middlewareInstallation = rmwInfo.middlewarePath;
        middlewareHomeBinVal = fullfile(middlewareInstallation,'bin');
        middlewareHomeLibVal = fullfile(middlewareInstallation,'lib');

        resetPath = onCleanup(@() setenv('PATH', orgPathEnvValue));
        setenv('PATH',[middlewareHomeBinVal, pathsep, getenv('PATH')]);

        setenv(archSpecificEnv, strjoin([customRMWDirList ...
            middlewareHomeLibVal ...
            getenv(archSpecificEnv)], pathsep));

        cleanPlatformPath = onCleanup(...
            @() setenv(archSpecificEnv, orgArchSpecificPathEnvValue));
    end
end
end