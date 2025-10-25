function m = cell2mat(c)
%CELL2MAT Convert the contents of a cell array into a matrix.
%   M = CELL2MAT(C) converts a multidimensional cell array into a matrix.
%   The contents of C must be able to concatenate into a hyperrectangle.
%   Moreover, for each pair of neighboring cells, the dimensions of the
%   cell's contents must match, excluding the dimension in which the cells
%   are neighbors. This constraint must hold true for neighboring cells
%   along all of the cell array's dimensions.
%
%   The dimensionality of M, i.e. the number of dimensions of M, will match
%   the highest dimensionality contained in the cell array.
%
%   CELL2MAT is not supported for cell arrays containing cell arrays.
%
%       Example:
%          C = {[1] [2 3 4]; [5; 9] [6 7 8; 10 11 12]};
%          M = cell2mat(C)
%
%       See also MAT2CELL, NUM2CELL

% Copyright 1984-2024 The MathWorks, Inc.

    arguments
        c cell
    end

    % short circuit for simplest case
    elements = numel(c);
    if elements == 0
        m = [];
        return
    end

    % error if first element is a cell array
    if iscell(c{1})
        error(message('MATLAB:cell2mat:UnsupportedCellContent'));
    end

    % short circuit for single element
    if elements == 1
        m = c{1};
        return
    end

    % Check if cell array is homogeneous
    cellclass = class(c{1});
    ciscellclass = cellfun('isclass',c,cellclass);
    if ~all(ciscellclass(:))
        % check for nested cell arrays
        nestedcells = cellfun('isclass',c,'cell');
        if any(nestedcells(:))
            error(message('MATLAB:cell2mat:UnsupportedCellContent'));
        end
        % error if array contains logical and char
        logicalcells = cellfun('islogical',c);
        charcells = cellfun('isclass',c,'char');
        if any(logicalcells(:)) && any(charcells(:))
            error(message('MATLAB:cell2mat:IncompatibleTypes'));
        end
        try
            m = concatenateCellContents(c);
            return
        catch ME
            newMsg = message('MATLAB:cell2mat:CatFailed');
            newME = MException(newMsg.Identifier,getString(newMsg));
            newME = addCause(newME, ME);
            throw(newME)
        end
    end

    m = concatenateCellContents(c);

end

function m = concatenateCellContents(c)
% If cell array is 2-D, execute 2-D code for speed efficiency
    if ismatrix(c)
        rows = size(c,1);
        cols = size(c,2);
        if (rows < cols)
            m = cell(rows,1);
            % Concatenate one dim first
            for n=1:rows
                m{n} = cat(2,c{n,:});
            end
            % Now concatenate the single column of cells into a matrix
            m = cat(1,m{:});
        else
            m = cell(1, cols);
            % Concatenate one dim first
            for n=1:cols
                m{n} = cat(1,c{:,n});
            end
            % Now concatenate the single row of cells into a matrix
            m = cat(2,m{:});
        end
        return
    end

    csize = size(c);
    % Treat 3+ dimension arrays

    % Construct the matrix by concatenating each dimension of the cell array into
    %   a temporary cell array, CT
    % The exterior loop iterates one time less than the number of dimensions,
    %   and the final dimension (dimension 1) concatenation occurs after the loops

    % Loop through the cell array dimensions in reverse order to perform the
    %   sequential concatenations
    for cdim=(length(csize)-1):-1:1
        % Pre-calculated outside the next loop for efficiency
        ct = cell([csize(1:cdim) 1]);
        cts = size(ct);
        ctsl = length(cts);
        mref = {};

        % Concatenate the dimension, (CDIM+1), at each element in the temporary cell
        %   array, CT
        for mind=1:prod(cts)
            [mref{1:ctsl}] = ind2sub(cts,mind);
            % Treat a size [N 1] array as size [N], since this is how the indices
            %   are found to calculate CT
            if ctsl==2 && cts(2)==1
                mref = {mref{1}};
            end
            % Perform the concatenation along the (CDIM+1) dimension
            ct{mref{:}} = cat(cdim+1,c{mref{:},:});
        end
        % Replace C with the new temporarily concatenated cell array, CT
        c = ct;
    end

    % Finally, concatenate the final rows of cells into a matrix
    m = cat(1,c{:});
end
