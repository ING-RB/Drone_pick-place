classdef ReleaseCompatibilityException
    % ReleaseCompatibilityException stores information about
    % any exceptions thrown during the execution of 
    % the upgrade process

    %   Copyright 2019 The MathWorks, Inc.

    properties (GetAccess = public, SetAccess = immutable)
        % Exception message
        ExceptionString (1,1) string
        % Exception ID
        ExceptionID (1,1) string
    end
    properties (Hidden,SetAccess = immutable)
        % Inputs required to build the exception
        Inputs string
    end
    methods
        % Create the exception message using the exception identifier
        % and the input parameters
        function ExceptionString = get.ExceptionString(obj)
            ExceptionString = "";
            if obj.ExceptionID == "MATLAB:settings:config:ErrorAddingProductSettingsGroup" || ...
                obj.ExceptionID == "MATLAB:settings:config:GroupOrSettingNameAlreadyExists"
                ExceptionString = getString(message(obj.ExceptionID, obj.Inputs(1), obj.Inputs(2)));
            elseif obj.ExceptionID == "MATLAB:settings:config:InvalidPersonalSettingsVersion" || ...
                    obj.ExceptionID == "MATLAB:settings:config:FactoryTreeChangesAreEmpty" || ...
                    obj.ExceptionID == "MATLAB:settings:config:PathNotRelativeToMasterFile" || ...
                    obj.ExceptionID == "MATLAB:settings:config:FactoryTreeDoesNotExist"
                ExceptionString = getString(message(obj.ExceptionID, obj.Inputs(1)));
            end
        end
    end
end
