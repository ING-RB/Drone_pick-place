function a = diff(a, n, dim)
%

%   Copyright 2022-2024 The MathWorks, Inc.

arguments
    a {validateTabular}
    n = 1
    dim {validateDim} = 1
end

try
    mustNotBeTabular(n,2);
    mustNotBeTabular(dim,3);
    tabular.validateTableAndDimUnary(a,dim);
    
    if isequal(dim,2)
        a = rowDiff(a,n,dim);
    else
        a = varDiff(a,n,dim);
    end
    % Check for any cross variable incompatability that could have been introduced
    % due to the type of the variables changing after the diff operation.
    % Currently, this is only required for eventtables and is a no-op for other
    % tabular types.
    a.validateAcrossVars();

catch ME
    throw(ME);
end

end

function validateTabular(a)
    if isa(a,'timetable') && ~issorted(a.rowDim.labels)
        % diff requires that timetable row times be sorted.
        error(message("MATLAB:table:math:UnsortedRowtimes",'diff'));
    end
end

function mustNotBeTabular(v, argPos)
    if isa(v,"tabular")
        error(message("MATLAB:table:math:TabularOption",argPos,class(v)));
    end
end

function validateDim(dim)
    if isnumeric(dim) && isscalar(dim) && dim > 2
        error(message("MATLAB:table:math:DiffND"));
    end
end

function a = varDiff(a, n, dim)
    if a.varDim.length == 0
        % Validate optional arguments.
        try
            diff([],n,dim);
        catch ME
            m = MException(message("MATLAB:table:math:FunFailed",'diff'));
            m = m.addCause(ME);
            throw(m);
        end
        
        % Shorten height by 1.
        if a.rowDim.length ~= 0
            a.rowDim = a.rowDim.shortenTo(max(1,a.rowDim.length-n));
        end
        return
    end

    a_data = a.data;
    for j = 1:numel(a_data)
        try
            a_data{j} = diff(a_data{j},n,dim);
        catch ME
            m = MException(message("MATLAB:table:math:VarFunFailed",'diff',a.varDim.labels{j}));
            m = m.addCause(ME);
            throw(m);
        end
    end
    [a.data,a_height] = tabular.numRowsCheck(a_data);
    a.rowDim = a.rowDim.shortenTo(a_height);
end

function a = rowDiff(a, n, dim)
    try
        inArgs = a.extractData(1:a.varDim.length);
    catch ME
        throw(ME);
    end
    if a.rowDim.length == 0
        try
            % Validate optional arguments.
            diff(inArgs,n,dim);
        catch ME
            m = MException(message("MATLAB:table:math:RowFunFailed",'diff'));
            m = m.addCause(ME);
            throw(m);
        end
        
        % Shorten width by 1.
        a.varDim = a.varDim.shortenTo(max(0,a.varDim.length-n));
        return
    end

    try
        a_data = num2cell(diff(inArgs,n,dim),1);
    catch ME
        m = MException(message("MATLAB:table:math:RowFunFailed",'diff'));
        m = m.addCause(ME);
        throw(m);
    end
    if isempty(a_data)
        a_data = cell(1,0);
    end
    a.data = a_data;
    a.varDim = a.varDim.shortenTo(numel(a_data));
end
