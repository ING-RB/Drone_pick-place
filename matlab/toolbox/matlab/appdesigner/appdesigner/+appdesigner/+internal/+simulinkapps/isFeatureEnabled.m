function tf = isFeatureEnabled()
    tf = appdesigner.internal.license.LicenseChecker.isProductAvailable("simulink_compiler") && logical(slsvTestingHook('SimulinkAppDesignerIntegration'));
end

