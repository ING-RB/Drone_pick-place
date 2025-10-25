function newSLSFSystem(warmupParamsEnv)
    % Check corresponding bit on the environment variable switch
    import simulink.online.internal.WarmupParamsEnum;
    warmupEnvValue = bitand(warmupParamsEnv, WarmupParamsEnum.NewSLSFSystem, 'uint32') > 0;
    if ~warmupEnvValue
        return;
    end

    % Check environment to controll the on/off state of license injection
    onTestEnvStr = getenv('PREWARM_SIMULINK_ON_TEST');
    isOnWarmupTest = ~isempty(onTestEnvStr) && onTestEnvStr ~= '0';
    setupLicense = ~isOnWarmupTest || ~license('test', 'SIMULINK');
    if setupLicense
        % If the Simulink license is not available, we can tell that we are within online
        % warmup progress. Inject the licenses using the license manager.
        % Otherwise whoever triggers the warmup procedure should ensure the availibities of the licenses
        try
            parallel.internal.lmgr.addFeatures(["SIMULINK", "Stateflow"]);
        catch ex
            warning(ex.message);
        end
    end
    licenseCleanup = onCleanup(@() clearupLicenses(setupLicense));

    h = new_system();
    % No need to check stateflow license here
    % Always warmup sl and sf new system together
    % The license should be already injected above
    % or whoever triggers the warmup procedure should ensure the availibities of the licenses
    sf('new', 'machine', '.name', get_param(h, 'Name'), '.simulinkModel', h);
    close_system(h, 0);
end

function clearupLicenses(doLicenseCleanup)
    if ~doLicenseCleanup
        return;
    end
    try
        parallel.internal.lmgr.clearFeatures();
    catch ex
        warning(ex.message);
    end
end  % clearupLicenses
