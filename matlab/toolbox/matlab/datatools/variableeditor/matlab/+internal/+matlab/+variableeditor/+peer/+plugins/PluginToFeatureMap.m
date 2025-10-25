classdef PluginToFeatureMap < handle
    %PLUGINTOFEATUREMAP     
    % This class holds a featureMap with a list of all the plugins
    % available for the view.
    
    % Copyright 2019 The MathWorks, Inc.
    properties 
        pluginToFeatureMap struct;
    end
    
    methods (Access=protected)
        function this = PluginToFeatureMap()            
            this.pluginToFeatureMap = struct( ...
                'SERVER_CUSTOM_WIDTHS' , 'internal.matlab.variableeditor.peer.plugins.CustomWidthsPlugin', ...
                'PLAIN_TEXT_SERVER_CUSTOM_WIDTHS' , 'internal.matlab.variableeditor.peer.plugins.PlainTextCustomWidthsPlugin', ...
                'SERVER_STRING_DISPLAY' , 'internal.matlab.variableeditor.peer.plugins.StringDisplayPlugin', ...
                'SERVER_JS_SPARKLINES' , 'internal.matlab.variableeditor.peer.plugins.JSSparkLinePlugin', ...
                'VEINTERACTION_HANDLER', 'internal.matlab.variableeditor.peer.plugins.VEInteractionHandler', ...
                'BACKGROUND_COLOR_PLUGIN', 'internal.matlab.variableeditor.peer.plugins.BackgroundColorPlugin' ...
            );
        end
    end
    
    methods (Static)
        function obj = getInstance
            mlock; % Keep persistent variables until MATLAB exits
            persistent featureMapInstance;
            if isempty(featureMapInstance)
                featureMapInstance = internal.matlab.variableeditor.peer.plugins.PluginToFeatureMap();
            end
            obj = featureMapInstance;
        end
        
        % This method returns a plugin class name for a provided
        % 'featureName'.
        function pluginClass = GetPluginsForFeature(featureName)           
            pluginClass = [];
            featureMapInstance = internal.matlab.variableeditor.peer.plugins.PluginToFeatureMap.getInstance;
            if (isfield(featureMapInstance.pluginToFeatureMap, featureName))
                pluginClass = featureMapInstance.pluginToFeatureMap.(featureName);            
            end            
        end        
        
    end
end

