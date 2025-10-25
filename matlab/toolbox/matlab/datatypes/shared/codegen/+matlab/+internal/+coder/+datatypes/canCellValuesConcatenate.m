function tf = canCellValuesConcatenate(cj, idx, allowCellstr) %#codegen
% check whether the elements of cell array cj can be concatenated together
% idx specifies the cell indices in cj we will examine. By default, all cells
% will be examined.
% allowCellstr specifies whether cellstr should be considered to be
% compatible with char and categorical. It is true by default.

%   Copyright 2020 The MathWorks, Inc.

if nargin < 2  % if indices not provided, check on all cells
    idx = 1:numel(cj);
else
    coder.internal.prefer_const(idx);
end
if nargin < 3
    allowCellstr = true;
else
    coder.internal.prefer_const(allowCellstr);
end
if ~isempty(idx)
    cj1 = cj{idx(1)};
    cj1_sz = size(cj1);
    cj1_NumericOrLogical = isnumeric(cj1) || islogical(cj1);
    cj1_NumericOrChar = isnumeric(cj1) || ischar(cj1);
    cj1_CategoricalOrText = isa(cj1,'categorical') || ischar(cj1)  || ...
        (allowCellstr && iscellstr(cj1));  %#ok<ISCLSTR> % string is taken care of separately
    cj1_DurationOrNumeric = isnumeric(cj1) || isa(cj1,'duration');
    allStringCompatibles = isa(cj1,'categorical') || ischar(cj1)  || ...
        iscellstr(cj1) || isstring(cj1) || isnumeric(cj1) || islogical(cj1);
    containsString = isstring(cj1);
    tf = true;
    coder.unroll();
    for i = 2:numel(idx)
        cji = cj{idx(i)};
        % check size and class are both compatible
        tf = tf && isequal(size(cji), cj1_sz) && ...
            ((cj1_NumericOrLogical && (isnumeric(cji) || islogical(cji) || isa(cji,'duration'))) || ...
            (cj1_NumericOrChar && (isnumeric(cji) || ischar(cji))) || ...
            (cj1_DurationOrNumeric && (isnumeric(cji) || islogical(cji) || isa(cji,'duration'))) || ...
            (cj1_CategoricalOrText && (isa(cji,'categorical') || ischar(cji) || ...
            (allowCellstr && iscellstr(cji)))) || ...
            isa(cji,class(cj1))); %#ok<ISCLSTR>
        allStringCompatibles = allStringCompatibles && (isnumeric(cji) || islogical(cji) || ...
            ischar(cji) || isa(cji,'categorical') || iscellstr(cji) || isstring(cji));
        containsString = containsString || isstring(cji);
    end
    tf = tf || (containsString && allStringCompatibles);
else
    tf = true;
end