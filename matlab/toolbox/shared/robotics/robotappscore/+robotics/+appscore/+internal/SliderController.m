classdef SliderController < handle
    %This class is for internal use only. It may be removed in the future. 
    
    %SliderController Controller portion of the MVC pattern for slider

    % Copyright 2018-2021 The MathWorks, Inc.
    
    properties
        SliderModel
        SliderView
    end
    
    methods
        function obj = SliderController(model, view)
            %SliderController Constructor
            obj.SliderModel = model;
            obj.SliderView = view;
            
            obj.refreshSliderView
            
            obj.addViewListeners();
            obj.addModelListeners();
        end

    end
    
    
    methods
        function addViewListeners(obj)
            %addViewListeners Add listeners to slider view events
            
            addlistener(obj.SliderView, 'SliderView_RefreshRequested', @(source, event) obj.refreshSliderView );
            addlistener(obj.SliderView, 'SliderView_ScrubberReleased', @(source, event) obj.refreshSliderView );

            addlistener(obj.SliderView, 'SliderView_ScrubberDragged', @(source, event) obj.scrubberDraggedCallback(event));
            addlistener(obj.SliderView, 'SliderView_CurrentValueEditChanged', @(source, event) obj.SliderModel.updateCurrentValue(event.Vector));
            
            addlistener(obj.SliderView, 'SliderView_ForwardStepperClicked', @(source, event) obj.incrementCurrentValue);
            addlistener(obj.SliderView, 'SliderView_BackwardStepperClicked', @(source, event) obj.decrementCurrentValue);
        end
        
    end
    

    methods
        function addModelListeners(obj)
            %addModelListeners Add listeners to slider model events
            
            addlistener(obj.SliderModel, 'SliderModel_MinMaxReset', @(source, event) obj.refreshSliderView);
            addlistener(obj.SliderModel, 'SliderModel_MaxAllowedValueUpdated', @(source, event) obj.refreshSliderView);
            addlistener(obj.SliderModel, 'SliderModel_CurrentValueUpdated', @(source, event) obj.refreshSliderView);
            addlistener(obj.SliderModel, 'SliderModel_SyncStartValueUpdated', @(source, event) obj.refreshSliderView);
            
        end
    end
    
    methods
        % callbacks assembled in controller
        function refreshSliderView(obj)
            %refreshSliderView Refresh slider view when slider model
            %   properties change
            data = obj.SliderModel.report;
            data.MaxAllowedValuePixels = valueToPixels(obj, data.MaxAllowedValue);
            data.SyncStartValuePixels = valueToPixels(obj, data.SyncStartValue);
            data.CurrentValuePixels = valueToPixels(obj, data.CurrentValue);
            obj.SliderView.refresh(data); 
        end
        
        function scrubberDraggedCallback(obj, event)
            %scrubberDraggedCallback
            v = obj.pixelsToValue(event.Pixels);
            obj.SliderModel.updateCurrentValue(v);
        end
        
        function incrementCurrentValue(obj)
            %incrementCurrentValue
            obj.SliderModel.updateCurrentValue(obj.SliderModel.CurrentValue + 1);
            % The above triggers graphics rendering. Keeping this busy
            % till the rendering is complete, to cancel any button clicks
            % while rendering.
            drawnow;
        end
        
        function decrementCurrentValue(obj)
            %decrementCurrentValue
            obj.SliderModel.updateCurrentValue(obj.SliderModel.CurrentValue - 1);
            % The above triggers graphics rendering. Keeping this busy
            % till the rendering is complete, to cancel any button clicks
            % while rendering.
            drawnow;
        end
    end
    
    methods
        
        % value-to-pixels converter
        function pixels = valueToPixels(obj, value) 
            %valueToPixels Convert a numeric value into its corresponding
            %   location w.r.t. the left border of the slider bottom track
            %   in terms of number of pixels. The location on the slider
            %   corresponds to the value depends on the min/max values of
            %   the slider
            if value == 1
                pixels = 0;
                return;
            end
            trackLength = obj.SliderView.BottomTrack.Position(3);
            pixels = round((value-obj.SliderModel.MinValue)/(obj.SliderModel.MaxValue-obj.SliderModel.MinValue)*trackLength);
        end
        
        % pixel-to-value converter
        function value = pixelsToValue(obj, pixels)
            %pixelsToValue Given a location on slider find its
            %   corresponding numeric value
            %
            % Position(1) - left 
            % Position(2) - bottom
            % Position(3) - width
            % Position(4) - height
            trackLength = obj.SliderView.BottomTrack.Position(3);
            value = round(obj.SliderModel.MinValue + (pixels - obj.SliderView.BottomTrack.Position(1))/trackLength * (obj.SliderModel.MaxValue - obj.SliderModel.MinValue));
        end
        
    end
end

