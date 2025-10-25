classdef (Hidden) StyleableComponentController < handle & ...
        appdesservices.internal.interfaces.controller.AbstractControllerMixin
    
    % StyleableComponentController provides the functionality to 
    % facilitate communicating style information to the view
    
    % Copyright 2021 The MathWorks, Inc.
    
    
    methods(Static)
        function value = getSerializableStyleConfigurationStorage(value)
            % GETSERIALIZABLESTYLECONFIGURATIONSTORAGE - Helper function to
            % assist in storing the style object in a way that is
            % compatible with jsonencode strategy for serialization
            %
            % value - an value object of class
            % matlab.ui.style.internal.StylesMetaData with fields Target,
            % TargetIndex, Style, Dirty, RemovedTarget, RemovedTargetIndex
            
            % Removed information could be tree nodes which are not
            % serializable.  clear this data 
            value.RemovedTarget = [string.empty(0, 0)];
            value.RemovedTargetIndex = {};
            
            % Determine if style object has iconUri information stored
            hasIcon = false;
            ishomogeneous = false;
            for idx = 1 : numel(value.Style)
                if isprop(value.Style(idx), 'IconUri') && ~isempty(value.Style(idx).IconUri)
                    hasIcon = true;
                    ishomogeneous = strcmp(class(value.Style(idx)), class(value.Style));
                    break;
                end
            end

            if hasIcon
                % Reconstruct data as struct in order to preserve the
                % hidden IconUri state.
                origState = warning('off','MATLAB:structOnObject');
                cleanup = onCleanup(@()warning(origState));
                value.Style = arrayfun(@struct, value.Style, 'UniformOutput', ishomogeneous);
            end
        end
    end
    methods
        function handleLinkClicked(obj, url)
            if ~isempty(url)
                try
                    web(url, '-browser')
                catch me
                    % MnemonicField is last section of error id
                    mnemonicField = 'failureToLaunchURL';

                    messageObj = message('MATLAB:ui:components:errorInWeb', ...
                        url, me.message);
                    context = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(obj.Model);
                    warning(['MATLAB:ui:', context, ':', mnemonicField], messageObj.getString())
                end

            else
                %Invalid web url
                mnemonicField = 'failureToLaunchWebURL';
                messageObj = message('MATLAB:ui:components:errorInWebEmpty');
                context = matlab.ui.control.internal.model.PropertyHandling.getComponentClassName(obj.Model);
                warning(['MATLAB:ui:', context, ':', mnemonicField], messageObj.getString());
            end
        end

    end
end


