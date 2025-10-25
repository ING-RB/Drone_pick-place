classdef Version1CodeLoader < appdesigner.internal.serialization.loader.interface.Loader
    %VERSION1CODELOADER  A class to load older apps (16a-17b)
    
    % Copyright 2021 The MathWorks, Inc.
    
    properties
        AppCodeData
    end
    
    methods
        
        function obj = Version1CodeLoader(appCodeData)
            obj.AppCodeData = appCodeData;
        end
        
        function appCodeData = load(obj)
            % convert the data to the new format
            appCodeData = appdesigner.internal.serialization.loader.util.convertVersion1CodeDataToVersion2(obj.AppCodeData);   
        end
    end
end
