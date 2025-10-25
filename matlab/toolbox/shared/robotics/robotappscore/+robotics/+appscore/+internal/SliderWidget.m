classdef SliderWidget < handle
    %This class is for internal use only. It may be removed in the future. 
    
    %SliderWidget This class provides a composite slider widget in a MATLAB
    %   figure

    % Copyright 2018 The MathWorks, Inc.    
    
    properties
        SliderView
        SliderModel
        SliderController
    end
    
    methods
        function obj = SliderWidget(fig, tag)
            %SliderWidget Constructor
            import robotics.appscore.internal.*
            
            obj.SliderView = SliderView(fig, tag);
            obj.SliderModel = SliderModel();
            obj.SliderController = SliderController(obj.SliderModel, obj.SliderView);
            
        end
       
    end
end

