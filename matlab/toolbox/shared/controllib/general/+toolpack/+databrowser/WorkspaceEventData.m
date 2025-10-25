classdef (ConstructOnLoad) WorkspaceEventData < event.EventData
    % Event data associated with workspace updates.
    
    %   Author(s): Murad Abu-Khalaf , December 17, 2010
    %   Revised:
    %   Copyright 2010-2011 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Dependent, GetAccess = public, SetAccess = public)
        % Workspace change flag indicating that a workspace variable is
        % added or re-assigned
        WSChange
        
        % Workspace deletion flag indicating the deletion of a workspace
        % variable(s)
        WSDelete
        
        % This flag indicates that the workspace was cleared
        WSClear
        
        % This flag indicates whether the workspace update had a rename
        WSRename        
    end
    
    properties (Access = protected)
        % Version
        Version = toolpack.ver();
    end
    
    properties (Access = private)
        Flags
        RenameData
    end
    
    % ----------------------------------------------------------------------------
    methods
        function this = WorkspaceEventData(varargin)
            % Creates an event data object describing the workspace update.
            %
            % Example: obj = toolpack.WorkspaceEventData(true,true,false)            
            if nargin == 0
                S.CHANGE = false;
                S.DELETE = false;
                S.CLEAR = false;
                S.RENAME = false;
                this.Flags = S;
                this.setRenameData('','');
            else
                if nargin == 4
                    this.WSChange = varargin{1};
                    this.WSDelete = varargin{2};
                    this.WSClear  = varargin{3};
                    this.WSRename = varargin{4};
                else
                    %error('Must specify all flags')
                end
            end
            
        end
    end
    
    % ----------------------------------------------------------------------------
    methods
        function value = get.WSChange(this)
            % GET function for WSChange property.
            value = this.Flags.CHANGE;
        end
        
        function set.WSChange(this, value)
            % SET function for WSChange property.
            if islogical(value)
                this.Flags.CHANGE = value;
            else
                ctrlMsgUtils.error('Controllib:databrowser:MustBeLogicalFlag');                
            end
        end
        
        function value = get.WSDelete(this)
            % GET function for WSChange property.
            value = this.Flags.DELETE;
        end
        
        function set.WSDelete(this, value)
            % SET function for WSChange property.
            if islogical(value)
                this.Flags.DELETE = value;
            else
                ctrlMsgUtils.error('Controllib:databrowser:MustBeLogicalFlag');
            end
        end
        
        function value = get.WSClear(this)
            % GET function for WSChange property.
            value = this.Flags.CLEAR;
        end
        
        function set.WSClear(this, value)
            % SET function for WSChange property.
            if islogical(value)
                this.Flags.CLEAR = value;
            else
                ctrlMsgUtils.error('Controllib:databrowser:MustBeLogicalFlag');
            end
        end
        
        function value = get.WSRename(this)
            % GET function for WSRename property.
            value = this.Flags.RENAME;
        end
        
        function set.WSRename(this, value)
            % SET function for WSRename property.
            if islogical(value)
                this.Flags.RENAME = value;
                if ~value
                    setRenameData(this,'','');
                end
            else
                ctrlMsgUtils.error('Controllib:databrowser:MustBeLogicalFlag');
            end
        end
        
        function setRenameData(this,oldname,newname)
            % Sets the rename data
            this.RenameData.OldName = oldname;
            this.RenameData.NewName = newname;
        end
        
        function [oldname,newname] = getRenameData(this)
            % Gets the rename data
            oldname = this.RenameData.OldName;
            newname = this.RenameData.NewName;
        end
        
        function delete(this) %#ok<MANU>
%             disp('WorkspaceEventData is deleting...');
        end
    end
end