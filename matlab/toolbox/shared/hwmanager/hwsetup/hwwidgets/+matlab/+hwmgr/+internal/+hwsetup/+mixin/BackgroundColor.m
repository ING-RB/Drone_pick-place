classdef (Abstract) BackgroundColor < matlab.hwmgr.internal.hwsetup.WidgetPeer
    % matlab.hwmgr.internal.hwsetup.mixin.BackgroundColor is a class that
    % defines an interface for the Background color property of a widget
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase, ...
            ?matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager,...
            ?matlab.hwmgr.internal.hwsetup.Widget}, Dependent)
        % Help and Navigation Mixin should have access to the color
        % property
        
        %Color - Background Color for a widget specified as 1x3 vector
        % of RGB values, each element between 0 and 1
        Color
    end
    
    properties(GetAccess = public, SetAccess = protected)
        % Inherited Properties
        % Peer
    end
    
    methods
        function set.Color(obj, aColor)
            % Template method to set the Color
            if isa(aColor, 'char') && startsWith(aColor, '--') && (isprop(obj.Peer,'BackgroundColor') || isfield(obj.Peer, 'BackgroundColor'))
                % If input is a semantic variable, apply the theme color
                matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.Peer,'BackgroundColor',aColor);
            else
                if isprop(obj.Peer, 'BackgroundColor') || isfield(obj.Peer, 'BackgroundColor')
                    validateattributes(aColor, {'numeric'}, {'size', [1, 3], '>=', 0, '<=', 1});
                    obj.Peer.BackgroundColor =  aColor;
                    obj.setColor();
                end
            end
        end
        
        function aColor = get.Color(obj)
            aColor = [];
            if isprop(obj.Peer, 'BackgroundColor') || isfield(obj.Peer, 'BackgroundColor')
                aColor = obj.Peer.BackgroundColor;
            end
        end
        
        function setColor(~)
            % Default empty implementation for compound widgets
        end
    end
end