function disp(a,name)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

if isempty(a)
    return;
end

% Let disp on a cellstr do the real work, capture its output.
catnames = [categorical.undefLabel; a.categoryNames];
catnames = strrep(catnames, '''', char(1)); % temporarily replace quotes in the category names
s = char(matlab.display.internal.obsoleteCellDisp(reshape(catnames(a.codes+1),size(a.codes))));

% For N-D arrays, output captured from the cell disp output contains page
% headers like '(:,:,1) ='. Add the array name to those the page headers.
if ~ismatrix(a) && (nargin == 2)
    s = regexprep(s,'(\([0-9:,]+\))', [name '$1']);
end

% Remove quotes that enclose each cell's text, and print to command window.
s = strrep(s, '''', ' ');
s = strrep(s, char(1), ''''); % put back embedded quotes in category names
fprintf('%s',s);
