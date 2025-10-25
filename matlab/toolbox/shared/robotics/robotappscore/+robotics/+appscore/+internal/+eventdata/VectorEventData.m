classdef (ConstructOnLoad) VectorEventData < event.EventData
    %This class is for internal use only. It may be removed in the future.

    %VectorEventData This class serves all the listeners that look for a 
    %    vector data in the events
    
    %   Copyright 2018 The MathWorks, Inc.

    properties
       Vector
    end
   
    methods
       function data = VectorEventData(vec)
         
           data.Vector = vec;
         
       end
    end
end

