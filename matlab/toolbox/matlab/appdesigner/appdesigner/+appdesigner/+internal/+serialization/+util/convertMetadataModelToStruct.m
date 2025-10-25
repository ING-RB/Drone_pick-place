function metadataStruct = convertMetadataModelToStruct(metadataModel)
    %CONVERTMETADATAMODELTOSTRUCT Extract the properties from an
    %appdesigner.internal.model.MetadataModel and set them on a struct
    
    % Copyright 2020 The MathWorks, Inc.

    propNames = properties(metadataModel);
    metadataStruct = struct;
    
    for idx = 1:length(propNames)
        propName = propNames{idx};
        metadataStruct.(propName) = metadataModel.(propName);
    end
end
