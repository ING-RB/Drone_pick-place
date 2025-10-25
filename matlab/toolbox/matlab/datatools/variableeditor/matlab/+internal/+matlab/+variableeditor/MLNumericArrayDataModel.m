classdef MLNumericArrayDataModel < internal.matlab.variableeditor.MLArrayDataModel & internal.matlab.variableeditor.NumericArrayDataModel
    %MLNUMERICARRAYDATAMODEL
    %   MATLAB Numeric Array Data Model

    % Copyright 2013-2020 The MathWorks, Inc.
    events        
        TableMetaDataChanged;        
    end

    methods(Access='public')
        % Constructor
        function this = MLNumericArrayDataModel(name, workspace)
            this@internal.matlab.variableeditor.MLArrayDataModel(name, workspace);
        end
    end %methods

    methods(Access='protected')
        % If data has changed, update tableMetaData
        function handleMetaDataUpdate(this, newData, currentData, ~, ~, ~)
            % If the class of newData is different from the class of
            % oldData, update tableMetaData as editability could have
            % changed.            
            if ~strcmp(class(newData), class(currentData))
                metaDataEvent = internal.matlab.datatoolsservices.data.ModelChangeEventData;
                this.notify('TableMetaDataChanged', metaDataEvent);
            end                        
        end
        
        % Compares new data to the current data and returns Rows(I) and
        % Columns(J) of Unmatched Values.  Assumes this.Data and newData
        % are the same size.
        %
        % For example, the following inputs returns [1, 3]:
        % this.Data = [1, 2, 3; 4, 5, 6];
        % newData = [1, 2, pi; 4, 5, 6];
        %
        % While these inputs return [[2;1], [2;3]]:
        % this.Data = [1, 2, 3; 4, 5, 6];
        % newData = [1, 2, pi; 4, NaN, 6];
        function [I,J] = doCompare(this, newData)
            i = isreal(this.Data);
            j = isreal(newData);
            % If the incoming data is changing from real to complex or
            % vice versa, we want to refresh the entire view.
            if (i && ~j) || (j && ~i)
                [I,J] = meshgrid(1:size(newData,1),1:size(newData,2));
            else
                [I,J] = find((abs(this.Data-newData)>0) | ...
                (isnan(this.Data)-isnan(newData)));
            end            
        end
    end
end
