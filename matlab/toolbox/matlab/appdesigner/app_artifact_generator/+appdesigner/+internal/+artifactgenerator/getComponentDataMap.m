function map = getComponentDataMap()
    % GETCOMPONENTDATAMAP 

%   Copyright 2024 The MathWorks, Inc.

    persistent dataMap;

    function combine(source)
        keys = source.keys;
        for i = 1:length(keys)
            key = keys{i};
            dataMap(key) = source(key);
        end
    end

    if isempty(dataMap)
        dataMap = dictionary();

        combine(matlab.ui.internal.MAPPIntegration.getComponentMap());

        try
            data = Aero.ui.control.internal.MAPPIntegration.getComponentMap();
            combine(data);
        catch ME
            % not installed - ignore
        end

        try
            data = matlab.ui.scope.internal.MAPPIntegration.getComponentMap();
            combine(data);
        catch ME
            % not installed - ignore
        end
    end

    map = dataMap;
end
