function [codeData, compatibilityData, metaData, appData] = getAppData(filepath)
    
    % GETAPPDATA read App Designer MLAPP file app, code & meta data
    %
    
    % Copyright 2020-2021 The MathWorks, Inc.

    % create mlapp data validators
    import appdesigner.internal.serialization.validator.deserialization.*;

    % - check toolbox license are correct
    validators = {MLAPPLicenseValidator};


    % create a deserializer and get the app Data
    deserializer = appdesigner.internal.serialization.MLAPPDeserializer(filepath, validators);

    if nargout == 4
        % only caller explicitly request appData, call deserializer getAppData 
        % because component deserialization is expensive
        appData = deserializer.getAppData();
        % extract the code Data
        codeData = appData.code;
    else
        % otherwise only get code data, this is faster for version 2 mlapp file
        codeData = deserializer.getAppCodeData();
    end
    metaData = deserializer.getAppMetadata();
    
    % get the compatibility type of the app (SAME, BACKWARD, FORWARD)
    versionOfLoadedApp = metaData.MATLABRelease;
    compatibilityType = appdesigner.internal.serialization.util.ReleaseUtil.getCompatibilityType(versionOfLoadedApp);

    % create a structure for the client to handle compatibility
    compatibilityData.CompatibilityType = char(compatibilityType);
    compatibilityData.LoadedVersion = versionOfLoadedApp;
    compatibilityData.CurrentVersion = appdesigner.internal.serialization.util.ReleaseUtil.getCurrentRelease();
    compatibilityData.MLAPPVersion = metaData.MLAPPVersion;

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
            if(newWarnings.Id == 'MissingLicense')
                compatibilityData.MissingLicense = 'Toolbox';
            end
        end
    end
    
    % Old releases (V1 mlapp file) have StartupFcn as field name
    if (isfield(codeData,'StartupFcn'))
        codeData.StartupCallback = codeData.StartupFcn;
        codeData = rmfield(codeData,'StartupFcn');
    end
    
    % User properties and methods
    if (~isfield(codeData,'EditableSectionCode'))
        codeData.EditableSectionCode = {};
    end
    
    % Startup function
    if (~isfield(codeData,'StartupCallback'))
        codeData.StartupCallback = [];
    end
    
    % callbacks
    if (~isfield(codeData,'Callbacks'))
        codeData.Callbacks = [];
    end
end