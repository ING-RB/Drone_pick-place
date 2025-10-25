classdef TransportDataValidator
    %TRANSPORTDATAVALIDATOR validates action and data type value.

    % Copyright 2021-2023 The MathWorks, Inc.

    %% Private Constructor
    methods (Access = private)
        function obj = TransportDataValidator()
        end
    end

    properties (Constant)
        AllPrecision = ...
            ["", "int8", "uint8", "int16", "uint16", "int32", "uint32", "int64", "uint64", "single", "double", "char", "string", ...
            string(message("transportapp:appspace:propertyinspector:ErrorDataType").getString)]
        AllActions = ...
            ["", "Read", "ReadLine", "ReadBinblock", "Write", "WriteLine", "WriteBinblock", "WriteRead"]
        Separator = ", "
    end

    %% Static Helper Functions
    methods (Static)
        function validateAction(action)
            % Validate that the action is one of "AllActions", else error.

            import matlabshared.transportapp.internal.utilities.TransportDataValidator
            list = TransportDataValidator.AllActions;
            if ~ismember(action, list)
                listString = TransportDataValidator.prepareList(list);
                throw(MException(message("transportapp:utilities:InvalidAction", action, listString)));
            end
        end

        function validateDataType(dataType)
            % Validate that the dataType  is one of "AllPrecision", else
            % error.

            import matlabshared.transportapp.internal.utilities.TransportDataValidator
            list = TransportDataValidator.AllPrecision;
            if ~ismember(dataType, list)
                listString = TransportDataValidator.prepareList(list);
                throw(MException(message("transportapp:utilities:InvalidDataType", dataType, listString)));
            end
        end

        function flag = binblockHeaderExists(transportData)
            % Returns true if the entered transportData instance contains
            % a non-empty binblock header. Returns false otherwise.

            arguments
                transportData (1, 1) matlabshared.transportapp.internal.utilities.forms.TransportData
            end
            flag = isfield(transportData.UserData, "Header") && ...
                ~isempty(transportData.UserData.Header) && transportData.UserData.Header ~= "";
        end
    end

    methods (Static, Access = private)
        function listString = prepareList(list)
            import matlabshared.transportapp.internal.utilities.TransportDataValidator
            listString = strjoin(list, TransportDataValidator.Separator);
            if ismember("", list)
                listString = """""" + listString;
            end
        end
    end
end
