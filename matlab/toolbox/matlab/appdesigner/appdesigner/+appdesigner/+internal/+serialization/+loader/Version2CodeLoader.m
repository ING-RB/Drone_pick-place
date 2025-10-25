classdef Version2CodeLoader < appdesigner.internal.serialization.loader.interface.Loader
    %VERSION2CODELOADER  A class to load apps in the new format (18a and beyond)
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties
        AppCodeData
    end
    
    methods
        
        function obj = Version2CodeLoader(appCodeData)
            % constructor
            obj.AppCodeData = appCodeData;
        end
        
        function appCodeData = load(obj)
            % read the App Designer data
            appCodeData = obj.AppCodeData;
        end     
    end
end

