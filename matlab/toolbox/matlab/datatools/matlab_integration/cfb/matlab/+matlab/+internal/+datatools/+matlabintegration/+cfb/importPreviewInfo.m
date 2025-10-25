% This class is unsupported and might change or be removed without
% notice in a future version.

% This class creates a struct of details determined from detectImportOptions,
% that are shown in the Current Folder Browser preview pane.  If the file is too
% large, returns an empty struct.  This function is called when the user shows
% the preview from the CFB, so needs to be quick.

% Copyright 2021-2025 The MathWorks, Inc.

function s = importPreviewInfo(filename)
    arguments
        filename char {mustBeFile}
    end

    d = dir(filename);
    s = struct();

    % Skip if file is too big (1Mb)
    LARGE_FILE_SIZE = 1024*1024;
    if d.bytes ~= LARGE_FILE_SIZE
        spreadsheetFileExtensions = matlab.io.internal.FileExtensions.SpreadsheetExtensions;

        % Pull of the extension instead of using fileparts, which does a
        % lot of extra work we don't care about in this context.
        extIdx = find(filename == '.', 1, 'last');
        ext = filename(extIdx:end);

        try
            if contains(ext, spreadsheetFileExtensions)
                % Spreadsheet Import
                opts = detectImportOptions(filename, "FileType", "spreadsheet", "TextType", "string");

                % Show the sheet names of the spreadsheet
                s.SheetNames = sheetnames(filename);
                s.SheetNamesLabel = getString(message("MATLAB:datatools:importdata:SpreadsheetPreviewSheetNames"));
            else
                % Delimited Text Import
                opts = detectImportOptions(filename, "FileType", "delimitedtext", "TextType", "string");

                % Show the delimiter
                delim = opts.Delimiter{1};
                switch (delim)
                    case " "
                        delim = getString(message("MATLAB:datatools:importdata:TextPreviewDelimiterSpace"));
                    case "\t"
                        delim = getString(message("MATLAB:datatools:importdata:TextPreviewDelimiterTab"));
                end
                s.Delimiter = {delim};
                s.DelimiterLabel = getString(message("MATLAB:datatools:importdata:TextPreviewDelimiter"));
            end

            % Properties that are common:  Variable Names and Types
            NUM_VARS_TO_DISPLAY = 5;
            varNames = opts.VariableNames;
            varTypes = opts.VariableTypes;
            numVars = length(varNames);
            if numVars > (NUM_VARS_TO_DISPLAY + 1)
                andMoreMsg = message("MATLAB:datatools:importdata:ImportPreviewAndMore", ...
                    (numVars - NUM_VARS_TO_DISPLAY)).getString;

                varNames = varNames(1:NUM_VARS_TO_DISPLAY);
                varNames{end+1} = andMoreMsg;

                varTypes = varTypes(1:NUM_VARS_TO_DISPLAY);
                varTypes{end+1} = andMoreMsg;
            end

            s.VariableNames = varNames;
            s.VariableNamesLabel = getString(message("MATLAB:datatools:importdata:PreviewVariableNames"));

            s.VariableTypes = varTypes;
            s.VariableTypesLabel =  getString(message("MATLAB:datatools:importdata:PreviewVariableTypes"));
        catch
            % Ignore errors.  This can happen in case of file extensions
            % which are not correct, or when an Excel file is open in
            % Excel.  By sending back no information, it just means the
            % default preview will be shown.
        end
    end
end
