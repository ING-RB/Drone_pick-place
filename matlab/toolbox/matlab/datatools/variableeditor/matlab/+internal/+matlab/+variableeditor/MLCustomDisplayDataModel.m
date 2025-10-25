classdef MLCustomDisplayDataModel < internal.matlab.variableeditor.DataModel & internal.matlab.variableeditor.NamedVariable & internal.matlab.variableeditor.MLNamedVariableObserver
    
    %  MATLAB Custom Object Display Variable Editor DataModel

    % Copyright 2022 The MathWorks, Inc.

    properties
        Data;
        CutomDisplayObj;
    end
    
    properties (Constant)
        % Type Property
        Type = 'CustomDisplay';
        
        % Class Type Property
        ClassType = 'CustomDisplay';
    end
    
    methods(Access='public')
        % Constructor
        function this = MLCustomDisplayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLNamedVariableObserver(name, workspace);
            this.Name = name;
        end
        
        function displayClass = getRichDisplayForClass(~)
            % This method should query some map of the custom display
            % objects to their rich views made in component containers
            displayClass = 'CustomViewDemo';
        end
        
        function embedCustomDisplay(this, parent)
            % This method embeds the users Custom View (present in the
            % VECustomView folder in the preferance dir), inside of the
            % uifigure so that it can be placed in a JS window using a
            % divfigure.
            path = fullfile(prefdir, 'VECustomViews');
            addpath(path);

            % This API returns the appropriate custom view for the datatype
            displayClass = this.getRichDisplayForClass();
            constructor = str2func(displayClass);
            g = uigridlayout(parent, [1,1], 'BackgroundColor', [1 1 1]);
            this.CutomDisplayObj = constructor('Parent', g);
        end
        
        % getData
        function varargout = getData(this,varargin)
           varargout{1} = this.Data;
        end

        % getSize
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
        
        function data = variableChanged(this, varargin)
            data = this.updateData(varargin{:});
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

