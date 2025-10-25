function reconstructAfterSettingImportOptions(pds, propName, propValue)
%reconstructAfterSettingImportOptions   Rebuild the ParquetDatastore after a
%   ParquetImportOptions-related property has changed.

%   Copyright 2022 The MathWorks, Inc.

    try
        % Create a copy of the ParquetImportOptions and try setting the
        % property.
        opts = pds.ImportOptions;
        opts.(propName) = propValue;
    
        % Reconstruct the datastore with new ImportOptions.
        pds.ImportOptions = opts;
    catch ME
        handler = matlab.io.datastore.exceptions.makeDebugModeHandler();
        handler(ME);
    end
end
