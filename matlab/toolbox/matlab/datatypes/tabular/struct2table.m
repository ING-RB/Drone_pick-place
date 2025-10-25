function t = struct2table(s,varargin)  %#codegen
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    t = matlab.internal.coder.struct2table(s, varargin{:});
    return
end

if ~isstruct(s)
    error(message('MATLAB:struct2table:NotVector'));
end

if nargin == 1
    rownames = {};
    supplied.RowNames = false;
    supplied.DimensionNames = false;
    supplied.AsArray = false;
else
    pnames = {'RowNames' 'DimensionNames' 'AsArray'};
    dflts =  {       {}               {}        [] };
    [rownames,dimnames,asArray,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
end

if supplied.AsArray
    asArray = matlab.internal.datatypes.validateLogical(asArray,'AsArray');
    if ~asArray && ~isscalar(s)
        error(message('MATLAB:struct2table:NonScalar'));
    end
else
    asArray = ~isscalar(s);
end

if asArray
    % Because structures grow as rows by default, don't be pedantic about
    % shape.  Accept either a row or a col.
    if ~isvector(s) && ~isempty(s)
        error(message('MATLAB:struct2table:NotVector'));
    end
    
    varnames = fieldnames(s);
    nvars = length(varnames);
    nrows = numel(s);
    
    if nvars == 0
        % Performant special case to create an Nx0 empty table.
        t = table.empty(nrows,0);
        if supplied.RowNames, t.Properties.RowNames = rownames; end
        if supplied.DimensionNames, t.Properties.DimensionNames = dimnames; end
    else
        % Each field of S becomes a variable in T after vertcat'ing the individual
        % values along that field. container2vars ensures that the vars in its
        % output cell are all the same height.
        vars = tabular.container2vars(s); % structArray -> cellVector
        if supplied.DimensionNames
            t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
        else
            t = table.init(vars,nrows,rownames,nvars,varnames);
        end
    end
else
    if isempty(fieldnames(s)) && supplied.RowNames
        % Size the array according to the row names
        t = table.empty(length(rownames),0);
        if supplied.DimensionNames, t.Properties.DimensionNames = dimnames; end
    else
        try %#ok<EMTC> 
            if supplied.DimensionNames
                t = table.fromScalarStruct(s,rownames,dimnames);
            else
                t = table.fromScalarStruct(s,rownames); 
            end
        catch ME
            matlab.internal.datatypes.throwInstead(ME,'MATLAB:table:UnequalFieldLengths',message('MATLAB:struct2table:UnequalFieldLengths'));
        end
    end
end
