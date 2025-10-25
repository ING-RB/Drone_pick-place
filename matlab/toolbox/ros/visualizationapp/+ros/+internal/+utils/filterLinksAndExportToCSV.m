function filterLinksAndExportToCSV(filteredSearchResults, cacheDataTable, outputCSVFile)
    % This function is for internal use only
    
    
    %FILTERLINKSANDEXPORTTOCSV Filters links from search results and exports relevant data to a CSV file
    %   This function takes search results, filters out hyperlinks, matches the filtered results with entries
    %   in a given data table, and then exports the matched entries to a CSV file. 
    
    %  Copyright 2024 The MathWorks, Inc.

    
     if isempty(filteredSearchResults) || isempty(cacheDataTable)
                error(message("ros:visualizationapp:view:EmptySearchExport"));
     end
    
    % Regular expression to extract text from HTML hyperlinks. Taken from
    % ChatGPT
    hyperlinkPattern = '(?<=<a [^>]*>).*?(?=</a>)';
    
    % Extract text from hyperlinks in the search results
    extractedFilePaths = cellfun(@(x) regexp(x, hyperlinkPattern, 'match', 'once'), ...
        filteredSearchResults, 'UniformOutput', false);
    
    % Find indices of entries in the cache data table that match the extracted file paths
    matchedIndices = contains(cacheDataTable.bagPaths, extractedFilePaths);
    filteredTable = cacheDataTable(matchedIndices, :);
    
    % Function to convert a cell array column to a comma-separated string for each cell
    convertToCommaSeparatedString = @(col) arrayfun(@getCommaSeparatedString, col, "UniformOutput", false);
        
    % Process 'tags', 'bookmarks', and 'visualizerTypes' columns to comma-separated strings
    filteredTable.tags = convertToCommaSeparatedString(filteredTable.tags);
    filteredTable.bookmarks = convertToCommaSeparatedString(filteredTable.bookmarks);
    filteredTable.visualizerTypes = convertToCommaSeparatedString(filteredTable.visualizerTypes);

    % Write the filtered data table to a CSV file
    writetable(filteredTable, outputCSVFile);

end


function out = getCommaSeparatedString( inp )
    % getCommaSeparatedString get a comma separated string for
    % values stored in the cache table column
            

    % Get the cell value
    colVal = inp{1};
   

    if isequal(colVal, [])
        out = {''};
    elseif iscell(colVal)
        % Remove empty arrays {''}
        colVal = colVal(~cellfun(@(e) isempty(e), colVal));

        % Check if cell value is empty
        if isempty(colVal)
            colVal = {''};
        end

        out = {strjoin(colVal, ',')};

    else
        % For visualizerTypes column as it contains an array of
        % strings
        out = {strjoin(cellstr(colVal), ',')};
    end
end
