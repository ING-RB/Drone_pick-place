classdef (Hidden) ValidationLocation
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % ValidationLocation - Location of validation

    % Copyright 2022-2023 The MathWorks, Inc.

    properties
        % Name - Name of location
        Name (1,1) string

        % Type - Type of location
        Type (1,1) matlab.buildtool.validations.ValidationLocationType
    end

    methods (Hidden)
        function location = ValidationLocation(name, type)
            location.Name = name;
            location.Type = type;
        end
    end
end
