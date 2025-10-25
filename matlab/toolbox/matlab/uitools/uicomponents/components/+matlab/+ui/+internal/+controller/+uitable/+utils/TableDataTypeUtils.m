classdef TableDataTypeUtils
    %TABLEDATATYPEUTILS - utility class for operations performed on Data of
    %type "table". These methods are directly invoked from the C++ model.

    % Copyright 2021 The MathWorks, Inc.

    methods (Static)
       % update UITable ColumnName to Table's VariableNames. This
       % function is called from the model when Data is set. The model
       % makes sure that the Data is of type "table" and "ColumnNameMode" is
       % "auto"
       function updateTableColumnName(model)
           data = model.Data;
           % update ColumnName_I property without changing its mode.
           names = data.Properties.VariableNames;
           if isempty(names)
               model.ColumnName_I = {};
           else
               model.ColumnName_I = names;
           end
       end

       % update UITable RowName to Table's RowNames. This
       % function is called from the model when Data is set. The model
       % makes sure that the Data is of type "table" and "RowNameMode" is
       % "auto"
       function updateTableRowName(model)
           data = model.Data;
           % update RowName_I property without changing its mode.
           model.RowName_I = data.Properties.RowNames;
       end
    end
end