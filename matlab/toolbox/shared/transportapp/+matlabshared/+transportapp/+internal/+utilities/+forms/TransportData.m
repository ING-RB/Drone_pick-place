classdef TransportData
    %TRANSPORTDATA contains transport operation data, like the type of
    %operation or action to be performed on the transport, the values to
    %write or number of values to read, and the datatype associated with
    %the transport operation.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties
        Action string {matlabshared.transportapp.internal.utilities.TransportDataValidator.validateAction(Action)} = string.empty
        Value
        DataType string {matlabshared.transportapp.internal.utilities.TransportDataValidator.validateDataType(DataType)} = string.empty
        UserData
    end

    methods
        function obj = TransportData(action, value, dataType, userData)
            arguments
                action = string.empty
                value = []
                dataType = string.empty
                userData = []
            end
            obj.Action = action;
            obj.Value = value;
            obj.DataType = dataType;
            obj.UserData = userData;
        end
    end
end
