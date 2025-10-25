classdef (Abstract) IController < handle
    %IController contains abstract methods and properties that all Write
    %Section Controller classes must implement.

    % Copyright 2021 The MathWorks, Inc.

    properties (Abstract, SetObservable)
        % Contains information about the write operation to be performed,
        % like the kind of write, the data to be written, and the
        % associated data type value.
        TransportData matlabshared.transportapp.internal.utilities.forms.TransportData
    end
end