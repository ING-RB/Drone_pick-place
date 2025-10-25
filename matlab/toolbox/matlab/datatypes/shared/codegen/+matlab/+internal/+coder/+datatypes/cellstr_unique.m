function [u, ia, ic] = cellstr_unique(a, flag)  %#codegen
%CELLSTR_UNIQUE Set unique for a cellstr.
%   CELLSTR_STRTRIM implements unique for cellstr inputs in codegen.

%   Copyright 2018-2020 The MathWorks, Inc.
        
if nargin < 2
    flag = 'sorted';
end

% Early exit case when empty
if isempty(a)
    u = cell(0,1);
    ia = zeros(0,1);
    ic = zeros(0,1);
else
    [c,idx] = matlab.internal.coder.datatypes.cellstr_sort(a);

    % use diff to get the index of unique values
    d = matlab.internal.coder.datatypes.cellstr_diff(c);
    d = [true;d];

    % extract the unique values from sorted list
    % also get the indices corresponding to the unique values
    % Note that u is a varsize array since its dimensions cannot be determined
    % at compile time. Calling MIN with numel(a) is necessary to give the
    % size of u an upperbound.
    u = coder.nullcopy(cell(min(sum(d),numel(a)),1));

    dIdx = find(d);
    n = numel(dIdx);
    ia = zeros(n,1);
    for i = 1:n
        % note that cellstr_sort is not stable, so need to check the idx of
        % all duplicate values and find the minimum to return in ia
        if i ~= numel(dIdx)
            ia(i) = min(idx((dIdx(i):(dIdx(i+1)-1)).'), [], 1);
        else
            ia(i) = min(idx((dIdx(i):end).'), [], 1);
        end
    end

    % find ic
    ic = cumsum(d);

    if isequal(flag,'stable')
        % The values of ic obtained by the above call to cumsum refer to the
        % values in the sorted version of a. Index into ia using these values to
        % get the indices corresponding to the unsorted version.
        ic = ia(ic);
        
        % Sort ia since we want the stable version of the output.
        ia = sort(ia);
    end
    
    ic(idx) = ic;
    
    for i = 1:n
        u{i} = a{ia(i)};
    end
end

