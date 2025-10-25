function t = array2table(x,varargin) %#codegen
%ARRAY2TABLE Convert homogeneous array to table.

%   Copyright 2019-2022 The MathWorks, Inc.

coder.internal.assert(ismatrix(x), 'MATLAB:array2table:NDArray');
dfltDimNames = matlab.internal.coder.table.defaultDimNames;
pnames = {'VariableNames' 'RowNames' 'DimensionNames'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);
pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

varnames = coder.internal.getParameterValue(pstruct.VariableNames,{},varargin{:});
rownames = coder.internal.getParameterValue(pstruct.RowNames,{},varargin{:});
dimnames = coder.internal.getParameterValue(pstruct.DimensionNames,dfltDimNames,varargin{:});

coder.internal.assert(pstruct.VariableNames ~= 0, 'MATLAB:array2table:CodegenVarNames');
coder.internal.assert(coder.internal.isConst(varnames), 'MATLAB:array2table:NonconstantVariableNames');

% Verify that dimension names are constant
coder.internal.assert(coder.internal.isConst(dimnames), ...
                                    'MATLAB:table:NonconstantDimensionNames');

% Get the number of rows and variables
nrows = size(x,1);
sz2 = size(x,2);
if coder.internal.isConst(sz2)
    nvars = coder.const(sz2);
else
    % If the input array is variable sized in the second dimension, then use the
    % number of elements in the supplied varnames as nvars. Add a runtime check to
    % verify that the size of the second dimension and number of variable names,
    % match up. This is necessary to avoid creating variable sized tables.
    nvars = coder.const(numel(varnames));
    coder.internal.assert(nvars == sz2, ...
        'MATLAB:table:IncorrectNumberOfVarNames');
end

if nvars == 0
    % Performant special case to create Nx0 empty table
    if pstruct.RowNames
        t = table('Size', [nrows 0], ...
            'RowNames', rownames, 'VariableNames', varnames, ...
            'DimensionNames', dimnames);
    else
        t = table('Size', [nrows 0],...
            'VariableNames', varnames, 'DimensionNames', dimnames);
    end
else
    % split the array into a cell array, with each column going into a
    % separate cell
    vars = cell(1,nvars);
    if iscell(x)
        for i = 1:nvars
            col = cell(nrows,1);
            for j = 1:nrows
                col{j} = x{j,i};  
            end
            vars{i} = col;
        end
    else
        for i = 1:nvars
            vars{i} = x(:,i);
        end
    end

    % Each column of x becomes a variable in t
    t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
end