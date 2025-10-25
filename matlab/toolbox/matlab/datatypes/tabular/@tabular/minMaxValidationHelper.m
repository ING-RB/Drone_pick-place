function isBinary = minMaxValidationHelper(nout, fun, funName, a, args)
%

% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Helper for min and max input validation.

%   Copyright 2022-2024 The MathWorks, Inc.

isBinary = isscalar(args) || ~( isempty(args) || isequal(args{1},[]) );
if isBinary
    if nout > 1
        throwAsCaller(MException(message("MATLAB:maxlhs")));
    end
    b = args{1};
    if isa(a,"tabular") && a.varDim.length == 0 || isa(b,"tabular") && b.varDim.length == 0
        % Force validation of a or b and optional arguments since
        % binaryFunHelper does not call fun when a or b has no variables.

        % Replace a and/or b with a non-tabular placeholder to avoid
        % infinite recursion.
        if isa(a,"tabular")
            a = 0;
        end
        if isa(b,"tabular")
            b = 0;
        end
        try
            [vout{1:nout}] = fun(a,b,args{2:end}); %#ok<NASGU>
        catch ME
            m = MException(message("MATLAB:table:math:FunFailed",funName));
            m = m.addCause(ME);
            throwAsCaller(m);
        end
    end
end
if numel(args) > 1
    if nout == 2 && strcmpi(args{2},'all')
        throwAsCaller(MException(message("MATLAB:table:math:MinMaxAllLinearIndices",funName)));
    end
    if strcmpi(args{end},'linear')
        throwAsCaller(MException(message("MATLAB:table:math:MinMaxLinearIndices")));
    end
end
