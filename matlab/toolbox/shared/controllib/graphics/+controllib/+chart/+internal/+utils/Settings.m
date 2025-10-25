classdef (Sealed) Settings < handle
%   Store and access settings for Controls Charts development

%   Copyright 2021 The MathWorks, Inc.

    properties
        CreateDataTipsMode string ...
            {mustBeMember(CreateDataTipsMode,["ResponseCreation","ResponseClick","None"])}...
            = "None"
        AxesInteractionMode string ...
            {mustBeMember(AxesInteractionMode,["Default","Basic","None"])}...
            = "Default"
        AxesToolbarMode string ...
            {mustBeMember(AxesToolbarMode,["Default","Basic","None","OnHover"])}...
            = "Default"
    end

    methods (Access = private)
        function obj = Settings
        end
    end
    
    methods (Static)
        function singleObj = getInstance
            mlock
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = controllib.chart.internal.utils.Settings;
            end
            singleObj = localObj;
        end
        
        %% CreateDataTipsMode
        function setCreateDataTipsMode(Value)
            obj = controllib.chart.internal.utils.Settings.getInstance;
            obj.CreateDataTipsMode = Value;
        end
        
        function Value = getCreateDataTipsMode()
            obj = controllib.chart.internal.utils.Settings.getInstance;
            Value = obj.CreateDataTipsMode;
        end
        
        %% AxesInteractionMode
        function setAxesInteractionMode(Value)
            obj = controllib.chart.internal.utils.Settings.getInstance;
            obj.AxesInteractionMode = Value;
        end
        
        function Value = getAxesInteractionMode()
            obj = controllib.chart.internal.utils.Settings.getInstance;
            Value = obj.AxesInteractionMode;
        end

        %% AxesToolbarMode
        function setAxesToolbarMode(Value)
            obj = controllib.chart.internal.utils.Settings.getInstance;
            obj.AxesToolbarMode = Value;
        end
        
        function Value = getAxesToolbarMode()
            obj = controllib.chart.internal.utils.Settings.getInstance;
            Value = obj.AxesToolbarMode;
        end
    end
end

