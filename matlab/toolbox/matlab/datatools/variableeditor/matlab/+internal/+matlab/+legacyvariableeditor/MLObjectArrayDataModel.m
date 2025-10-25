classdef MLObjectArrayDataModel < ...
        internal.matlab.legacyvariableeditor.MLArrayDataModel & ...
        internal.matlab.legacyvariableeditor.ObjectArrayDataModel
    %MLOBJECTARRAYDATAMODEL
    % MATLAB Object Array Data Model

    % Copyright 2015 The MathWorks, Inc.

    methods
        % Constructor
        function this = MLObjectArrayDataModel(name, workspace)
            this@internal.matlab.legacyvariableeditor.MLArrayDataModel(...
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
