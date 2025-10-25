classdef ElementsAvailableInfo < event.EventData
    % Information associated with the ElementsAvailableInfo

    % Copyright 2018 The MathWorks, Inc.

    properties
        % The number of elements available in the buffer
        NumElementsAvailable (1, 1) double
    end

    methods
        function obj = ElementsAvailableInfo(numElements)
            obj.NumElementsAvailable = numElements;
        end
    end
end