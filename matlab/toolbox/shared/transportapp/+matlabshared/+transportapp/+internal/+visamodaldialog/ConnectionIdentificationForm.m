classdef ConnectionIdentificationForm
    %CONNECTIONIDENTIFICATIONFORM contains VISA Connection related fields -
    %ResourceName, Model, Vendor, Type, Identification string used,
    %Identification response received, and Error.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        ResourceName (1, 1) string
        Model (1, 1) string
        Vendor (1, 1) string
        Type (1, 1) string
        Identification (1, 1) string
        IdentificationResponse (1, 1) string
        Error
    end
end