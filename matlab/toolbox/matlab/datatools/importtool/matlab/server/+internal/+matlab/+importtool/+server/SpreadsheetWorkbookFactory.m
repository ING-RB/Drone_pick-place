classdef SpreadsheetWorkbookFactory < handle
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % Creates a Spreadsheet Workbook object for a given file.
    
    % Copyright 2018-2024 The MathWorks, Inc.
    
    properties(Access = protected)
        Workbooks;
    end
    
    methods(Static)
        % Get an instance of the SpreadsheetWorkbookFactory Service
        function obj = getInstance(varargin)
            mlock;  % Keep persistent variables until MATLAB exits
            persistent workbookFactoryInstance;
            if isempty(workbookFactoryInstance) || ~isvalid(workbookFactoryInstance)
                workbookFactoryInstance = internal.matlab.importtool.server.SpreadsheetWorkbookFactory;
            end
            obj = workbookFactoryInstance;
        end
    end
    
    methods
        % Get the Workbook object for the given spreadsheet file
        function [workbook, cached] = getWorkbookForFile(this, fileName)
            fileName = convertStringsToChars(fileName);
            workbook = [];
            cached = false;
            
            if isKey(this.Workbooks, fileName)
                % Try to use the workbook from the cache
                workbook = this.Workbooks(fileName);
                cached = true;
            end
            
            if isempty(workbook) || ~isvalid(workbook)
                % If the workbook hasn't been cached yet, or if it is invalid,
                % created it.  This can take time for larger files.
                fmt = matlab.io.spreadsheet.internal.getExtension(fileName);

                % Certain Excel formats require interoperability (Excel), but 
                % if it isn't required, its more performant to not use it.  
                % This is the third argument to create the workbook.
                interop = contains(fmt, ["ods", "xlsb"], "IgnoreCase", true);
                try
                    workbook = matlab.io.spreadsheet.internal.createWorkbook(char(fmt), char(fileName), interop);
                catch ex
                    % There have been some rare cases where the workbook
                    % creation fails, and requires Excel to open it.  If
                    % this is on Windows, retry with interoperability set
                    % to true.
                    if ispc
                        workbook = matlab.io.spreadsheet.internal.createWorkbook(char(fmt), char(fileName), true);
                    else
                        rethrow(ex);
                    end
                end
                this.Workbooks(fileName) = workbook;
                cached = false;
            end
        end
        
        function workbookClosed(this, fileName)
            % Called when a workbook is closed, and can be deleted and removed
            % from the cache.
            if isKey(this.Workbooks, fileName)
                workbook = this.Workbooks(fileName);
                remove(this.Workbooks, fileName);
                delete(workbook);
            end
        end

        function closeAllWorkbooks(this)
            % Called to delete all workbooks and remove them from the cache
            k = keys(this.Workbooks);
            for idx = 1:length(k)
                key = k{idx};
                workbook = this.Workbooks(key);
                remove(this.Workbooks, key);
                delete(workbook);
            end
        end
        
        function w = getAllWorkbooks(this)
            % Returns all cached workbooks
            w = this.Workbooks;
        end
    end
    
    methods(Access = protected)
        function this = SpreadsheetWorkbookFactory()
            this.Workbooks = containers.Map;
        end
    end  
end
