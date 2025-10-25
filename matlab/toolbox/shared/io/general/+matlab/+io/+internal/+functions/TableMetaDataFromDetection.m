classdef TableMetaDataFromDetection < matlab.io.internal.shared.ReadTableInputs
%

% Copyright 2018 The MathWorks, Inc.
    properties 
        DetectMetaLines = true;
    end 
    
    methods
        function meta = setMetaLocations(obj, supplied, metarows)
            if ~obj.DetectMetaLines
                metarows = 0;
            end
            meta.DataRow = 1;
            meta.VariableNamesRow = 0;
            meta.RowNamesCol = 0;

            meta.RowNames = supplied.ReadRowNames && obj.ReadRowNames;
            if meta.RowNames
                meta.RowNamesCol = 1;
            end
            meta.VarNames = (supplied.ReadVariableNames && obj.ReadVariableNames)...
                || (~supplied.ReadVariableNames && metarows > 0);
            if meta.VarNames
                meta.DataRow = metarows + 1;
                meta.VariableNamesRow = 1;
            end

        end
    end
end

