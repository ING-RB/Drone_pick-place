classdef MLUnsupportedDataModel < internal.matlab.variableeditor.DataModel & internal.matlab.variableeditor.MLNamedVariableObserver
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %MLUnsupportedDataModel 
    %   Abstract Unkown Data Model

    % Copyright 2013-2021 The MathWorks, Inc.

    properties
        Data;
    end
    
    properties (Constant)
        % Type Property
        Type = 'Unsupported';
        
        % Class Type Property
        ClassType = 'unsupported';
        
        % List of data types that should show in the unsupported view.  This is
        % here because some of these may also pass other checks (like isnumeric,
        % for example), but we want in the unsupported view instead.
        ForceUnsupported = {'tall' 'timerange' 'gpuArray' 'distributed' 'codistributed' 'dlarray'};
    end
    
    methods(Access='public')
        % Constructor
        function this = MLUnsupportedDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLNamedVariableObserver(name, workspace);
            this.Name = name;
        end
        
        % getData
        function varargout = getData(this,varargin)
           varargout{1} = this.Data;
        end

        % getSize
        % return vector size for unsupported view.
        function s = getSize(~)
            s = [1 1];
        end %getSize
        
        % updateData
        function data = updateData(this, varargin)
            data = varargin{1};
            
            %set the new data
            this.Data = data;
            
            eventdata = internal.matlab.datatoolsservices.data.DataChangeEventData;            
            this.notify('DataChange',eventdata);                
        end
        
        %getType
        function type = getType(this)
            type = this.Type;
        end
        
        %getClassType
        function type = getClassType(this)
            type = this.ClassType;
        end
        
        function rhs = getRHS(~, ~)
            rhs='';
        end
        
        function data = variableChanged(this, options)
            arguments
                this
            	options.newData = [];
            	options.newSize = 0;
            	options.newClass = '';
            	options.eventType = internal.matlab.datatoolsservices.WorkspaceEventType.UNDEFINED;
            end

            % updateData only uses the newData from the arguments options
            data = this.updateData(options.newData);
        end
        
        function [I,J]=doCompare(~, ~)
            I = [];
            J = [];
        end

        function lhs=getLHS(varargin)
            lhs = '';
        end
    end
end

