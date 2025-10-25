classdef ResourceStringForm
    %RESOURCESTRINGFORM contains properties for the Generate Resource
    %Section of the modal window. This is used by the dialog classes to
    %generate the resource strings for a specific visa type - VXI-11,
    %Socket, or HiSLIP.

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        IPAddress
        Port
        DeviceID
        BoardNumber
    end
end

