function t2 = braceAssign(t,rhs,varargin)   %#codegen
%BRACEASSIGN Subscripted assignment using braces into a table.

%   Copyright 2019-2021 The MathWorks, Inc.

subsTypes = matlab.internal.coder.tabular.private.tabularDimension.subsType; % "import" for calls to subs2inds

coder.internal.errorIf(numel(varargin) == 1, 'MATLAB:table:LinearSubscript');
coder.internal.assert(numel(varargin) == t.metaDim.length, 'MATLAB:table:NDSubscript'); % Error for ND indexing

varIndices = t.varDim.subs2inds(varargin{2},subsTypes.assignment,t.data);

% Syntax:  t{rowIndices,varIndices} = b
%
% Assignment to contents of a table.

% Special flag to avoid converting rhs to a table whenever possible. See
% parenAssignImpl for more details.
isInternalCall = true;

% For successful brace assignment, all variables being assigned to should have
% the same sizes along all but the second dimension. Verify this and error
% accordingly. For new variables we assume the size along the second dimension
% to be 1. Do this check explicitly over here instead of relying on
% subsasgnParens to ensure that cases when the LHS variables have invalid
% dimensions, do not succeed because of unintended scalar expansion.
colSizes = ones(1,length(varIndices));
if ~isempty(varIndices)
    % verify all variables have same number of dimensions
    dims = ndims(t.data{varIndices(1)});
    for i = 2:numel(varIndices) 
        coder.internal.errorIf(dims ~= ndims(t.data{varIndices(i)}), ...
            'MATLAB:table:ExtractDataDimensionMismatch'); 
    end
    sizes = zeros(length(varIndices),dims);
    szRef = size(t.data{varIndices(1)});
    for i = 1:numel(varIndices)
        % Assign the size to a local variable and check it one by one to ensure
        % that we throw a compile-time error whenever possible.
        sz = size(t.data{varIndices(i)});
        coder.internal.errorIf(~isequal(szRef(3:end),sz(3:end)), ...
            'MATLAB:table:ExtractDataSizeMismatch');
        sizes(i,:) = sz;
    end
    colSizes(:) = sizes(:,2);
end
sizeRHS = size(rhs);
% Convert rhs into a row of cells (same representation as t.data) before
% passing it to parenAssignImpl, if possible.
if coder.internal.isConstTrue(isscalar(rhs))
    if isa(rhs,'matlab.internal.coder.tabular')
        % We repmat scalar rhs inside parenAssignImpl. Since tabular does not
        % support repmat, use the old method of wrapping the rhs into a table
        % and calling parenAssignImpl with isIternalCall set to false.
        rhs_data = matlab.internal.coder.table.init({rhs}, 1, {}, 1, {'Var1'});
        isInternalCall = false;
    else
        rhs_data = {rhs};
    end
else
    
    % We know the number of columns in each existing var, assume one column for
    % new vars.  If we have the right number of columns on the RHS, good.
    coder.internal.assert(size(rhs,2) == sum(colSizes), 'MATLAB:table:WrongNumberRHSCols',sum(colSizes));

    % We have already verified that the exsiting variables have the same sizes
    % along the trailing dimensions. Verfiy that even the RHS has the same
    % trailing sizes.
    coder.internal.errorIf(~isempty(varIndices) && ~isequal(sizeRHS(3:end),sizes(1,3:end)), ...
        'MATLAB:table:WrongSizeRHS');

    %dimSz = num2cell(size(rhs)); dimSz{2} = colSizes;
    %rhs_data = mat2cell(rhs,dimSz{:});
    if coder.internal.isConstTrue(isscalar(colSizes))
        % Optimize the one variable case by avoiding mat2cell logic below and
        % simply wrapping up the rhs in a cell array.
        rhs_data = {rhs};
    else
        rhs_data = cell(1,numel(colSizes));
        dummy_varnames = cell(1,numel(colSizes));
        if iscell(rhs)  % cellstr
            for i = 1:numel(rhs_data)  % loop through each cell
                cellwidth = colSizes(i);
                colstart = sum(colSizes(1:i-1));
                rhsheight = size(rhs,1);
                rhs_data{i} = coder.nullcopy(cell(rhsheight,cellwidth));
                for k = 1:cellwidth  % loop through each column within a cell
                    for j = 1:rhsheight  % loop through each row within a cell
                        rhs_data{i}{j,k} = rhs{j, colstart+k};
                    end
                end
                dummy_varnames{i} = ['Var' num2str(i)];
            end
        else
            for i = 1:numel(rhs_data)
                prev = sum(colSizes(1:i-1));
                rhs_data{i} = rhs(:,prev+(1:size(t.data{varIndices(i)},2)));
                dummy_varnames{i} = ['Var' num2str(i)];
            end
        end
    end
end

t2 = parenAssignImpl(t,rhs_data,isInternalCall,sizeRHS(1),varargin{:});

