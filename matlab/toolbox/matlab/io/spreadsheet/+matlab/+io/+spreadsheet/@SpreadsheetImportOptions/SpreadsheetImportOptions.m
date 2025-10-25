classdef SpreadsheetImportOptions < matlab.io.ImportOptions ...
        & matlab.io.internal.shared.SpreadsheetInputs ...
        & matlab.io.internal.parameter.SpanHandlingProvider
    %SpreadsheetImportOptions Options for importing data from a spreadsheet
    %   SpreadsheetImportOptions can be used to import data from a spreadsheet
    %   file.
    %
    %   Example, using detectImportOptions to create import options, set
    %   multiple variable types to categorical, then read the data using
    %   readtable:
    %
    %       opts = detectImportOptions('patients.xls')
    %       opts = setvartype(opts,{'Gender','Location','SelfAssessedHealthStatus'},'categorical')
    %       T = readtable('patients.xls',opts)
    %
    %   Example, setting the fill values for different Variables:
    %
    %       opts = setvaropts(opts,'Smoker','FillValue',false)
    %       opts = setvaropts(opts,{'Diastolic','Systolic'},'FillValue',0)
    %       T = readtable('patients.xls',opts)
    %
    %   Range Options: Many import options specify the Range of some
    %   information such as the data, or names of variables.
    %
    %   The following is a list of different ways to specify a Range:
    %
    %       range        - A character vector containing a rectangular
    %                      range specified by two corner cells, separated
    %                      by a colon. Range may also be a character vector
    %                      containing the name of a range in a sheet.
    %
    %                      Example: 'C2:N15' specifies all the cells between
    %                      rows 2 and 15, and columns C through N.
    %
    %       cell         - A character vector containing a column letter and
    %                      row number.
    %
    %                      Example: 'C13' specifies the 3rd column, and 13th
    %                      row.
    %
    %       row-range    - A character vector containing a starting row number
    %                      and ending row number, separated by a colon.
    %
    %                      Example: '4:17' specifies all the cells in rows 4
    %                      through 17.
    %
    %       column-range - A character vector containing a starting columns
    %                      letter and ending column letter, separated by a
    %                      colon.
    %
    %                      Example: 'C:AZ' specifies all the cells in columns 3
    %                      through 52.
    %
    %       number-index - A row number.
    %
    %   SpreadsheetImportOptions Properties:
    %
    %                          Sheet - The name or number where the table is
    %                                  located
    %                      DataRange - Where the table data is located
    %             VariableNamesRange - Where the variable names are located
    %                  RowNamesRange - Where the row names are located
    %             VariableUnitsRange - Where the variable units are located
    %      VariableDescriptionsRange - Where the variable descriptions are located
    %                  VariableNames - Names of the variables in the file
    %          SelectedVariableNames - Names of the variables to be imported
    %                  VariableTypes - The import types of the variables
    %                VariableOptions - Advanced options for variable import
    %          PreserveVariableNames - Whether or not to convert variable names
    %                                  to valid MATLAB identifiers.
    %                ImportErrorRule - Rules for interpreting nonconvertible or bad data
    %                    MissingRule - Rules for interpreting missing or unavailable data
    %
    %   SpreadsheetImportOptions Methods:
    %
    %       getvaropts - get the options for a variable by name or number
    %       setvaropts - set the options for a variable by name or number
    %       setvartype - set the import type of a variable by name or number
    %          preview - read 8 rows of data from the file using options
    %
    % See also matlab.io.VariableImportOptions, detectImportOptions, readtable

    % Copyright 2016-2024 The MathWorks, Inc.

    properties (Access = {?matlab.io.internal.functions.ReadCellSpreadsheet, ...
            ?matlab.io.internal.functions.ReadMatrixWithImportOptions})
        % When a SpreadsheetImportOptions object that does not contain any
        % variables is provided to readcell or readmatrix, an extra
        % variable is added. This variable keeps track of whether this has
        % occured.
        AddedExtraVar = false;
    end

    methods
        function opts = SpreadsheetImportOptions(varargin)
        % If present, VariableNames needs to be parsed early since others
        % depend on the number of variables.
        % If present, PreserveVariableNames needs to be parsed earlier
        % than VariableNames since it is necessary for validation.
            [opts,otherArgs] = opts.parseInputs(varargin, ...
                                                {'NumVariables','VariableOptions','PreserveVariableNames','VariableNames'});
            opts.assertNoAdditionalParameters(fields(otherArgs),class(opts));
        end
    end

    methods (Access = protected)
        function addCustomPropertyGroups(opts,h)
        % added strings for the property types to the message catalog
        % for translation purposes
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Sheet')),opts,{'Sheet'});
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Replacement')),opts,{'MissingRule','ImportErrorRule','MergedCellColumnRule','MergedCellRowRule'});
            varStruct.VariableNames = [];
            varStruct.VariableTypes = [];
            varStruct.SelectedVariableNames = [];
            varStruct.VariableOptions = [];
            varStruct.VariableNamingRule = opts.VariableNamingRule;
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:VariableImport')),varStruct);
            addPropertyGroup(h,getString(message('MATLAB:textio:importOptionsProperties:Range')),opts,{'DataRange','VariableNamesRange','RowNamesRange','VariableUnitsRange','VariableDescriptionsRange'});
        end

        function modifyCustomGroups(opts,h)
            if ischar(opts.DataRange) && ~(isempty(opts.DataRange) || contains(opts.DataRange,":"))
                d = textscan(opts.DataRange,['%[' 'a':'z' 'A':'Z' ']%f']);
                if numel(d{1}{1})<= 3 && ~isempty(d{2})
                    appendPropDisp(h,"DataRange","(Start Cell)");
                end
            end
        end

        function verifyMaxVarSize(~,n)
            persistent mx
            if isempty(mx), mx = matlab.io.spreadsheet.internal.columnNumber('XFD'); end
            if n > mx
                error(message('MATLAB:spreadsheet:importoptions:MaxVarSize',mx))
            end
        end

        function obj = updatePerVarSizes(obj,nNew)
            import matlab.io.spreadsheet.internal.columnNumber;
            import matlab.io.spreadsheet.internal.columnLetter;

            locNames ={'DataRange','VariableNamesRange','VariableUnitsRange','VariableDescriptionsRange'};
            for l = locNames
                loc = obj.(l{:});
                if ~isempty(loc) && ~isnumeric(loc)
                    rangeType = matlab.io.spreadsheet.internal.validateRange(loc);
                    if ismember(rangeType,{'two-corner','column-only'})

                        if nNew == 0
                            if strcmpi(l, "DataRange")
                                range = strsplit(loc,':');
                                dataRange = range{1};
                                if strcmpi(rangeType, "column-only")
                                    dataRange = [dataRange, '1'];
                                end
                                obj.(l{:}) = dataRange;
                            else
                                obj.(l{:}) = '';
                                warning(message('MATLAB:spreadsheet:importoptions:AdjustedRangeZero',l{:}));
                            end
                        else
                            range = strsplit(loc,':');
                            [columns,rows] = regexp(range,'([0-9]*)','split','match');
                            colNum = columnNumber(columns{1}{1});
                            range{2} = [columnLetter(colNum + nNew - 1),rows{2}{:}];
                            try
                                obj.(l{:}) = strjoin(range,':');
                            catch
                                error(message('MATLAB:spreadsheet:importoptions:RangeOverExtended',l{:}));
                            end
                        end

                    end
                end
            end
        end

        function [opts,rowNamesID,rowNamesAsVariable] = deselectRowNames(opts,rrn)
            dataRng = opts.DataRange;
            rnRng = opts.RowNamesRange;

            if ischar(dataRng)
                [~,d] = matlab.io.spreadsheet.internal.validateRange(dataRng);
                dataRngID = d(2);
            else
                dataRngID = dataRng;
            end

            if ischar(rnRng) && ~isempty(rnRng)
                % the first letter of the RowNamesRange
                [~,d] = matlab.io.spreadsheet.internal.validateRange(rnRng);
                rowNamesID = 1 + dataRngID - d(2);
            elseif isnumeric(rnRng)
                rowNamesID = rnRng;
            else
                rowNamesID = 0;
            end
            [opts,rowNamesAsVariable,rowNamesID] = deselectSelectedRownames(opts,rrn,rowNamesID);
        end

        function [opts,rowNamesAsVariable,rowNamesID] = deselectSelectedRownames(opts,rrn,rowNamesID)
            rowNamesAsVariable = ~(rrn && rowNamesID > 0 && ~ismember(opts.VariableNames(rowNamesID),opts.SelectedVariableNames));
            if ~rowNamesAsVariable
                opts.SelectedVariableNames = [opts.VariableNames(rowNamesID),opts.SelectedVariableNames];
                rowNamesID = 1;
            end
        end
    end

    methods (Hidden)
        function T = readPreview(opts, sheet, rowsToRequest)
            [opts, args] = validateArgs(opts, {});

            % preview should always read the VariableNames from the file
            % if these conditions are met:
            %
            %       1. VariableNamesRange is set (not equal to "") AND
            %
            %       2. VariableNames has not been modified via its set
            %          method. If VariableNames has been set, preview
            %          and readtable must respect those values.
            readVariableNames = opts.VariableNamesRange ~= "" && opts.namesAreGenerated();
            args = [args, 'ReadVariableNames', readVariableNames];
            try
                [data,metadata] = matlab.io.spreadsheet.internal.readSpreadsheet(...
                    sheet, opts, [args,'Preview',rowsToRequest]);
            catch ME
                throw(ME);
            end
            T = buildTableFromResults(data,metadata);
        end

        function n = getNumVars(opts)
            n = numel(opts.VariableOptions);
        end

        function [opts, sheet] = getSheet(opts, filename)
            import matlab.io.internal.common.validators.isGoogleSheet;
            import matlab.io.internal.common.validators.extractGoogleSheetIDFromURL;
            fmt = matlab.io.spreadsheet.internal.getExtension(filename);
            if strcmp(opts.Sheet, '')
                opts.Sheet = 1;
            end
            if isGoogleSheet(filename)
                bookName = extractGoogleSheetIDFromURL(filename);
                book = matlab.io.spreadsheet.internal.createWorkbook('gsheet', ...
                    bookName, 2, opts.Sheet);
                sheet = book.getSheet(opts.Sheet);
            else
                filename = matlab.io.internal.filesystem.resolvePath(filename);
                book = matlab.io.spreadsheet.internal.createWorkbook(fmt, ...
                    filename.ResolvedPath, false, opts.Sheet);
                sheet = book.getSheet(1);
            end
        end
    end

    methods(Static, Hidden)
        function obj = loadobj(s)
            % Loads SpreadsheetImportOptions objects from MAT files.
            obj = matlab.io.ImportOptions.loadImportOptions(s, "spreadsheet");
        end
    end

    methods(Static, Access = protected)
        function props = getTypeSpecificProperties()
            % List of properties specific to SpreadsheetImportOptions to
            % be  set in the loadImportOptions method of ImportOptions.
            props = ["DataRange", "VariableUnitsRange",...
                "VariableNamesRange", "VariableDescriptionsRange",...
                "RowNamesRange", "Sheet", "MergedCellColumnRule", "MergedCellRowRule"];
        end
    end
end

function [opts, args] = validateArgs(opts, args)
    [opts,rrn,~,args] = matlab.io.ImportOptions.validateReadtableInputs(opts,args);
    opts = opts.deselectRowNames(rrn);
end

function T = buildTableFromResults(data,metadata)
    T = table(data{:},...
              'VariableNames',metadata.VariableNames,...
              'RowNames',metadata.RowNames);

    rowDimName = metadata.RowDimNames;
    dimNames = T.Properties.DimensionNames;
    if ~isempty(rowDimName)
        dimNames{1} = rowDimName;
    end
    T.Properties.VariableUnits = metadata.VariableUnits;
    T.Properties.VariableDescriptions = metadata.VariableDescriptions;
    T.Properties.DimensionNames = matlab.lang.makeUniqueStrings(dimNames,metadata.VariableNames,namelengthmax);
end
