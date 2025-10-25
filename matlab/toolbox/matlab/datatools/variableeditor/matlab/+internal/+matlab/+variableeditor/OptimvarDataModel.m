classdef OptimvarDataModel < internal.matlab.variableeditor.ArrayDataModel
    %OPTIMVARDATAMODEL 
    % Optimvar Data Model

    % Copyright 2022 The MathWorks, Inc.

    % Type
    properties (Constant)
        % Type Property
        Type = 'Optimvar';

        % Will be set to the object name when data is set
        ClassType = 'optimvar';
    end

    % Data
    properties (SetObservable = true)
        % Data Property
        Data
    end
    
    methods
        function storedValue = get.Data(this)
            storedValue = this.Data;
        end
        
        function set.Data(this, newValue)
            reallyDoCopy =  ~isequal(this.Data, newValue);
            if reallyDoCopy
                this.Data = newValue;
            end
        end

        % Generates code for setting data on the variable
        function varargout = setData(this,varargin)
            row = varargin{2};
            col = varargin{3};
            newValue = varargin{1};
            code = variableEditorSetDataCode(this.Data, this.Name, row, col, newValue);
            varargout{1} = string(code);
        end
    end

    methods (Access = protected)
        % NOOP , variableEditorSetDataCode is used to generate LHS and RHS
        function lhs = getLHS(~, idx)
            lhs = sprintf('(%s)', idx);
        end
    end
   
end

