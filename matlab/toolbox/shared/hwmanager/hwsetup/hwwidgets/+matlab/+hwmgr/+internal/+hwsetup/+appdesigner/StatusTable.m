classdef StatusTable < matlab.hwmgr.internal.hwsetup.StatusTable
    %matlab.hwmgr.internal.hwsetup.appdesigner.StatusTable is a class that
    %implements StatusTable widget. It renders three text areas for display.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.StatusTable
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for DeviceInfoTable
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.StatusTableWrapper(aParent);
            aPeer.formatTextForDisplay();
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = StatusTable(varargin)
            %StatusTable- constructor
            
            obj@matlab.hwmgr.internal.hwsetup.StatusTable(varargin{:});
            
            %this listener will invoke the destructor of the
            %DeviceInfoTable when it's parent is destroyed
            addlistener(obj.Parent,...
                'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
    end
    
    
    methods(Access = protected)
        %setters
        function setEnable(obj, value)
            obj.Peer.Enable = value;
        end
        
        function setStatus(obj, status)
            obj.Peer.Status = status;
        end
        
        function setSteps(obj, steps)
            obj.Peer.Steps = steps;
        end
        
        function setBorder(obj, border)
            obj.Peer.Border = border;
        end
        
        %getters
        function value = getEnable(obj)
            value = obj.Peer.Enable;
        end
        
        function status = getStatus(obj)
            status = obj.Peer.Status;
        end
        
        function steps = getSteps(obj)
            steps = obj.Peer.Steps;
        end
        
        function border = getBorder(obj)
            border = obj.Peer.Border;
        end
        
        %other methods
        function out = isIconStr(~, str)
            %isIconStr- check if the string entered is an icon string.
            
            out = ~isempty(regexp(str, '<img src=".+" style="height:16px; width:16px;"/>', 'once'));
        end
        
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete StatusTable when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
end