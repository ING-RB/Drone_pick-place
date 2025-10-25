function vars = container2vars(c)  %#codegen
%CONTAINER2VARS Convert cell or structure array to table's internal representation.

%   Copyright 2018-2022 The MathWorks, Inc.
haveCell = iscell(c);
if haveCell
    nvars = size(c,2);
else
    s = c;
    fnames = fieldnames(s);
    nvars = length(fnames);
end

vars = cell(1,nvars);

for j = 1:nvars
    if haveCell
        %cj = c(:,j);
        cj = cell(size(c,1),1);
        for i = 1:numel(cj)
            cj{i} = c{i,j};
        end
    else % have structure
        %cj = {s.(fnames{j})}';
        
        cj = cell(numel(s),1);
        for i = 1:numel(cj)
            cj{i} = s(i).(fnames{j});
        end
    end
    
    if coder.internal.isConst(numel(cj))
        if isempty(cj)
            vars{j} = zeros(size(cj,1),0);
            continue
        elseif iscellstr(cj)
            % Prevent a cellstr that happens to have all the same length
            % character vectors, e.g., datestrs, from being converted into a
            % character array.
            vars{j} = cj;
            continue
        end
        cellAllOneRow = true;
        coder.unroll;
        for i = 1:numel(cj)
            cellAllOneRow = coder.const(cellAllOneRow && coder.internal.isConst(size(cj{i},1)) && (size(cj{i},1) == 1));
            if ~cellAllOneRow
                break;
            end
        end
    else  % var sized cj, which means homogeneous cell array
        % variable-sized cell arrays cannot be empty at run-time
        coder.internal.errorIf(isempty(cj), 'MATLAB:table:EmptyMustBeFixedSize');
        % for homogeneous cell arrays, just need to check the first cell.
        % do not convert a cellstr into a character array.
        % if cell content is variable-sized, just leave them in their
        % cells.
        cellAllOneRow = coder.internal.isConst(size(cj{1},1)) && ...
            size(cj{1},1) == 1 && ~ischar(cj{1});
    end
    
    if ~cellAllOneRow
        % If the cells don't all have one row, we won't be able to
        % concatenate them and preserve rows, leave it as is.
        vars{j} = cj;
    elseif coder.internal.isConst(isscalar(cj)) && isscalar(cj)
        vars{j} = cj{1};
    else
        % check all elements of cell array can be concatenated
        if coder.internal.isConst(numel(cj))
            compat = matlab.internal.coder.datatypes.canCellValuesConcatenate(cj);
        else
            % homogeneous cells can always be concatenated
            compat = true;
        end
        % when a field of a struct array have different sizes, it
        % becomes variable sized. In that case, isConst returns false,
        % and we just leave the variable in cells
        if coder.internal.isConst(compat) && compat
            % cell array needs special handling. Cat doesn't work.
            if iscell(cj{1})
                szcj1 = size(cj{1});
                numelcj1 = numel(cj{1});
                sz = [size(cj,1) szcj1(2:end)];
                vars{j} = coder.nullcopy(cell(sz));
                % need to force unroll the inner loop in case of
                % heterogeneous cell arrays
                for i = 1:size(cj,1)
                    coder.unroll();
                    for ii = 1:numelcj1
                        vars{j}{i,ii} = cj{i}{ii};
                    end
                end
            else
                if coder.internal.isConst(numel(cj))
                    vars{j} = cat(1,cj{:});
                else  % if cj is variable sized, cannot call cat with variable number of inputs
                    % preallocate and fill in instead
                    vars{j} = repmat(cj{1},numel(cj), 1);
                    for i = 1:numel(cj)
                        vars{j}(i,:) = cj{i};
                    end
                    
                end
            end
        else
            vars{j} = cj;
        end
    end
end
