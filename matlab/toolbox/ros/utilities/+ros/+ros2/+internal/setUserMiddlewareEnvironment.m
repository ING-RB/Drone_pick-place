function resetMiddlewareEnvs = setUserMiddlewareEnvironment(rmwImplementation)
% setUserMiddlewareEnvironment - Set the user provided middleware environment
% in the ROS Middleware Configuration GUI.

% Copyright 2022 The MathWorks, Inc.

% set user environment variables which are provided in the Middleware
% Installation Environment screen of ROS Middleware Configuration GUI.

resetMiddlewareEnvs = {};
% Get the middleware installation for the selected RMW implementation
customRMWRegistry = ros.internal.CustomRMWRegistry.getInstance;
rmwInfo = customRMWRegistry.getRMWInfo(rmwImplementation);

if ~isempty(rmwInfo)
    middlewareInstallation = rmwInfo.middlewarePath;
    middlewareEnv = ros.internal.MiddlewareEnvironment.getInstance;
    if isKey(middlewareEnv.MiddlewareMap, middlewareInstallation)
        userEnvVars = middlewareEnv.MiddlewareMap(middlewareInstallation).keys();
        userEnvValues = middlewareEnv.MiddlewareMap(middlewareInstallation).values();

        for i=1:length(userEnvVars)
            if ismember(userEnvVars{i}, {'PATH', 'LD_LIBRARY_PATH', 'DYLD_LIBRARY_PATH'})
                setenv(userEnvVars{i}, [userEnvValues{i}, pathsep, getenv(userEnvVars{i})]);
                resetMiddlewareEnvs{i} = []; %#ok<AGROW>
            else
                setenv(userEnvVars{i},userEnvValues{i});
                resetMiddlewareEnvs{i} = onCleanup(@()unsetenv(userEnvVars{i})); %#ok<AGROW>
            end
        end
    end
end

end
