function deviceList = createDataStructArrayFromJSON(filepaths)
% This is an internal utility function that creates data structure array
% with specific fields from JSON files

% Copyright 2018-2019 The MathWorks, Inc.

    validateFiles(filepaths);
    
    % get registered fields of JSON files
    registeredFields = matlab.hwmgr.internal.util.getRequiredJSONFields().RegisteredFields;
    % preallocate a maximum capacity of supported devices
    PreallocNum = 500;
    % -----------------------------------------------------------

    % prepare struct array
    structInputs = [registeredFields; cell(size(registeredFields))];
    deviceList = repmat(struct(structInputs{:}), PreallocNum, 1);

    % keep count of number of devices
    deviceCount = 1;

     % read JSON files
    for i = 1:length(filepaths) 
        filepath = filepaths{i}; 
        txt = fileread(filepath); 
        data = jsondecode(txt); 
        % data must be a struct array, if it's cell, it shouldn't pass test
        % data is a column vector
        if iscell(data) 
            messageID = 'hwmanagerapp:deviceenumerator:InvalidJSONFile';
            error(message(messageID, filepath));
        end
        % validate struct fields, all fields must exist in RegisteredFields
        foundFields = fieldnames(data)'; 
        for curDeviceStruct = data' 
             % populate new struct array
            for currentField = foundFields 
                deviceList(deviceCount).(currentField{:}) = curDeviceStruct.(currentField{:}); 
            end 
            deviceCount = deviceCount + 1; 
        end 
    end 
    % remove unused struct
    deviceList(deviceCount:end) = [];
end

function validateFiles(filepaths)
    % validate filepaths format
    if ~isa(filepaths, 'cell') || ~isvector(filepaths)
        messageID = 'hwmanagerapp:deviceenumerator:InvalidInputTypeForPaths';
        error(message(messageID));
    end

    % validate files exist and file extentions are json
    for i = 1:length(filepaths)
        filepath = filepaths{i};
        fileType = exist(filepaths{i}, 'file');
        if fileType ~= 2
            messageID = 'hwmanagerapp:deviceenumerator:FileDoesNotExist';
            error(message(messageID, filepath));
        end
        [~, ~, ext] = fileparts(filepaths{i});
        if ~strcmpi(ext, '.json')
            messageID = 'hwmanagerapp:deviceenumerator:InvalidFileType';
            error(message(messageID, filepath));
        end
    end   
end

% LocalWords:  filepaths extentions
