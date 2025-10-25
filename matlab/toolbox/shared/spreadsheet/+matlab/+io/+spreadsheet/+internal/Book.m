classdef (Abstract) Book < handle
    % BOOK The equivalent of a Spreadsheet application Workbook
    %   Contains methods to operate on workbooks and the sheets
    %   contained within them.
    %
    
    %   Copyright 2015-2024 The MathWorks, Inc.
    
    properties (Abstract, GetAccess = public, SetAccess = private)
        % String containing 'XLS', 'XLSX'
        Format
    end

    properties (Abstract, GetAccess = public, SetAccess = public)
        % Array containing sheet names for the sheets in the book
        SheetNames
    end
    
    methods (Abstract)
        %
        % SAVE(book, filename)
        %
        %   Saves the changes made to the workbook in to a file
        %   named filename.
        % 
        save(book, varargin)
        
        %
        % sheet = GETSHEET(book, sheetName)
        % sheet = GETSHEET(book, sheetIdx)
        %
        %   Returns a Worksheet object based on the sheet name or
        %   sheet index.
        % 
        sheet = getSheet(book, sheetNameOrIndex)
        
        %
        % sheet = ADDSHEET(book, sheetName)
        % 
        %   Adds a new sheet to the given book at the end. The sheet name is
        %   sheetName.
        %
        % sheet = ADDSHEET(book, sheetName, sheetIdx)
        % 
        %   Adds a new sheet to the given book. The sheet name is
        %   sheetName. It is added at index sheetIdx.
        %
        % sheet = ADDSHEET(book, sheetName, sheetIdx, sheetToCopy)
        %
        %   Inserts a copy of an existing sheet at the provided index with
        %   the provided sheet name.
        %
        % NOTE: Calling this method invalidates all sheet objects obtained
        % previously.
        %
        sheet = addSheet(book, sheetName, index, sheetToCopy)
        
        %
        % REMOVESHEET(book, sheetName)
        % REMOVESHEET(book, sheetIdx)
        %
        %   Removes a Worksheet based on the sheet name or
        %   sheet index.
        % 
        % NOTE: Calling this method invalidates all sheet objects obtained
        % previously.
        removeSheet(book, sheetNameOrIndex)
        
        %
        % GETFILENAME(book)
        %
        %   Returns an absolute path to the location of the spreadsheet
        %   file referenced by book.
        %
        getFileName(book)

        %
        % status = ISSHEETLOADED(book)
        %
        %   Returns whether the specific sheet was loaded or the entire
        %   workbook was loaded.
        %
        status = isSheetLoaded(book)

        %
        %  sheetIndex = LOADEDSHEETINDEX(book)
        %
        %   Returns the index within the workbook of the loaded sheet.
        %
        sheetIndex = loadedSheetIndex(book)
    end
end
