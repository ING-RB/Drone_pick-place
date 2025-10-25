classdef SliderModel < handle
    %This class is for internal use only. It may be removed in the future.
    
    %SLIDERMODEL Model portion of the slider in MVC design pattern. 
    %   This model might be hooked up with different Views.

    %   Copyright 2018-2020 The MathWorks, Inc.
    
    properties (SetAccess = protected, SetObservable)
        %MaxValue
        MaxValue
        
        %MaxAllowedValue
        MaxAllowedValue
        
        %MinValue
        MinValue

        %CurrentValue
        CurrentValue
        
        %SyncStartValue
        SyncStartValue
    end
    
    
    events
        %SliderModel_MinMaxReset
        SliderModel_MinMaxReset
        
        %SliderModel_MaxAllowedValueUpdated
        SliderModel_MaxAllowedValueUpdated
        
        %SliderModel_CurrentValueUpdated
        SliderModel_CurrentValueUpdated
        
        %SliderModel_SyncStartValueUpdated
        SliderModel_SyncStartValueUpdated
    end
    
    methods
        function obj = SliderModel()
            %SliderModel Constructor
            obj.MaxValue = 100;
            obj.MinValue = 1;
            obj.CurrentValue = 1;
            obj.MaxAllowedValue = 100;
            obj.SyncStartValue = 100;
        end
        
        function resetMinMaxValue(obj, minVal, maxVal)
            %resetMinMaxValue Reset the min and max values on the slider
            %   This will reset other properties as well.
            
            maxValRounded = round(maxVal);
            minValRounded = round(minVal);
            assert( maxValRounded >= minValRounded);
            
            obj.MaxValue = maxValRounded;
            obj.MinValue = minValRounded;
            obj.MaxAllowedValue = obj.MaxValue;
            obj.SyncStartValue = obj.MaxValue;
            obj.updateCurrentValue(obj.MinValue);
            
            obj.notify('SliderModel_MinMaxReset');
        end
        
        function updateCurrentValue(obj, currVal)
            %updateCurrentValue
            import robotics.appscore.internal.eventdata.*

            if ~isnan(currVal)
                v = round(currVal);
                if v < obj.MinValue
                    v = obj.MinValue;
                end
                if v > obj.MaxAllowedValue
                    v = obj.MaxAllowedValue;
                end
                obj.CurrentValue = v;
            else
                v = obj.CurrentValue;
            end
            
            obj.notify('SliderModel_CurrentValueUpdated', VectorEventData(v));
        end
        
        function updateMaxAllowedValue(obj, maxAllowedVal)
            %updateMaxAllowedValue
            v = round(maxAllowedVal);
            
            if v < obj.MinValue
                v = obj.MinValue;
            end
            
            if v > obj.MaxValue
                v = obj.MaxValue;
            end
            
            obj.MaxAllowedValue = v;
            obj.updateCurrentValue(obj.MinValue); % to make sure current value is consistent
            
            if obj.SyncStartValue > obj.MaxAllowedValue % SyncStartValue should be always NO greater than max allowed value
                obj.SyncStartValue = obj.MaxAllowedValue;
            end
            
            obj.notify('SliderModel_MaxAllowedValueUpdated');
        end
        
        function updateSyncStartValue(obj, syncStartVal)
            %updateSyncStartValue
            v = round(syncStartVal);
            
            if v < obj.MinValue
                v = obj.MinValue;
            end
            
            if v > obj.MaxAllowedValue
                v = obj.MaxAllowedValue;
            end
            obj.SyncStartValue = v;
            
            obj.notify('SliderModel_SyncStartValueUpdated');
            
        end
        
        function data = report(obj)
            %report Report current state of the slider
            data.MaxValue = obj.MaxValue;
            data.MinValue = obj.MinValue;
            data.CurrentValue = obj.CurrentValue;
            data.MaxAllowedValue = obj.MaxAllowedValue;
            data.SyncStartValue = obj.SyncStartValue;
        end
        
        function reinstate(obj, data)
            %reinstate Reinstate slider from data
            obj.resetMinMaxValue(obj.MinValue, data.MaxValue);
            obj.updateSyncStartValue(data.SyncStartValue);
            obj.updateMaxAllowedValue(data.MaxAllowedValue);
            obj.updateCurrentValue(data.CurrentValue);
        end
        
    end
end

