% This class is unsupported and might change or be removed without
% notice in a future version.

% This class is represents an Output Data Type from Import.  Concrete
% implementations of this class represent numeric array, string array, etc...
% Note that the functions are for converting from table, because internally
% import uses readtable, so all internal processing is done with readtable.

% Copyright 2018-2023 The MathWorks, Inc.

classdef OutputTypeAdapter < internal.matlab.importtool.server.output.OutputType
    
    properties(Access = private)
        ColumnNameStrategy;
        ColumnClassStrategy;
        ColumnClassOptionsStrategy;
    end
    
    methods
        function setColumnNameStrategy(this, columnNameStrategy)
            if ~isa(columnNameStrategy, "internal.matlab.importtool.server.output.OutputColumnNameStrategy")
                error("Column Name Strategy must be an OutputColumnNameStrategy");
            end
            this.ColumnNameStrategy = columnNameStrategy;
        end
        
        function setColumnClassStrategy(this, columnClassStrategy)
            if ~isa(columnClassStrategy, "internal.matlab.importtool.server.output.OutputColumnClassStrategy")
                error("Column Class Strategy must be an OutputColumnClassStrategy");
            end
            this.ColumnClassStrategy = columnClassStrategy;
        end
        
        function setColumnClassOptionsStrategy(this, columnClassOptionsStrategy)
            if ~isa(columnClassOptionsStrategy, "internal.matlab.importtool.server.output.OutputColumnClassOptionsStrategy")
                error("Column Class Options Strategy must be an OutputColumnClassOptionsStrategy");
            end
            this.ColumnClassOptionsStrategy = columnClassOptionsStrategy;
        end
        
        % Return the column names for this output type, given the default column
        % names.  The return values will be the same length as the
        % defaultColumnNames argument.
        function columnNames = getColumnNames(this, defaultColumnNames)
            if ~isempty(this.ColumnNameStrategy)
                columnNames = this.ColumnNameStrategy.getColumnNamesForImport(defaultColumnNames);
            else
                columnNames = defaultColumnNames;
            end
        end
        
        % Return the column classes for this output type, given the initial
        % column classes.   Return value columnClasses can be a scalar char
        % or string, which will be applied to every column (for example,
        % every column must be 'double'), or it can be a cell array,
        % matching the same size as the input initialColumnClasses.
        function columnClasses = getColumnClasses(this, initialColumnClasses)
            if ~isempty(this.ColumnClassStrategy)
                columnClasses = this.ColumnClassStrategy.getColumnClassesForImport(initialColumnClasses);
            else
                columnClasses = initialColumnClasses;
            end
        end
        
        % Return the column class options for this output type, given the
        % initial column classes.  Return value columnClassOptions should be the
        % same size as the defaultColClassOptions.
        function columnClassOptions = getColumnClassOptions(this, initialColumnClassOptions)
            if ~isempty(this.ColumnClassOptionsStrategy)
                columnClassOptions = this.ColumnClassOptionsStrategy.getColumnClassOptionsForImport(initialColumnClassOptions);
            else
                columnClassOptions = initialColumnClassOptions;
            end
        end
        
        % Convert from table to the specific datatype. Returns the converted
        % variable and any new variable names created.  varNames can be empty if
        % the original variable name is used.
        function [vars, varNames] = convertFromImportedData(~, ~)
            vars = {};
            varNames = {};
        end
        
        % Generate the code string which will be used to convert from table to a
        % specific datatype.  Returns the code, and any variables that need to
        % be cleared.
        function [code, varsToClear] = getCodeToConvertFromImportedData(~, ~, ~)
            code = "";
            varsToClear = [];
        end
        
        % Return the function header line that indicates the type of output the
        % function will produce.
        function code = getFunctionHeaderCode(~)
            code = "";
        end
        
        % Returns the function handle of the function used to perform the
        % import.  Typically this is @readtable, but could also be
        % @readmatrix, @readtimetable, etc...
        function fcnHandle = getImportFunction(~)
            % Imports using readtable
            fcnHandle = @readtable;
        end
        
        % Returns the name of the function used to perform the import.
        % Typically this is "readtable", but could also be "readmatrix",
        % "readtimetable", etc...
        function fcnHandleName = getImportFunctionName(~)
            % Imports using readtable
            fcnHandleName = "readtable";
        end
        
        % Returns true if the output requires some conversion, false if
        % not.  For example, if the output type is table, and readtable is
        % used, no conversion is required.  However, if the output type is
        % cell, then conversion will be needed to go from table to cell.
        function b = requiresOutputConversion(~)
            b = true;
        end
        
        % Called to allow the Output Type to make changes to the import options
        % object prior to the read* function being called.  By default no
        % changes are made.
        function opts = updateImportOptionsForOutputType(~, origOpts)
            opts = origOpts;
        end
        
        % Called to initialize arguments for the OutputType based on the view
        % model's settings (TableModelProperties, ColumnModelProperties, etc.)
        % By default, no properties are needed.
        function initOutputArgsFromProperties(~, ~)
        end
        
        % Called to get additional arguments for the import function.  Return a
        % cell array, which will be expanded as the args for the function.  By
        % default, no additional arguments are needed.
        function c = getAdditionalArgsForImportFcn(~)
            c = {};
        end
        
        % Called to get additional arguments for the import function for code
        % generation.  Return a string which is properly formatted, which will
        % be appended to the codegen function call.  By default, no additional
        % arguments are needed.
        function s = getAdditionalArgsForCodeGen(~)
            s = strings(0);
        end
        
        % Called to get the output type to initialize variables for codegen,
        % where the code generation happens with multiple calls, and is
        % concatenated together afterwards.  Return a string which is the data
        % type, for example:  "table"
        function s = getOutputTypeInitializerForCodeGen(~)
            s = "table";
        end

        function b = isTabular(~)
            b = false;
        end
    end
end
