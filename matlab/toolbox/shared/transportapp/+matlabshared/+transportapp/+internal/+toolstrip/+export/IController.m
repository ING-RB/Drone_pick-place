classdef IController < handle
    %ICONTROLLER interface provides abstract properties and methods for the
    %export section Controller class to implement.

    % Copyright 2021-2023 The MathWorks, Inc.

    methods (Abstract)
        setTransportName(obj, transportName);
    end
end