classdef Table < matlab.hwmgr.internal.hwsetup.Table
    % matlab.hwmgr.internal.hwsetup.appdesigner.Table is a class that implements a
    % HW Setup table using uitable.
    %It exposes all of the settable and gettable properties defined by the
    %interface specification
    %
    %See also  matlab.hwmgr.internal.hwsetup.Table
    
    % Copyright 2019-2021 The MathWorks, Inc.
    
    methods(Static)
        function aPeer = createWidgetPeer(aParent)
            validateattributes(aParent, {'matlab.ui.Figure',...
                'matlab.ui.container.Panel', 'matlab.ui.container.GridLayout'}, {}, 'createWidgetPeer', 'aParent');
            
            aPeer = uitable('Parent', aParent,...
                'Visible', 'on',...
                'RowStriping', 'off',...
                'FontSize', matlab.hwmgr.internal.hwsetup.util.Font.getPlatformSpecificFontSize(),...
                'FontWeight', 'normal');       
        end
    end
    
    methods(Access = ?matlab.hwmgr.internal.hwsetup.DerivedWidget)
        function addStyle(obj, style, cellIdx)
             validateattributes(cellIdx, {'numeric'},...
                {'size', [1, 2], '>=', 1})
           obj.Peer.addStyle(style, 'cell', cellIdx); 
        end
    end
    
    methods(Access = protected)
        %set Peer property
        function setData(obj, value)
            obj.Peer.Data = value;
        end
        
        function setColumnWidth(obj, value)
            obj.Peer.ColumnWidth = value;
        end
        
        function setColumnName(obj, value)
            obj.Peer.ColumnName = value;
        end
        
        function setRowName(obj, value)
            obj.Peer.RowName = value;
        end
        
        function setColumnEditable(obj, value)
            obj.Peer.ColumnEditable = value;
        end

        % callbacks
        function setCallback(obj)
            obj.Peer.CellEditCallback = @obj.CellEditCbk;
            obj.Peer.CellSelectionCallback = @obj.CellSelectionCbk;
        end
        
        function CellEditCbk(obj, varargin)
            CellEditData = varargin{2};
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(CellEditData, {'event.PropertyEvent','matlab.ui.eventdata.CellEditData'}, {});
            obj.safeCallbackInvoke(obj.CellEditFcn, CellEditData);
        end
        
        function CellSelectionCbk(obj, varargin)
            CellSelectionData = varargin{2};
            validateattributes(varargin, {'cell'}, {'row', 'ncols', 2});
            validateattributes(CellSelectionData, {'event.PropertyEvent','matlab.ui.eventdata.CellSelectionChangeData'}, {});
            obj.safeCallbackInvoke(obj.CellSelectionFcn, CellSelectionData);
        end
        
        %get Peer property
        function value = getData(obj)
            value = obj.Peer.Data;
        end
        
        function value = getColumnWidth(obj)
            value = obj.Peer.ColumnWidth;
        end
        
        function value = getColumnName(obj)
            value = obj.Peer.ColumnName;
        end
        
        function value = getRowName(obj)
            value = obj.Peer.RowName;
        end
        
        function value = getColumnEditable(obj)
            value = obj.Peer.ColumnEditable;
        end
    end
    
    methods(Access = {?matlab.hwmgr.internal.hwsetup.Widget})
        function obj = Table(varargin)
            obj@matlab.hwmgr.internal.hwsetup.Table(varargin{:});
            addlistener(obj.Peer, 'Data', 'PostSet', @obj.CellEditCbk);
        end
    end
end