function codeDataStruct = convertVersion1CodeDataToVersion2(olderAppCodeData)
    %CONVERTVERSION1CODEDATATOVERSION2 converts the older format data to the new format
    % Copyright 2021 The MathWorks, Inc.
    
    % create a CodeData structure
    codeDataStruct = struct();
    codeDataStruct.ClassName = olderAppCodeData.GeneratedClassName;
    codeDataStruct.EditableSectionCode = olderAppCodeData.EditableSection.Code;
    
    % Version 1 apps had InputParams in a cell array
    if ( ~isempty(olderAppCodeData.InputParameters))
        codeDataStruct.InputParameters = olderAppCodeData.InputParameters{1};
    else
        codeDataStruct.InputParameters = '';
    end
    
    % create a struct array for callbacks
    cbdata = struct.empty;
    callbacks = olderAppCodeData.Callbacks;
    codeDataStruct.Callbacks = [];
    for i=1:length(callbacks)
        callback = callbacks(i);
        cbdata(i).Name = callback.Name;
        cbdata(i).Code = callback.Code;
        cbdata(i).ComponentData = struct('CodeName', {}, ...
            'CallbackPropertyName', {}, 'ComponentType', {});        
    end
    % if there are callbacks add them to the codeDataStruct
    % otherwise this field should be empty
    if (~isempty(cbdata))
        codeDataStruct.Callbacks = cbdata;
    end
    
    % startupFcn
    startupFcn = [];
    if ~isempty(olderAppCodeData.ConfigurableStartupFcn)
        startupFcn.Name = olderAppCodeData.ConfigurableStartupFcn.Name;
        startupFcn.Code = olderAppCodeData.ConfigurableStartupFcn.Code;
        % set the componentData to be empty so that it has a
        % similar structure to callbacks
        startupFcn.ComponentData = struct( ...
            'CodeName', {}, ...
            'CallbackPropertyName', {}, ...
            'ComponentType', {});
    end
    codeDataStruct.StartupFcn = startupFcn;
end

