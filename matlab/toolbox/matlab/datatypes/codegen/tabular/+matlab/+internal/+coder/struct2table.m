function t = struct2table(s,varargin)  %#codegen
%STRUCT2TABLE Convert structure array to table.

%   Copyright 2019-2020 The MathWorks, Inc.

coder.internal.assert(isstruct(s), 'MATLAB:struct2table:NotVector');
dfltDimNames = matlab.internal.coder.table.defaultDimNames;
pnames = {'RowNames' 'AsArray' 'DimensionNames'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);
pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

rownames = coder.internal.getParameterValue(pstruct.RowNames,{},varargin{:});
asArray = coder.internal.getParameterValue(pstruct.AsArray,[],varargin{:});
dimnames = coder.internal.getParameterValue(pstruct.DimensionNames,dfltDimNames,varargin{:});

% Verify that dimension names are constant
coder.internal.assert(coder.internal.isConst(dimnames), ...
                                    'MATLAB:table:NonconstantDimensionNames');

if pstruct.AsArray
    % AsArray input must be constant because it affects the dimension of
    % the output table
    coder.internal.assert(coder.internal.isConst(asArray), 'MATLAB:struct2table:NonconstantAsArray');
    asArray = matlab.internal.coder.datatypes.validateLogical(asArray,'AsArray');
    coder.internal.errorIf(~asArray && ~isscalar(s), 'MATLAB:struct2table:NonScalar');
else
    asArray = ~isscalar(s);
end


if asArray
    % Because structures grow as rows by default, don't be pedantic about
    % shape.  Accept either a row or a col.
    coder.internal.assert(isvector(s), 'MATLAB:struct2table:NotVector');
    
    varnames = fieldnames(s);
    nvars = length(varnames);
    nrows = numel(s);
    if nvars == 0 % creating a table with no variables
        % Give the output table the same number of rows as the input struct ...
        if pstruct.RowNames
            t = table('Size', [nrows 0], ...
                'RowNames', rownames, 'DimensionNames', dimnames);
        else
            t = table('Size', [nrows 0], ...
                'DimensionNames', dimnames);
        end
    else
        % Each field of S becomes a variable in T after vertcat'ing the individual
        % values along that field. container2vars ensures that the vars in its
        % output cell are all the same height.
        vars = tabular.container2vars(s);
        t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
    end
else
    if isempty(fieldnames(s)) && pstruct.RowNames
        % Size the array according to the row names
        t = table('Size', [length(rownames) 0], ...
            'RowNames', rownames, 'DimensionNames', dimnames);
    else
        t = table.fromScalarStruct(s, rownames, dimnames);
    end
    
end