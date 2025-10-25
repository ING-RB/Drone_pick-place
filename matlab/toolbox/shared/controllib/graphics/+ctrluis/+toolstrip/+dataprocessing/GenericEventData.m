classdef GenericEventData < event.EventData
    %
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = 'public', SetAccess = 'private')
        Data %Event data
    end
    
    methods(Access = public)
        function obj = GenericEventData(data)
            %GENERICEVENTDATA Construct GenericEventData object
            %
            
            %Call superclass constructor
            obj = obj@event.EventData;
            
            %Set data property
            obj.Data = data;
        end
    end
end