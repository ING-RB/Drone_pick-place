function c = cellstr(s) %#codegen
%CELLSTR Create cell array of character vectors
%   C = CELLSTR(S) converts S to a cell array of character vectors.
%   If S is a string array, then CELLSTR converts each element of S.
%   If S is a character array, then CELLSTR places each row into a
%   separate cell of C. Any trailing spaces in the character vectors are 
%   removed.
%
%   Use STRING to convert C to a string array, or CHAR to convert C
%   to a character array.
%
%   Another way to create a cell array of character vectors is by using 
%   curly braces:
%      C = {'hello' 'yes' 'no' 'goodbye'};
%
%   See also STRING, CHAR, ISCELLSTR.

%   Copyright 2020 The MathWorks, Inc.

if ischar(s)
    if isempty(s)
        c = {''};
    else
        coder.internal.errorIf(~ismatrix(s),'MATLAB:cellstr:InputShape');
        numrows = size(s,1);
        c = cell(numrows,1);
        for i = 1:numrows
            c{i} = deblank(s(i,:));
        end
    end
elseif iscellstr(s) 
    c = s;
elseif iscell(s)
    c = cell(size(s));
    for i=1:numel(s)
        if ischar(s{i})
            c{i} = char(s{i});
        elseif isstring(s{i}) && isscalar(s{i}) % && ~ismissing(s{i})) (missing not supported for codegen)
            c{i} = char(s{i});
        else
            coder.internal.errorIf(isstring(s{i}) && isscalar(s{i}) && ismissing(s{i}), 'MATLAB:string:CannotConvertMissingElementToChar', i);
            coder.internal.assert(isstring(s{i}) && isscalar(s{i}) && ismissing(s{i}), 'MATLAB:cellstr:MustContainText', i);
        end
    end
elseif isstring(s) && isscalar(s)
    c = cellstr(s);
else
    coder.internal.assert(false, 'MATLAB:invalidConversion', 'cellstr', class(s));
end
