classdef TpDownloadTable < matlab.hwmgr.internal.hwsetup.TpDownloadTable
    %matlab.hwmgr.internal.hwsetup.appdesigner.TpDownloadTable is a class that
    %implements TpDownloadTable widget. It renders three text areas for display.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also matlab.hwmgr.internal.hwsetup.TpDownloadTable
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            %createWidgetPeer creates a UI Component peer for DeviceInfoTable
            %widget.
            
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {});
            
            aPeer = matlab.hwmgr.internal.hwsetup.appdesigner.TpDownloadTableWrapper(aParent);
            aPeer.formatTextForDisplay();
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = TpDownloadTable(varargin)
            %TpDownloadTable- constructor
            
            obj@matlab.hwmgr.internal.hwsetup.TpDownloadTable(varargin{:});
            
            %this listener will invoke the destructor of the
            %DeviceInfoTable when it's parent is destroyed
            addlistener(obj.Parent,...
                'ObjectBeingDestroyed', @obj.parentDeleteCallback);
        end
    end
    
    methods
        function setEnable(obj, value)
            obj.Peer.Enable = value;
        end
        
        function value = getEnable(obj)
            %setEnable - return enabled state of DeviceInfoTable
            
            value = obj.Peer.Enable;
        end
    end
    
    
    methods(Access = protected)
        function setName(obj, names)
            %setLabels - set new names to the table column 1.
            
            obj.Peer.Name = names;
        end
        
        function setVersion(obj, versions)
            %setVersion - set new versions to the table column 2.
            
            obj.Peer.Version = versions;
        end
        
        function setDetails(obj, details)
            %setDetails - set new details to the table column 3.
            
            obj.Peer.Details = details;
        end
        
        function setColumnName(obj, names)
            %setColumnName - set new column names to the table row 1. 
            
            obj.Peer.ColumnName = names;
        end
        
        function setBorder(obj, value)
            %setBorder- set border on peer.
            
            obj.Peer.Border = value;
        end
        
        function setTextAlignment(obj, value)
            %setTextAlignment- set specified text alignment to each cell.
            
            obj.Peer.TextAlignment = value;
        end
        
        function value = getBorder(obj)
            %getBorder- get border on peer.
            
            value = obj.Peer.Border;
        end
        
        function alignment = getTextAlignment(obj)
            %getTextAlignment- get text alignment of each cell.
            
            alignment = obj.Peer.TextAlignment;
        end
        
        function names = getName(obj)
            %getName- get list of names set by user.
            
            names = obj.Peer.Name;
        end
        
        function versions = getVersion(obj)
            %getVersion- get list of versions set by user.
            
            versions = obj.Peer.Version;
        end
        
        function value = getDetails(obj)
            %getDetails- get list of details set by user.
            
            value = obj.Peer.Details;
        end
        
        function names = getColumnName(obj)
            %getColumnName- get list of column headers
            
            names = obj.Peer.ColumnName;
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