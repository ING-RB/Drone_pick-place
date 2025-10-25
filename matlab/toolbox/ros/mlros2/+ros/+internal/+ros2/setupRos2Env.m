function [pathEnv, amentPrefixEnv, cleanPath, cleanAmentPath] = setupRos2Env()

%This function is for internal use only. It may be removed in the future.

%   Copyright 2023 The MathWorks, Inc.

    % setup env-variables needed for ROS2 builtins mcos objects

    mlRoot = matlabroot;
    archKeys = {'win64', 'glnxa64', 'maci64','maca64'};
    arch = computer('arch');
    envPathMap = ...
        containers.Map(archKeys, ...
                       {'PATH', ...             % win64
                        'LD_LIBRARY_PATH', ...  % glnxa64
                        'DYLD_LIBRARY_PATH',...
                        'DYLD_LIBRARY_PATH'});  % maci64
    pathEnv = getenv(envPathMap(arch));
    amentPrefixEnv = ros.ros2.internal.getAmentPrefixPath;
    % start directory suggestion
    startPathBase = fullfile(mlRoot, 'sys', 'ros2', ...
                             arch, 'ros2');
    startPathMap = ...
        containers.Map(archKeys, ...
                       {'bin', ...    % win64
                        'lib', ...    % glnxa64
                        'lib', ...    % maci64
                        'lib'});      % maca64
    bagLibsPath = fullfile(startPathBase, startPathMap(arch));
    %SetupPaths for ros2bagreader
    customMsgRegistry = ros.internal.CustomMessageRegistry.getInstance('ros2');
    customMsgDirList = getBinDirList(customMsgRegistry);
    msgList = getMessageList(customMsgRegistry);
    msgInfoList = cellfun(@(msg) getMessageInfo(customMsgRegistry, msg), msgList);
    installDirList = arrayfun(@(msgInfo) msgInfo.installDir, ...
                              msgInfoList, 'UniformOutput', false);
    setenv(envPathMap(arch), ...
           strjoin([bagLibsPath,customMsgDirList,...
                    pathEnv], pathsep));
    setenv('AMENT_PREFIX_PATH', strjoin([unique(installDirList), amentPrefixEnv], pathsep));
    cleanPath = onCleanup(...
        @() setenv(envPathMap(arch), pathEnv));
    cleanAmentPath = onCleanup(...
        @() setenv('AMENT_PREFIX_PATH', amentPrefixEnv));
end