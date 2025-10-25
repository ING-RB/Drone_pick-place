classdef IController < handle
    %ICONTROLLER interface contains abstract properties and methods that
    %every Communication Log Controller class needs to implement.

    % Copyright 2021 The MathWorks, Inc.

    properties (Abstract, SetObservable)
        DisplayType
        ClearTable logical
    end
end

