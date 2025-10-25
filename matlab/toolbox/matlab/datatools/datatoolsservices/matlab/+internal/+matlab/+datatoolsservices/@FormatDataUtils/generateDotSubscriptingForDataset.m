% Generate dot subscription for datasets

% Copyright 2015-2023 The MathWorks, Inc.

function subsExpr = generateDotSubscriptingForDataset(t, subs, tname, forceNumericIndex)
    %GENERATEDOTSUBSCRIPTING create table dot-subscripting expression for code generation.
    % This function takes a dataset and a subscript that returns a single
    % variable (Any valid subscripting integer, name, logical or vartype.) Note that
    % this supports the case for creating a new variable in the dataset.

    if nargin < 4 || isempty(forceNumericIndex)
        forceNumericIndex = false;
    end

    subsExpr = tname;

    if ~isa(t,'dataset')
        error(message('MATLAB:tabular:InvalidInput'))
    end

    tempTable = internal.matlab.datatoolsservices.VariableUtils.convertDatasetToTable(t);
    ind = subscripts2indices(tempTable,subs,'assignment','varDim');
    if ~isscalar(ind)
        error(message('MATLAB:tabular:MultipleSubscripts'));
    end

    if ind > width(t) % Appending a variable
        if matlab.internal.datatypes.isText(subs)
            vname = subs;
        else
            vname = matlab.internal.tabular.defaultVariableNames(ind);
        end
        if iscell(vname), vname = vname{:}; end
    else % Existing variable
        vname = t.Properties.VarNames{ind};
    end

    if isvarname(vname)
        subsExpr = [subsExpr '.' vname];
    elseif ~isempty(find((char(vname)<=31 | char(vname)==127), 1)) ... % Non-Printing Characters or control characters use .(#)
            || forceNumericIndex
        subsExpr = [subsExpr '.(' num2str(ind) ')'];
    else % not a valid name, use t.()
        vname = strrep(vname, '''', ''''''); % Single quotes need to be escaped
        subsExpr = [subsExpr '.(''' vname ''')'];
    end
end
