function d = columnNumber(s)
    %   COLUMNNUMBER(S) returns the column number of S which is a spreadsheeet
    %   column letter 'A'..'Z', 'AA','AB'...'AZ', and so on.
    %
    %   Examples:
    %       base27dec('A') returns 1
    %       base27dec('Z') returns 26
    %       base27dec('IV') returns 256
    %
    % See also matlab.io.spreadsheet.internal.columnLetter
    
    %   Copyright 2014-2018 The MathWorks, Inc.
    
    try
        s = upper(s);
        if length(s) == 1
            d = s(1) -'A' + 1;
        else
            cumulative = sum(26.^(1:numel(s)-1));
            indexes_fliped = 1 + s - 'A';
            indexes = fliplr(indexes_fliped);
            indexes_in_cells = mat2cell(indexes, 1, ones(1,numel(indexes))); %#ok<MMTC>
            d = cumulative + sub2ind(repmat(26, 1,numel(s)), indexes_in_cells{:});
        end
    catch
        d = NaN;
    end
end
