classdef MLMxNArrayDataModel < ...
        internal.matlab.variableeditor.MLArrayDataModel & ...
        internal.matlab.variableeditor.MxNArrayDataModel
    %MLMxNArrayDataModel
    % MATLAB MxN Array Data Model

    % Copyright 2015-2023 The MathWorks, Inc.

    methods
        % Constructor
        function this = MLMxNArrayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(...
                name, workspace);
        end
    end
    
    methods (Access = protected)
        function [I,J] = doCompare(this, newData)
            [I,J] = find(arrayfun(@(a,b) ~isequal(a,b), ...
                this.Data, newData));
        end
    end
end
