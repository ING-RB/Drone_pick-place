classdef AppOpenedEventData < event.EventData
    
    properties
        AppModel
    end

    methods
        function obj = AppOpenedEventData(appModel)
            obj.AppModel = appModel;
        end
    end
end