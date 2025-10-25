classdef (Abstract) IController < handle
    %IController contains abstract methods and properties that all Read
    %Section Controller classes must implement.

    % Copyright 2021 The MathWorks, Inc.

    properties (Abstract, SetObservable)
        TransportData
    end
end