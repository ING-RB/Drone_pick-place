function t = cell2table(c,varargin)  %#codegen
%

%   Copyright 2012-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    t = matlab.internal.coder.cell2table(c, varargin{:});
    return
end

if ~iscell(c) || ~ismatrix(c)
    error(message('MATLAB:cell2table:NDCell'));
end
[nrows,nvars] = size(c);

if nargin == 1
    rownames = {};
    supplied.VariableNames = false;
    supplied.RowNames = false;
    supplied.DimensionNames = false;
else
    pnames = {'VariableNames' 'RowNames' 'DimensionNames' };
    dflts =  {            {}         {}               {}  };
    [varnames,rownames,dimnames,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
end

if ~supplied.VariableNames && (nvars > 0) % skip nvars==0 for performance
    baseName = inputname(1);
    if isempty(baseName)
        varnames = matlab.internal.tabular.defaultVariableNames(1:nvars);
    else
        if nvars == 1
            varnames = {baseName};
        else
            varnames = matlab.internal.datatypes.numberedNames(baseName,1:nvars);
        end
    end
end

if nvars == 0
    % Performant special case to create an Nx0 empty table.
    t = table.empty(nrows,0);
    % Assign the supplied var names just to check for the correct number (zero) and
    % throw a consistent error. No need to check for conflicts with dim names.
    if supplied.VariableNames, t.Properties.VariableNames = varnames; end
    if supplied.RowNames, t.Properties.RowNames = rownames; end
    if supplied.DimensionNames, t.Properties.DimensionNames = dimnames; end
else
    % Each column of C becomes a variable in T. container2vars ensures that the vars
    % in its output cell are all the same height.
    vars = tabular.container2vars(c); % cellArray -> cellVector
    if supplied.DimensionNames
        t = table.init(vars,nrows,rownames,nvars,varnames,dimnames);
    else
        t = table.init(vars,nrows,rownames,nvars,varnames);
    end
end
