classdef MLAPPValidator < handle
    %MLAPPVALIDATOR MLAPP file data validator
    %   Validate if the data is valid, for example, 
    %   MLAPP type is supported by the current App Designer?
    %   MLAPP file is supported by the current App Designer?
    %   
    %   When validation fails, a validator should throw an error with
    %   proper message, which would be used by the App Designer client side
    %   to inform the user the reason of failure opening.
    
    % Copyright 2018 The MathWorks, Inc.
    
    
    properties(SetAccess = 'private')
        % An array of warning objects
        %
        % Any warnings encountered during deserialization will be stored
        % here
        %
        % Examples when warnings should be thrown:
        %
        % - Licenses unavailable
        % - A component was corrupt and the app maybe shouldn't be used
        % - etc...
        Warnings appdesigner.internal.serialization.validator.MLAPPWarning = ...
        appdesigner.internal.serialization.validator.MLAPPWarning.empty()
    end
    
    methods 
        function validateMetaData(obj, metaData)
            % Check meta data of MLAPP file, for instance, AppType,
            % MinimumSupported MATLAB Release, etc.
            % If checking fails, an error is thrown.
            %
            
            % no-op by default
        end
        
        function validateAppData(obj, metaData, appData)
            % Check AppData of MLAPP file, for instance,
            % If it's a responsive app, check layou type from component
            % (GridLayout) information to determine if it's supported by
            % the current App Designer. If not, an error is thrown.
            %
            
            % no-op
        end
    end
    
    methods(Sealed)
        function addWarning(obj, id, warningInformation)
            % Should be called by subclasses when encountering a warning
            %
            % ID = a unique string ID
            %
            % WarningInformation = a struct of arbitrary information,
            % determined by the validator
            obj.Warnings(end+1) = appdesigner.internal.serialization.validator.MLAPPWarning(id, warningInformation);
        end
    end
end

