classdef SensorParamLoader
%   This class is for internal use only. It may be removed in the future. 
% SENSORPARAMLOADER Helper functions to load imuSensor parameters  
%
%

%   Copyright 2019 The MathWorks, Inc.    

    methods (Static)
        function s = extractPartFromJSON(file, pn)
        %EXTRACTPARTFROMJSON Read json file and extract config for part
        %   params pn is a part number s is a struct describing the
        %   IMU. The filename file is a JSON file holding IMU parameters.
            try
                json = fusion.internal.SensorParamLoader.json2struct(file);
            catch ME
                % Generic file read error
                error(message('shared_positioning:imuSensor:FailedRead', ...
                    file));
            end
            s = fusion.internal.SensorParamLoader.findPartInJSON(json, pn);
        end
        
        function pv = parseParams(s)
        %PARSEPARAMS parse the parameters in struct s from the JSON. Convert  the struct
        %to property-value pairs suitable for constructing accelparams and friends. 
        
            %Change fields values from strings to numbers
            fn = fieldnames(s);
            pv = cell(1, 2*numel(fn));
            for ii=1:numel(fn)
                thisfield = fn{ii};

                % Create the property name
                pv{(2*ii) - 1} = thisfield;

                % Convert the value string to a number
                thisvalue = s.(thisfield);
                try
                    if ~isnumeric(thisvalue)
                        if strcmpi(thisvalue, 'inf')
                            e = Inf;
                        else
                            error(message('shared_positioning:imuSensor:UnexpectedToken', thisvalue));
                        end
                        
                    else
                        e = thisvalue;
                    end
                    
                    if numel(e) == 3
                        e = reshape(e,1,[]); % make row vectors
                    end
                    pv{2*ii} = e;
                catch ME
                    switch (ME.identifier)
                        case 'shared_positioning:imuSensor:UnexpectedToken'
                            rethrow(ME);
                        otherwise
                            error(message('shared_positioning:imuSensor:expectedNumeric'));
                    end
                end
            end
        end
        
        function s = findPartInJSON(json, pn)
        %FINDPARTINJSON Find a part in decoded json. 
        %   json is the output of  json2struct - a struct
        %   pn is the part number to be found
        %   s is the substruct in json for the part number

            if isempty(json)
                s = json; 
                return;
            end
            
            % Must be a non-empty struct
            potentialParts = fieldnames(json);  % Possible parts. For example: lsm9ds1, mpu6050.
            % Need to validate to be sure.
            
            foundPart = struct([]);
            for ii=1:numel(potentialParts)
                if strcmpi(pn, potentialParts{ii})
                    foundPart = potentialParts{ii};
                end
            end
            
            if isempty(foundPart)
                s = foundPart;
                return;
            end
            % Validate foundPart params;
            param = json.(foundPart);
            hasAGM =  validateStruct(param);
            if any(hasAGM)
                % At least one valid subfield.
                % Prune subparts we don't want.
                
                fn = fieldnames(param);
                badfields = fn(~hasAGM);
                if ~isempty(badfields)
                    param = rmfield(param, badfields);
                end 
                s = param;
                
            else
                % No Accel, Gyro or Mag
                s = struct([]);            
            end
            
        end
        
        function pn = getPartsInFile(file)
        %GETPARTSINFILE Extract a list of part numbers in a json file
        %   Used for tab completion, so this should just swallow any errors
        %   and return an empty list in case of a failure. The returned pn
        %   is a cell array of parts found in the json file.
           
            try
                s = fusion.internal.SensorParamLoader.json2struct(file);
                if isempty(s) 
                    pn = {};
                    return;
                end
                
                % Must be a non-empty struct
                potentialParts = fieldnames(s);  % Possible parts: lsm9ds1, mpu6050.
                % Need to validate to be sure.
                lst = cell(1,numel(potentialParts));
                
                %Validate parts
                for ii=1:numel(potentialParts)
                    thispart = potentialParts{ii}; %lsm9ds1
                    params = s.(thispart); %struct('Acc',... 'gyro',... mag)
                    if isstruct(params)
                        hasAGM = validateStruct(params);
                        if any(hasAGM)
                            lst{ii} = thispart;
                        end
                    end
                    
                end
                % Prune empty cells
                lst = lst(~cellfun('isempty', lst));
                pn = reshape(lst, [],1);
            catch
                pn = {};
            end
        end
        function st  =json2struct(filename)
        %JSON2STRUCT read a file and extract json info. If not a bunch of structs, return an empty struct
            fid = fopen(filename);
            s = fscanf(fid, '%s');
            st = jsondecode(s);

            if ~(~isempty(st) && isstruct(st))
                st = struct([]); 
            end

            fclose(fid);
        end
        
        function params = configureParams(params, pv)
        %CONFIGUREPARAMS configure params based on the property-value pairs
        % pv. Skip any property-value pairs for which the property is not
        % present in params.
            try
                for ii=1:2:numel(pv)
                    if isprop(params, pv{ii})
                        params.(pv{ii}) = pv{ii+1};
                    end
                end
            catch ME
                error(message('shared_positioning:imuSensor:paramConstruction', ...
                    class(params), ME.message))
            end
            
        end
    end
    
end

function valid = validateStruct(params)
% VALIDATESTRUCT ensure that the struct params has fields Accelerometer,
% Gyroscope and/or Magnetometer
if isstruct(params)
    subfields = fieldnames(params);
    valid = contains(subfields, {'Accelerometer', 'Gyroscope', 'Magnetometer'});
else
    valid = false;
end
end

