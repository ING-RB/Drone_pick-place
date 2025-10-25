function s = columnLetter(d)
    %   COLUMNLETTER(D) returns the representation of D as a spreadsheet column letter,
    %   expressed as 'A'..'Z', 'AA','AB'...'AZ', and so on. 
    %
    %   Examples:
    %       dec2base(1) returns 'A'
    %       dec2base(26) returns 'Z'
    %       dec2base(27) returns 'AA'
    %
    % See also matlab.io.spreadsheet.internal.columnNumber
    
    %   Copyright 2014-2016 The MathWorks, Inc.

    persistent powersOf26 
    if isempty(powersOf26)
        powersOf26 = 26.^(1:11);
    end
        
    digits = 1;
    begin = 0;
    current_sum = 26;
    % This calculates the number of "letter-digits" in the output
    while d > current_sum
        digits = digits + 1;
        begin = current_sum;
        current_sum = begin + powersOf26(digits);
    end
    
    idx = zeros(1,digits);
    pos = d - begin;

    % Find the leftmost "letter-digits" 
    for i = digits:-1:3
        remainder = rem(pos-1, powersOf26(i-1)) + 1;
        idx(i) = (pos - remainder)/powersOf26(i-1) + 1;
        pos = remainder;
    end
    
    % Find the right most "letter-digits"
    if digits >= 2
        idx(1) = rem(pos-1, 26) + 1;
        idx(2) = (pos - idx(1))/26 + 1;
    else
        idx(1) = pos;
    end
    
    % Write out the reverse digits using char
    s = char('A'-1+idx(end:-1:1));
end


