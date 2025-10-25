classdef (Abstract) FontProperties < matlab.hwmgr.internal.hwsetup.WidgetPeer
    % matlab.hwmgr.internal.hwsetup.mixin.FontProperties is a class that
    % defines an interface for the Font properties -
    %1. FontWeight
    %2. FontSize
    %3. FontColor
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    properties(Access = {?matlab.hwmgr.internal.hwsetup.TemplateBase,...
            ?matlab.hwmgr.internal.hwsetup.util.TemplateLayoutManager,...
            ?matlab.hwmgr.internal.hwsetup.Widget}, Dependent)
        % Size of the font in points.
        FontSize
        % FontWeight -- font weight ('normal', 'bold')
        FontWeight
        % FontColor -- Color of the text specified as a RGB triplet
        FontColor
    end
    
    properties(GetAccess = public, SetAccess = protected)
        % Inherited Properties
        % Peer
    end
    
    methods
        function fontSize = get.FontSize(obj)
            fontSize = obj.Peer.FontSize;
        end
        
        function fontWeight = get.FontWeight(obj)
            fontWeight = obj.Peer.FontWeight;
        end
        
        function fontColor = get.FontColor(obj)
            if isprop(obj.Peer, 'FontColor')
                fontColor = obj.Peer.FontColor;
            else
                fontColor = obj.Peer.ForegroundColor;
            end
        end
        
        function set.FontSize(obj, fontSize)
            validateattributes(fontSize,{'numeric'}, {'real', 'nonnegative', 'scalar',...
                'integer'});
            obj.Peer.FontSize = fontSize;
        end
        
        function set.FontWeight(obj, fontWeight)
            value = validatestring(fontWeight, {'normal', 'bold'});
            obj.Peer.FontWeight = value;
        end
        
        function set.FontColor(obj, fontColor)
            if isa(fontColor, 'char') && startsWith(fontColor, '--')
                % If input is a semantic variable, apply the theme color
                if isprop(obj.Peer, 'FontColor')
                    matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.Peer,'FontColor',fontColor);
                else
                    matlab.hwmgr.internal.hwsetup.util.Color.applyThemeColor(obj.Peer,'ForegroundColor',fontColor);
                end
            else
                validateattributes(fontColor, {'numeric'},...
                    {'size',[1,3], '>=', 0, '<=', 1});
                if isprop(obj.Peer, 'FontColor')
                    obj.Peer.FontColor = fontColor;
                else
                    obj.Peer.ForegroundColor = fontColor;
                end
            end
        end
    end
end