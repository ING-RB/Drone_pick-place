classdef Version2Loader < appdesigner.internal.serialization.loader.interface.Loader
    %VERSION2LOADER  A class to load apps in the new format (18a and beyond)
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties
        AppData
    end
    
    methods
        
        function obj = Version2Loader(appData)
            % constructor
            obj.AppData = appData;
        end
        
        function appData = load(obj)
            % read the App Designer data
            appData = obj.AppData;
        end     
    end
end

