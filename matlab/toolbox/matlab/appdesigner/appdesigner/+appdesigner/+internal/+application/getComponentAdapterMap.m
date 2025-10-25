function componentAdapterMap = getComponentAdapterMap()
%GETCOMPONENTADAPTERMAP Internal function to get component adapter map
% from AppDesignEnviornment

% Copyright 2021 The MathWorks, Inc.

    appDesignEvironment = appdesigner.internal.application.getAppDesignEnvironment();
    componentAdapterMap = appDesignEvironment.getComponentAdapterMap();
    if isempty(componentAdapterMap)
        % AppDesignEnvironment now gets ComponentAdapterMap in background taske
        % queue as part of our App Designer startup performance work.
        % If we do not start App Designer before calling into
        % appdesigner.internal.application.getAppDesignEnvironment, we may have
        % no chance to get component adapter map, for instance,
        % 1) Comparison API: appdesigner.internal.comparison.getAppData calls
        % into Deserializer directly
        % 2) appdesignerqe.mlappinfo calls into appdesigner.internal.application.loadApp
        % 3) munit tests could call getComponentAdapterMap on AppDesignEnvironment directly
        % without running async initialization
        % Todo: when it's able to use backgroundPool from AsyncTask, we
        % can refactor this.
        componentAdapterMap = appdesigner.internal.appmetadata.getProductionComponentAdapterMap();
        appDesignEvironment.setComponentAdapterMap(componentAdapterMap);
    end
end

