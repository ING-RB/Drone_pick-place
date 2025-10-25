classdef Panel <  matlab.hwmgr.internal.hwsetup.Panel
    % matlab.hwmgr.internal.hwsetup.appdesigner.Panel is a class that implements a
    % HW Setup panel using uipanel.
    
    % Copyright 2019-2022 The MathWorks, Inc.
    
    properties(Access = public, Dependent)
        % Inherited Properties
        % Visible
        % Enable
        % Tag
        % Position
        % Title
        % TitlePosition
    end
    
    properties(SetAccess = private, GetAccess = protected)
        % Inherited Properties
        % Parent
    end
    
    properties(GetAccess = protected, SetAccess = protected)
        % Inherited Properties
        % Peer
    end
    
    properties(Access = private)
        %BorderTypeInput- since we translate unsupported values like 
        %'etchedin' to maintain compatibility, we need to keep track of
        %user set values. Remove once g2253923 is addressed.
        BorderTypeInput
    end
    
    methods(Static)
        function aPeer = createWidgetPeer(parent)
            validateattributes(parent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            aPeer = uipanel('Parent', parent,...
                'Visible', 'on', 'AutoResizeChildren', 'off');
        end
    end

    methods
        function position = getPosition(obj)
            position = getPosition@matlab.hwmgr.internal.hwsetup.WidgetBase(obj);
            
            %TODO: Remove once all downstream teams transition to grid
            %layout. This is currently needed since teams are positioning
            %widgets wrt to ContentPanel position.
            if contains(obj.Tag, 'ContentPanel')
                 position = [0 50 470 390];
            end
        end
    end
    
    methods(Access = protected)
        function type = getBorderType(obj)
            %getBorderType- get border type set by user.
            
            type = obj.BorderTypeInput;
        end
        
        function setBorderType(obj, borderType)
            %setBorderType- validate and set border type.
            
            validBorderType = validatestring(borderType, {'etchedin', 'line', 'none'});
            %etchedin bordertype is not supported by uipanel. Replace it
            %with line to maintain compatibility.
            obj.BorderTypeInput = borderType;
            validBorderType = strrep(validBorderType, 'etchedin', 'line');
            set(obj.Peer, 'BorderType', validBorderType);
        end
        
        function setTitlePosition(obj, titlePos)
            validTitlePos = validatestring(titlePos, {'lefttop', 'centertop', 'righttop'});
            set(obj.Peer, 'TitlePosition', validTitlePos);
        end
    end
end
% LocalWords:  hwmgr hwsetup
