classdef (Abstract) Saveable
    % Defines interface for classes that are saved as structs and
    % loaded from structs.
    
    % Copyright 2020 The MathWorks, Inc.
    methods (Abstract, Access = protected)
        s = saveToStruct(obj)
        obj = loadFromStruct(obj, s)
    end
end
