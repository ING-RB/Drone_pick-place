function b = extractData(t,inputvars)  %#codegen
%EXTRACTDATA Extract data from a table.
%   B = EXTRACTDATA(T,VARS) returns the contents of the variables table T
%   specified by VARS, converted to an array whose type is that of the first
%   variable. The classes of the remaining variables must support the
%   conversion. VARS is a positive integer, a vector of positive integers, a
%   variable name, a cell array containing one or more variable names, or a
%   logical vector.
%
%   See also TABLE.

%   Copyright 2019-2021 The MathWorks, Inc.
coder.internal.prefer_const(inputvars);

vars = t.varDim.subs2inds(inputvars);

if isempty(vars)
    b = zeros(t.rowDimLength(),0,'double');
    return
end

vars1 = t.data{vars(1)};
ndims1 = ndims(vars1);
size1 = size(vars1);
bwidth = size1(2);
haveString = false;
for i = 1:numel(vars)
    if isstring(t.data{vars(i)})
        haveString = true;
        break;
    end
end
iscell1 = iscell(vars1);
for i = 2:numel(vars)
    varsi = t.data{vars(i)};
    % verify all veriables have same number of dimensions
    coder.internal.assert(ndims(varsi) == ndims1, 'MATLAB:table:ExtractDataDimensionMismatch');
    % verify all veriables have same sizes along all dimensions except
    % second dimension
    sizei = size(varsi);
    coder.internal.assert(isequal(sizei([1 3:end]), size1([1 3:end])), ...
        'MATLAB:table:ExtractDataSizeMismatch');
    % Disallow mixture of cells (such as cellstr) and other types
    coder.internal.assert(haveString || iscell(varsi) == iscell1, 'MATLAB:table:ExtractDataIncompatibleTypeError',...
        t.varDim.labels{vars(1)}, t.varDim.labels{vars(i)}, class(vars1), class(varsi));
    bwidth = bwidth + sizei(2);
end

% Concatenate the cell array of variables.  If the vars are empty, the concatenation
% results in a 0x0 empty, not a 0xNvars empty.
if iscell1 && ~haveString
    % special code for cell because lack of cell concatenation support
    if isscalar(vars)  % no need for concatenation if scalar
        b = t.data{vars};
    else
        % Only do concatenation for cell matrices. Disallow higher
        % dimensions.
        coder.internal.assert(ndims1 == 2, 'MATLAB:table:NDCellIndexing');
        size1(2) = bwidth;
        b = coder.nullcopy(cell(size1));
        counter = 0;
        for j = 1:numel(vars)            
            currvar = t.data{vars(j)};
            coder.unroll(coder.internal.isConst(numel(currvar)));
            for k = 1:numel(currvar)
                b{counter + k} = currvar{k};
            end
            counter = counter + numel(currvar);
        end
    end
else
    b = [ t.data{vars} ];
end