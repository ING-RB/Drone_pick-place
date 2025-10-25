function numericI2CAddress = validateHexParameterRanged(paramValue)

% This function returns numeric I2C Addresses from the input.
% The I2C address can be numeric(0x98,105), string("0x98"), char ('0x98')
% Cell array and numeric arrays are supported

%   Copyright 2020 The MathWorks, Inc.
if ischar(paramValue)
    paramValue = string(paramValue);
end
numericI2CAddress = uint8(zeros(1,numel(paramValue)));
for i=1:numel(paramValue)
    % If the input is cell array use brace indexing
    if iscell(paramValue)
        val = paramValue{i};
    else
        val = paramValue(i);
    end
    if isnumeric(val) && isscalar(val)
        try
            validateattributes(val, {'double', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'},...
                {'scalar', 'integer', 'real', 'nonnegative', 'finite', 'nonnan'});
        catch
            error(message('matlab_sensors:general:invalidI2CAddressValue'));
        end
    end
    if isstring(val)||ischar(val)
         try
            validateattributes(val, {'char','string'},{'nonempty'},'','I2CAddress');
         catch ME
            throwAsCaller(ME)
         end
        tmpValue= char(val);
        if length(tmpValue)>=3 && strcmpi(tmpValue(1:2), '0x')
            tmpValue = tmpValue(3:end);
        end
        if ~isempty(tmpValue) && strcmpi(tmpValue(end), 'h')
            tmpValue(end) = [];
        end
        try
            numericI2CAddress(i) = uint8(hex2dec(tmpValue));
        catch
            % TO DO Modify the errror message
            error(message('matlab_sensors:general:invalidI2CAddressValue'));
        end
    else
        numericI2CAddress(i) = uint8(val);
    end
end
end

