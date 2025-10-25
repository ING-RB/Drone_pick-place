classdef (ConstructOnLoad) SliderScrubberEventData < event.EventData
    %This class is for internal use only. It may be removed in the future.

    %SliderScrubberEventData This class encapsulates data needed for
    %   SliderView_ScrubberDragged event listeners.

    %   Copyright 2018 The MathWorks, Inc.

    properties
       Pixels
    end
   
    methods
       function data = SliderScrubberEventData(px)
         
           data.Pixels = px;
         
       end
    end
end

