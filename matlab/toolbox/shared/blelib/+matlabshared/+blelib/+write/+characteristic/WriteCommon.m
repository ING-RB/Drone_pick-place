classdef WriteCommon < matlabshared.blelib.write.characteristic.Interface
%WRITECOMMON - Concrete write interface class for characteristic that 
%has "Write","WriteWithoutResponse","AuthenticatedSignedWrites" or 
%"ReliableWrites" property
    
% Copyright 2019-2020 The MathWorks, Inc.
    
    methods
        function write(obj, client, varargin)
            narginchk(3,5);
                
            % Validate optional inputs
            [type, precision] = validateOptionalInputs(obj, varargin{2:end});
            
            % Validate type if specified or derive type if not specified
            type = validateType(obj, type, client.Attributes);
            
            % Validate data
            data = varargin{1};
            data = matlabshared.blelib.internal.validateDataRange(data, precision);
            
            try
                execute(client,matlabshared.blelib.internal.ExecuteCommands.WRITE_CHARACTERISTIC,data, type=="WithResponse");
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToWriteCharacteristic');
                end
            end
        end
    end
    
    methods(Access = ?matlabshared.blelib.internal.TestAccessor) 
        function [type, precision] = validateOptionalInputs(~,varargin)
            % Validate optional input parameters of write method to allow
            % the following scenarios:
            %   write(data, "uint16")
            %   write(data, "WithoutResponse")
            %   write(data, "uint16", "WithoutResponse")
            %   write(data, "WithoutResponse", "uint16")
            
            type = "WithResponse";
            precision = "uint8";
            
            % Return immediately if no inputs are specified
            if nargin == 1
                return
            end

            % Check against union of both types and precisions to allow
            % random order of the optional values. As a result, the inputs
            % might not be assigned to the right field in p.Results and it
            % is fixed in checkDuplicateOptionValues next.
            p = inputParser;
            validateFcn = @(x) isstring(validatestring(x, [matlabshared.blelib.internal.Constants.WriteTypes, matlabshared.blelib.internal.Constants.WritePrecisions]));
            addOptional(p, "Type", "", validateFcn);
            addOptional(p, "Precision", "", validateFcn);
            p.parse(varargin{:});
            
            % Check if duplicate values are given to both type and
            % precision
            typeSpecified = false;
            precisionSpecified = false;
            specifiedOptionals = setdiff(p.Parameters,p.UsingDefaults);
            for index = 1:numel(specifiedOptionals) % only check for parameters user has specified
                checkDuplicateOptionValues(p.Results.(specifiedOptionals{index}));
            end
            
            function checkDuplicateOptionValues(input)
                % Correct partial matched optional parameter and also check
                % that type or precision is not specified twice
                
                % correct partial match
                input = validatestring(input, [matlabshared.blelib.internal.Constants.WriteTypes, matlabshared.blelib.internal.Constants.WritePrecisions]);
                if ismember(input, matlabshared.blelib.internal.Constants.WriteTypes)
                    if typeSpecified
                        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:duplicateWriteOptions');
                    end
                    type = input;
                    typeSpecified = true;
                elseif ismember(input, matlabshared.blelib.internal.Constants.WritePrecisions)
                    if precisionSpecified
                        matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:duplicateWriteOptions');
                    end
                    precision = input;
                    precisionSpecified = true;
                end
            end
        end
        
        function output = validateType(~, input, attributes)
            % Validate type, if specified, is supported on the
            % characteristic or derive type, if not specified, from 
            % attributes of characteristic
            
            if isempty(input) % type unspecified derive from attributes
                if any(ismember(attributes, ["Write","ReliableWrites"]))
                    output = "WithResponse";
                elseif any(ismember(attributes, ["WriteWithoutResponse","AuthenticatedSignedWrites"]))
                    output = "WithoutResponse";
                end
            else % type specified, check if supported
                if (input == "WithResponse") && ~any(ismember(attributes, ["Write","ReliableWrites"]))
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedWriteType');
                end
                if (input == "WithoutResponse") && ~any(ismember(attributes, ["WriteWithoutResponse","AuthenticatedSignedWrites"]))
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedWriteType');
                end
                output = input;
            end
        end
    end
end
