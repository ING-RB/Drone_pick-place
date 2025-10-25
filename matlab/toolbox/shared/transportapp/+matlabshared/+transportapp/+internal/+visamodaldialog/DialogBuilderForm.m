classdef DialogBuilderForm
    %DIALOGBUILDERFORM form class contains information regarding the
    %Generate Resource section of the Modal Dialog Window. The builder uses
    %this form to create the modal dialog for the different window types.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        ResourceType (1, 1) string

        BoardNumberRowIndex {validateRowIndex(BoardNumberRowIndex)}
        IPAddressRowIndex {validateRowIndex(IPAddressRowIndex)}
        DeviceIDRowIndex {validateRowIndex(DeviceIDRowIndex)}
        PortRowIndex {validateRowIndex(PortRowIndex)}
        GenerateResourceRowIndex {validateRowIndex(GenerateResourceRowIndex)}
        ResourceNameRowIndex {validateRowIndex(ResourceNameRowIndex)}

        GenerateResourceFcnHandle function_handle = function_handle.empty
    end
end

function validateRowIndex(value)
arguments
    value
end

mustBeNumeric(value)

if isempty(value)
    return
end

mustBeScalarOrEmpty(value);
mustBeFinite(value);
mustBeGreaterThan(value, 0);
end

