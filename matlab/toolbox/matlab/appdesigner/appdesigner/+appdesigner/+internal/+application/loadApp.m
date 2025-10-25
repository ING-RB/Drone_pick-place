function [loadOutcome, loadedData] = loadApp(filepath)

% LOADAPP Facade API for App Designer client side getting app data to load
%
% Retrieve the data of the App of file - "filepath".  This
% is called by the client when the user chooses an App to open.

% Copyright 2017-2024 The MathWorks, Inc.

import appdesigner.internal.serialization.validator.deserialization.*;

% Assume load will be successful
loadOutcome.Status = 'success';
loadedData = struct.empty;


try

    deserializer = appdesigner.internal.serialization.DeserializerFactory.createDeserializer(filepath);

    appData = deserializer.getAppData();

    codeData = appData.code;

    if ( isfield(codeData,'StartupCallback'))
        % the client expects the 'startupCallback' field to be called 'StartupFcn'.
        % Changing the key name here because the client has many occurences
        % of 'StartupFcn' and don't want to make that change in the initial
        % checkin
        codeData.StartupFcn = codeData.StartupCallback;
        codeData = rmfield(codeData,'StartupCallback');
    end

    % if certain features were not used by the user, and therefore no data
    % for them is in the mlapp file, set the corresponding data expected by
    % the client
    
    %  Run Arguments
    if ( isfield(appData,'runConfigurations' ))
        runConfigurations = appData.runConfigurations;
    else
        runConfigurations = {''};
    end

    % Groups
    if isfield(appData.components,'Groups')
        groups = appData.components.Groups;
    else
        groups = [];
    end

    % User properties and methods
    if ( ~isfield(codeData,'EditableSectionCode'))
        codeData.EditableSectionCode = {};
    end

    % Startup function
    if ( ~isfield(codeData,'StartupFcn'))
        codeData.StartupFcn = [];
    end

    % Startup function input parameters
    if ( ~isfield(codeData,'InputParameters'))
        codeData.InputParameters = {};
    end

    % callbacks
    if ( ~isfield(codeData,'Callbacks'))
        codeData.Callbacks = [];
    end

    % singleton
    if ( ~isfield(codeData,'SingletonMode'))
        codeData.SingletonMode = '';
    end

    % Bindings
    if ( ~isfield(codeData,'Bindings'))
        codeData.Bindings = [];
    end

    % saved code text digest to be sent to client side
    % to:
    % 1) check if app generated code would be different upon loading
    % 2) check if app is out of sync with file on disk, for instance,
    %    mlapp file is modified from MLAPP Diff/Merge tool
    [codeData.DigestOfLastSavedCodeText, ~] = appdesigner.internal.codegeneration.getAppFileCodeDigest(filepath);

    % convert the component and their properties to structs
    componentConverter = appdesigner.internal.serialization.util.ComponentObjectToStructConverter(appData.components.UIFigure);
    [componentData, erroredComponentCodeNames] = componentConverter.getConvertedData();

    % get the metadata of the app
    appMetadata  = deserializer.getAppMetadata();

    % get the compatibility type of the app (SAME, BACKWARD, FORWARD)
    versionOfLoadedApp = appMetadata.MATLABRelease;
    compatibilityType = appdesigner.internal.serialization.util.ReleaseUtil.getCompatibilityType(versionOfLoadedApp);

    % create a structure for the client to handle compatibility
    compatibilityData.CompatibilityType = char(compatibilityType);
    compatibilityData.LoadedVersion = versionOfLoadedApp;
    compatibilityData.CurrentVersion = appdesigner.internal.serialization.util.ReleaseUtil.getCurrentRelease();
    compatibilityData.MLAPPVersion = appMetadata.MLAPPVersion;

    % collect any warnings and put in compatibility
    if(~isempty(deserializer.Warnings))

        % store as cell so its always an array in UI
        compatibilityData.Warnings = {};

        for idx = 1:length(deserializer.Warnings)
            warning = deserializer.Warnings(idx);

            newWarnings = struct;
            newWarnings.Id = warning.Id;
            newWarnings.Info = warning.Info;

            compatibilityData.Warnings{end+1} = newWarnings;
        end
    end

    % get the serialized AppName
    serializedAppName = codeData.ClassName;
    [~, appName] =  fileparts(filepath);
    appNameData = struct('AppName', appName, 'SerializedAppName', serializedAppName);

    % create the loadData structure to be sent to the client
    loadedData = struct;
    loadedData.ComponentData = componentData;
    loadedData.GroupData = groups;
    loadedData.RunConfigurations = runConfigurations;
    loadedData.AppMetaData = appMetadata;
    loadedData.CompatibilityData = compatibilityData;
    loadedData.AppNameData = appNameData;

    appTypeDataLoader = appdesigner.internal.serialization.loader ...
        .apptypedataloader.AppTypeDataLoaderFactory ...
        .createAppTypeDataLoader(appMetadata.AppType);

    loadedData.CodeData = appTypeDataLoader.load(codeData);

    % Only send info about components that failed to load if any did fail.
    if ~isempty(erroredComponentCodeNames)
        loadedData.ErroredComponents = struct;
        loadedData.ErroredComponents.CodeNames = erroredComponentCodeNames;
    end

    if (isfield(appData, 'simulink'))
        loadedData.SimulinkData = appData.simulink;
    end

catch me
    % Error Message
    loadOutcome.Message = me.message;
    loadOutcome.Status = 'error';
    loadOutcome.ErrorID = me.identifier;
end

end
