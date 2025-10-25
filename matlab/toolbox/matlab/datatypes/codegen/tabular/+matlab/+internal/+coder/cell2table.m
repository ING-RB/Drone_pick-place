function t = cell2table(c,varargin)  %#codegen
%CELL2TABLE Convert cell array to table.

%   Copyright 2019-2020 The MathWorks, Inc.

coder.internal.assert(iscell(c) && ismatrix(c), 'MATLAB:cell2table:NDCell');
coder.internal.assert(coder.internal.isConst(size(c,2)), ...
    'MATLAB:cell2table:VariableColumns');
[nrows,nvars] = size(c);
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

coder.internal.assert(pstruct.VariableNames ~= 0, 'MATLAB:cell2table:CodegenVarNames');
coder.internal.assert(coder.internal.isConst(varnames), 'MATLAB:cell2table:NonconstantVariableNames');

% Verify that dimension names are constant
coder.internal.assert(coder.internal.isConst(dimnames), ...
                                    'MATLAB:table:NonconstantDimensionNames');

if nvars == 0
    % Performant special case to create Nx0 empty table
    if pstruct.RowNames
        t = table('Size', [nrows 0], ...
            'RowNames', rownames, 'VariableNames', ...
            varnames, 'DimensionNames', dimnames);
    else
        t = table('Size', [nrows 0],...
            'VariableNames', varnames, 'DimensionNames', dimnames);
    end
else
    % Each column of C becomes a variable in D
    vars = tabular.container2vars(c);

    t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
end
