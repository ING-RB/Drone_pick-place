function b = addvars(a,varargin) %#codegen
%ADDVARS Add variables to table or timetable.

%   Copyright 2020-2023 The MathWorks, Inc.

if (nargin == 1)
    b = a;
else
    numNamedArguments = matlab.lang.internal.countNamedArguments();
    numVars = tabular.countVarInputs(varargin,numNamedArguments);
    pnames = {'NewVariableNames'  'Before'           'After' };
    poptions = struct('CaseSensitivity', false, ...
        'PartialMatching', 'unique', ...
        'StructExpand',    false);
    % parseParameterInputs allows string param names, but they are not supported
    % in addvars, so scan the parameter names beforehand and error if necessary.
    for i = numVars+1:2:(length(varargin) - 2*numNamedArguments)
        pname = varargin{i};
        % Missing string is not supported in codegen, so no need to check for
        % that.
        coder.internal.errorIf(isstring(pname) && isscalar(pname),...
            'MATLAB:table:addmovevars:StringParamNameNotSupported',pname);
    end
    supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{numVars+1:end});

    % NewVariableNames must be specified if adding any new variabe -- default names are not supported
    coder.internal.assert( supplied.NewVariableNames~=0, 'MATLAB:table:addmovevars:MustSpecifyNewVarNames');
    newvarnames = coder.internal.getParameterValue(supplied.NewVariableNames, [], varargin{numVars+1:end});

    % Either _none_ or exactly _one_ of BEFORE or AFTER (not both)
    coder.internal.errorIf(supplied.After && supplied.Before, 'MATLAB:table:addmovevars:BeforeAndAfter');
    before      = coder.internal.getParameterValue(supplied.Before,             [], varargin{numVars+1:end});
    after       = coder.internal.getParameterValue(supplied.After, a.varDim.length, varargin{numVars+1:end});
    coder.internal.assert(coder.internal.isConst(size(before)) && coder.internal.isConst(size(after)), ...
        'MATLAB:table:addmovevars:NoVarSizeBeforeAndAfter')

    % NewVariableNames must be text, constant, and same length as NewVariables
    newvarnames = convertStringsToChars(newvarnames);
    [isNewVarNamestext,newvarnames] = matlab.internal.coder.datatypes.isText(newvarnames);
    
    coder.internal.assert(isNewVarNamestext, 'MATLAB:table:addmovevars:InvalidVarNames');
    coder.internal.assert(coder.internal.isConst(newvarnames), 'MATLAB:table:addmovevars:NewVarNamesMustBeConstant');
    coder.internal.assert(length(newvarnames) == numVars,'MATLAB:table:addmovevars:IncorrectNumberOfVarNames')

    % New vars cannot clash with a's dim names. We know they don't if we
    % create them. Only check when user-supplied.
    a.metaDim.checkAgainstVarLabels(newvarnames,'error');

    % Adding no variables is a no-op. Do this after going through newvarnames
    % to provide a helpful error if numVars differs from number of newvarnames.
    if numVars > 0
        % Compute locations of new variables. Support edge cases of 'After' 0 and
        % 'Before' width(t)+1 which could be hit programmatically by empty tables.
        if ~supplied.Before && isnumeric(after) && isscalar(after) && after == 0 % 'After', 0 becomes 'Before', 1
            addIndex = 1;
            supplied.Before = ones(1,'like',supplied.Before);
            supplied.After = zeros(1,'like',supplied.After);
        elseif supplied.Before && isnumeric(before) && isscalar(before) && before == a.varDim.length + 1
            if a.varDim.length ~= 0 % non-empty table: 'After', width(t)
                addIndex = before - 1;
                supplied.Before = zeros(1,'like',supplied.Before);
                supplied.After = ones(1,'like',supplied.After);
            else % empty table: 'Before', 1
                addIndex = 1;
            end
        else
            if supplied.Before
                pos = before;
            else
                pos = after;
            end

            coder.internal.errorIf(isa(pos,'vartype'),'MATLAB:table:addmovevars:InvalidLocation','vartype subscripter');
            addIndex = a.varDim.subs2inds(pos);
        end

        % Append a new tabular containing new variables at the end, and move to
        % speicified location using MOVEVARS. If the number of rows in the new
        % variables do not match the height of the input tabular, then throw a
        % helpful error. Rely on HORZCAT to catch other potential errors like
        % duplicates between a.varDim.labels and newvarnames - no explicit check
        % is needed for those.
        coder.internal.assert(...
               (islogical(addIndex) && isvector(addIndex) && ...
                sum(addIndex)==1 && length(addIndex) == width(a))...
            || ...
                (isnumeric(addIndex) && isscalar(addIndex)),...
            'MATLAB:table:addmovevars:NonscalarPosition')

        % Only check the heights for the first variable, countVarInputs ensures
        % that others have the same height.
        coder.internal.assert(size(varargin{1},1) == height(a),...
            'MATLAB:table:addmovevars:NumRowsMismatch');

        if supplied.Before
            posFlag = 'Before';
        else
            posFlag = 'After';
        end

        newvarlen = a.varDim.length+numVars;
        b_varDim = lengthenTo(a.varDim,newvarlen,newvarnames);
        b_data = matlab.internal.coder.datatypes.cellvec_concat(...
            a.data,varargin,a.varDim.length,numVars);
        btemp = updateTabularProperties(a, b_varDim, [], [], [], b_data);
        b = movevars(btemp ,...
            (1:numVars)+a.varDim.length,... % Location of new variables in the concatenated tabular
            posFlag, addIndex);
    else
        b = a;
    end
end
