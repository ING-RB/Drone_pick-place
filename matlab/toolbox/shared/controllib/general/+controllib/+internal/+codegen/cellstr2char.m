function c = cellstr2char(str) 
% CELLSTR2CHAR  Converts a cell array of strings into a char array with
% newlines in between elements.
%
 
% Author(s): Erman Korkut 04-Apr-2013
% Copyright 2013 The MathWorks, Inc.

if ischar(str)
    c = str;
    return;
end

c = [];
for n = 1:numel(str)
    c = [c,str{n},sprintf('\n')]; %#ok<AGROW>
end
