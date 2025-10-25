classdef TabularImportDataModel < internal.matlab.variableeditor.ArrayDataModel

    % This class is unsupported and might change or be removed without notice in
    % a future version.

    % This class is the common DataModel class, used for Text and spreadsheet
    % Import

    % Copyright 2018-2024 The MathWorks, Inc.

    properties (Hidden = true)
        FileImporter;
    end

    properties
        Data  % unused, just referenced by VE infrastructure
    end

    properties (Access = private)
        DataChangeListener
    end


    methods (Access = public)
        function this = TabularImportDataModel(fileImporter)
            this.FileImporter = fileImporter;

            this.DataChangeListener = event.listener(this.FileImporter, "DataChange", @(es, ed) this.dataChanged(es, ed));
        end

        function filename = getFileName(this)
            filename = this.FileImporter.FileName;
        end

        function props = getDataSourceProps(this)
            props = this.FileImporter.DataSourceProps;
        end

        function dims = getSheetDimensions(this)
            dims = this.FileImporter.getSheetDimensions();
        end

        function headerRow = getHeaderRow(this)
            headerRow = this.FileImporter.getHeaderRow();
        end

        function columnCount = getColumnCount(this)
            columnCount = this.FileImporter.getColumnCount();
        end

        function initialSelection = getInitialSelection(this)
            initialSelection = this.FileImporter.getInitialSelection();
        end

        function [varNames, vars, opts] = importData(this, opts, varargin)
            [varNames, vars, opts] = this.FileImporter.importData(opts, varargin{:});
        end

        function [opts, dataRanges] = getImportOptions(this, varargin)
            [opts, dataRanges] = this.FileImporter.getImportOptions(varargin{:});
        end

        function dateColFormats = getDateFormats(this)
            dateColFormats = this.FileImporter.getDateFormats();
        end

        function durationColFormats = getDurationFormats(this)
            durationColFormats = this.FileImporter.getDurationFormats();
        end

        function columnClasses = getColumnClasses(this)
            columnClasses = this.FileImporter.getColumnClasses();
        end

        function columnClassOptions = getColumnClassOptions(this)
            columnClassOptions = this.FileImporter.getColumnClassOptions();
        end

        function state = getState(this)
            state = this.FileImporter.getState();
        end

        function setState(this, varargin)
            this.FileImporter.setState(varargin{:});
        end

        function columnNames = getColumnNames(this, row, avoidShadow, varargin)
            columnNames = this.FileImporter.getColumnNames(row, avoidShadow, varargin{:});
        end

        function initColumnNames(this)
            this.FileImporter.initColumnNames();
        end

        function colsToTrim = getTrimNonNumericCols(this, currVarTypes)
            colsToTrim = this.FileImporter.getTrimNonNumericCols(currVarTypes);
        end

        function [data, raw, dateData, cachedData, rowRange, colRange] = getData(this, startRow, endRow, startCol, endCol, asDatetime)
            if nargin < 6
                % Unless explicitly set as an argument, dates will be returned
                % as text rather than datetime objects.
                asDatetime = false;

                if nargin == 1
                    data = [];
                    return;
                end
            end
            [data, raw, dateData, cachedData, rowRange, colRange] = this.FileImporter.getData(startRow, endRow, startCol, endCol, asDatetime);
        end

        function [data, raw, dateData, cachedData, rowRange, colRange] = getDataFromExcelRange(this, excelRange, asDatetime)
            if nargin <= 2
                % Unless explicitly set as an argument, dates will be returned
                % as text rather than datetime objects.
                asDatetime = false;
            end
            [data, raw, dateData, cachedData, rowRange, colRange] = this.FileImporter.getDataFromExcelRange(excelRange, asDatetime);
        end

        function [code, codeGenerator, codeDescription] = generateScriptCode(this, varargin)
            [code, codeGenerator, codeDescription] = this.FileImporter.generateScriptCode(varargin{:});
        end

        function [code, codeGenerator] = generateFunctionCode(this, varargin)
            [code, codeGenerator] = this.FileImporter.generateFunctionCode(varargin{:});
        end

        function s = addAdditionalImportDataFields(this, currImportDataStruct)
            s = this.FileImporter.addAdditionalImportDataFields(currImportDataStruct);
        end

        function interpreted = getConvertedDatetimeValue(this, importOptions, data, raw)
            interpreted = this.FileImporter.getConvertedDatetimeValue(importOptions, data, raw);
        end

        function varOutputName = getDefaultVariableOutputName(this)
            varOutputName = this.FileImporter.getDefaultVariableOutputName();

            % make it unique if the varname already exists in the workspace
            varOutputName = matlab.lang.makeUniqueStrings(varOutputName, evalin('base', 'who'));
        end

        function data = updateData(~, varargin)
            % Unused for text import
            data = [];
        end

        function data = variableChanged(~, varargin)
            % Unused for text import
            data = [];
        end

        function columnTypes = getUnderlyingColumnTypes(this)
            columnTypes = this.FileImporter.getUnderlyingColumnTypes();
        end

        function rulesStrategy = getRulesStrategy(this)
            rulesStrategy = this.FileImporter.RulesStrategy;
        end

        function resetStoredNames(this)
            this.FileImporter.resetStoredNames();
        end

        function d = convertEmptyDatetimes(this, val)
            d = this.FileImporter.convertEmptyDatetimes(val);
        end
    end

    methods (Access = protected)
        function lhs = getLHS(~, varargin)
            % Unused for text import
            lhs = [];
        end

        function dataChanged(this, ~, ed)
            % By default just propagate the event
            if isprop(ed, "SizeChanged")
                this.notify("DataChange", ed);
            end
        end
    end
end

