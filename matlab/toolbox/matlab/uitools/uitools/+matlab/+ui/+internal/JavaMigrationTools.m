classdef JavaMigrationTools
    %JAVAMIGRATIONTOOLS utility to toggle java migration warnings
    
    % Copyright 2019-2020 The MathWorks, Inc.
    
    methods (Static)
        function cleanupObj = suppressJavaComponentWarning()
            cleanupObj = suppressWarning('MATLAB:ui:javacomponent:FunctionToBeRemoved');
        end
        
        function [hcomponent, hcontainer] = suppressedJavaComponent(varargin)
            % Temporarily disable the JavaComponent warning.
            % Suppress it specifically here (instead of calling
            % suppressJavaComponentWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:javacomponent:FunctionToBeRemoved');
            suppressWarning('MATLAB:ui:javacomponent:BridgeForWebFigures');
            
            % Call
            [hcomponent, hcontainer] = javacomponent(varargin{:});
        end
        
        function cleanupObj = suppressJavaFrameWarning()
            cleanupObj = suppressWarning('MATLAB:ui:javaframe:PropertyToBeRemoved');
        end
        
        function jf = suppressedJavaFrame(hObj)
            % Temporarily disable the JavaFrame warning
            % Suppress it specifically here (instead of calling
            % suppressJavaFrameWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:javaframe:PropertyToBeRemoved');
            
            % Call JavaFrame on the object: figure or uicontainer
            try
                jf = get(hObj,'JavaFrame');
            catch ME
                jf = [];
            end
        end
        
        function cleanupObj = suppressJavaContainerWarning()
            cleanupObj = suppressWarning('MATLAB:ui:javacontainer:PropertyToBeRemoved');
        end
        
        function jf = suppressedJavaContainer(hObj)
            % Temporarily disable the JavaContainer warning
            % Suppress it specifically here (instead of calling
            % suppressJavaContainerWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:javacontainer:PropertyToBeRemoved');
            
            % Call JavaContainer on the object: uitoolbar, uisplittool etc
            try
                jf = get(hObj,'JavaContainer');
            catch ME
                jf = [];
            end
        end
        
        function cleanupObj = suppressActXControlWarning()
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrol:FunctionToBeRemoved');
        end
        
        function varargout = suppressedActXControl(varargin)
            % Temporarily disable the ActiveX warning
            % Suppress it specifically here (instead of calling
            % suppressActXControlWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrol:FunctionToBeRemoved');
            
            % Call
            [varargout{1:nargout}] = actxcontrol(varargin{:});
        end
        
        function cleanupObj = suppressActXControllistWarning()
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrollist:FunctionToBeRemoved');
        end
        
        function info = suppressedActXControllist(varargin)
            % Temporarily disable the ActiveX warning
            % Suppress it specifically here (instead of calling
            % suppressActXControllistWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrollist:FunctionToBeRemoved');
            
            % Call
            info = actxcontrollist(varargin{:});
        end
        
        function cleanupObj = suppressActXControlselectWarning()
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrolselect:FunctionToBeRemoved');
        end
        
        function varargout = suppressedActXControlselect(varargin)
            % Temporarily disable the ActiveX warning
            % Suppress it specifically here (instead of calling
            % suppressActXControlselectWarning) so that stack level detection
            % works properly.
            cleanupObj = suppressWarning('MATLAB:ui:actxcontrolselect:FunctionToBeRemoved');
            
            % Call
            [varargout{1:nargout}] = actxcontrolselect(varargin{:});
        end
        
    end
end

function c = suppressWarning (id)
c = onCleanup.empty;
s = settings; 
if s.matlab.ui.internal.ForceJavaMigrationWarnings.ActiveValue
    return;
end

% Temporarily disable the warning
w = warning('off',id);
c(1) = onCleanup(@() warning(w));

% Cache and restore last warning
[lastmsg, lastid] = lastwarn;
c(2) = onCleanup(@()lastwarn(lastmsg, lastid));
end
