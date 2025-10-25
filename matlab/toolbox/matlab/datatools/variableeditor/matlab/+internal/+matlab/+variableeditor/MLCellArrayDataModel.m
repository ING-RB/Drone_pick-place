classdef MLCellArrayDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.CellArrayDataModel
    %MLCellARRAYDATAMODEL
    %   MATLAB Cell Array Data Model

    % Copyright 2014-2025 The MathWorks, Inc.

    methods(Access='public')
        function this = MLCellArrayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
        end
    end
    
    methods(Access='protected')
        % Compare our current data and new data. The return value is the index of the changed element from
        % the output of our cellfun() call.
        function [I,J] = doCompare(this, newData)
            [I,J] = find(cellfun(@(a,b) ~strcmp(class(a), class(b)) || ~isequal(a,b), this.Data, newData));
        end
    end
end
