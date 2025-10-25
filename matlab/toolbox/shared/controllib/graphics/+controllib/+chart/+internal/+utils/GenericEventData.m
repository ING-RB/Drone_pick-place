classdef GenericEventData < event.EventData & dynamicprops
    % Class used to pass event data during notify

    properties
        Data        % Data that was changed
        Type
    end
    
    methods
        function this = GenericEventData(Data,nameValueArgs)
            arguments
                Data = []
                nameValueArgs.Type string = ""
            end
            this.Data = Data;
            this.Type = nameValueArgs.Type;
        end
    end
    
end