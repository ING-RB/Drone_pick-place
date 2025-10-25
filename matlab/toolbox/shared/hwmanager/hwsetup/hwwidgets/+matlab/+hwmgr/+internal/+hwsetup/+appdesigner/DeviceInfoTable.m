classdef DeviceInfoTable < matlab.hwmgr.internal.hwsetup.DeviceInfoTable
    %matlab.hwmgr.internal.hwsetup.appdesigner.DeviceInfoTable is a class that
    %implements DeviceInfoTable widget. It renders three text areas for display.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.DeviceInfoTable
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for DeviceInfoTable
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.DeviceInfoTableWrapper(aParent);
            aPeer.formatTextForDisplay();
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = DeviceInfoTable(varargin)
            %DeviceInfoTable- constructor
            
            obj@matlab.hwmgr.internal.hwsetup.DeviceInfoTable(varargin{:});
                        
            %this listener will invoke the destructor of the
            %DeviceInfoTable when it's parent is destroyed
            addlistener(obj.Parent,...
                'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
    end
    
    methods
        function setEnable(obj, value)
            %setEnable- enable DeviceInfoTable.
            
            obj.Peer.Enable = value;
        end
        
        function value = getEnable(obj)
            %setEnable - return enabled state of DeviceInfoTable
            
            value = obj.Peer.Enable;
        end
    end
    
    methods(Access = protected)
        function setLabels(obj, labels)
            %setLabels - set new label values on peer
            
            obj.Peer.Labels = labels;
        end
        
        function setValues(obj, values)
            %setValues - set new values on peer
            
            obj.Peer.Values = values;
        end

        function labels = getLabels(obj)
            %getLabels- get set of labels in table.
            
            labels = obj.Peer.Labels;
        end
        
        function values = getValues(obj)
            %getValues- get set of values in table.
            
            values = obj.Peer.Values;
        end
        
        function parentDeleteCallback(obj, varargin)
            %parentDeleteCallback - delete DeviceInfoTable when its parent is
            %destroyed.
            
            if isvalid(obj)
                delete(obj);
            end
        end
    end
end