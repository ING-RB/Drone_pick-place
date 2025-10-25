% matlab.desktop.editor Summary of Editor Document functionality
% Programmatically access the MATLAB Editor to open, change, save, or close
% documents.
%
% MATLAB Version 25.1 (R2025a) 21-Nov-2024 
%
% Work with all documents open in the Editor:
%   isEditorAvailable     - Verify Editor is available.
%   getAll                - Identify all open Editor documents.
%
% Work with single document open in the Editor:
%   getActive             - Find active Editor document.
%   getActiveFilename     - Find file name of active document.
%   findOpenDocument      - Create Document object for open document.
%   isOpen                - Determine if specified file is open in Editor.
%
% Open an existing document or create a new one:
%   newDocument           - Create Document in Editor. 
%   openDocument          - Open file in Editor.
%   openAndGoToFunction   - Open MATLAB file and highlight specified function.
%   openAndGoToLine       - Open file and highlight specified line.
%
% Work with text from an Editor document:
%   indexToPositionInLine - Convert text array index to position within line.
%   positionInLineToIndex - Convert position within line to text array index.
%   linesToText           - Convert cell array of text lines to character array.
%   textToLines           - Convert character array into cell array of text lines.

%   Copyright 2010-2024 The MathWorks, Inc. 
