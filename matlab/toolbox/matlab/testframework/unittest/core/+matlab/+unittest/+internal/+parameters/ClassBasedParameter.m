classdef (Hidden, Abstract) ClassBasedParameter
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    methods (Hidden, Static, Abstract)
        % getParameters - Get Parameters for a class.
        %
        %   The getParameters method returns parameter information.
        parameters = getParameters(testClass);
        
        % fromName - Construct a single Parameter given the Name.
        %
        %   The fromName method constructs a scalar Parameter instance
        %   given the Property Name and Name of a parameter.
        parameter = fromName(testClass, propName, name);
    end
end

