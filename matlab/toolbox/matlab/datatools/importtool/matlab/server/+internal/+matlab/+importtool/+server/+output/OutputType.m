% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Output Data Type from Import.  Concrete
% implementations of this class represent numeric array, string array, etc...
% Note that the functions are for converting from table, because internally
% import uses readtable, so all internal processing is done with readtable.

% Copyright 2018-2023 The MathWorks, Inc.

classdef OutputType < handle
    methods(Abstract)
        % Convert from table to the specific datatype. Returns the converted
        % variable and any new variable names created.  varNames can be empty if
        % the original variable name is used.
        [vars, varNames] = convertFromImportedData(this, tbl);
        
        % Generate the code string which will be used to convert from table to a
        % specific datatype.  Returns the code, and any variables that need to
        % be cleared.
        [code, varsToClear] = getCodeToConvertFromImportedData(this, varName, imopts);
        
        % Return the function header line that indicates the type of output the
        % function will produce.
        code = getFunctionHeaderCode(this);
        
        % Return the column classes for this output type, given the initial
        % column classes.   Return value columnClasses can be a scalar char
        % or string, which will be applied to every column (for example,
        % every column must be 'double'), or it can be a cell array,
        % matching the same size as the input initialColumnClasses.
        columnClasses = getColumnClasses(this, initialColumnClasses);
        
        % Return the column class options for this output type, given the
        % initial column classes.  Return value columnClassOptions should be the
        % same size as the defaultColClassOptions.
        columnClassOptions = getColumnClassOptions(this, defaultColClassOptions);
        
        % Return the column names for this output type, given the default column
        % names.  The return values will be the same length as the
        % defaultColumnNames argument.
        columnNames = getColumnNames(this, defaultColumnNames);
        
        % Returns the function handle of the function used to perform the
        % import.  Typically this is @readtable, but could also be
        % @readmatrix, @readtimetable, etc...
        fcnHandle = getImportFunction(this);
        
        % Returns the name of the function used to perform the import.
        % Typically this is "readtable", but could also be "readmatrix",
        % "readtimetable", etc...
        fcnHandleName = getImportFunctionName(this);
        
        % Returns true if the output requires some conversion, false if
        % not.  For example, if the output type is table, and readtable is
        % used, no conversion is required.  However, if the output type is
        % cell, then conversion will be needed to go from table to cell.
        b = requiresOutputConversion(this);
        
        % Called to allow the Output Type to make changes to the import options
        % object prior to the read* function being called.
        opts = updateImportOptionsForOutputType(this);
        
        % Called to initialize arguments for the OutputType based on the view
        % model's settings (TableModelProperties, ColumnModelProperties, etc.)
        initOutputArgsFromProperties(this, viewModel);
        
        % Called to get additional arguments for the import function.  Return a
        % cell array, which will be expanded as the args for the function.
        c = getAdditionalArgsForImportFcn(this);
        
        % Called to get additional arguments for the import function for code
        % generation.  Return a string which is properly formatted, which will
        % be appended to the codegen function call.
        s = getAdditionalArgsForCodeGen(this);
        
        % Called to get the output type to initialize variables for codegen,
        % where the code generation happens with multiple calls, and is
        % concatenated together afterwards.  Return a string which is the data
        % type, for example:  "table"
        s = getOutputTypeInitializerForCodeGen(this);

        % Returns true if this is a tabular output type (table or
        % timetable), false if otherwise.
        b = isTabular(this);
    end
    
    properties
        % If true, the last line of code which produces an output will not have
        % a semi-colon on it, so that its output will be displayed when the code
        % is executed.
        showLastOutput logical = false;
    end
end
