function out = validatestring( varargin )
    narginchk(2,5);

    try
        [in, validStrings, optional_inputs] = checkInputs(varargin);
    catch e
        % only VALIDATESTRING should be on the stack
        throw(e)
    end

    try    
        % check the contents of IN
        out = checkString(in, validStrings, optional_inputs);

    catch e
        myId = 'MATLAB:validatestring:';
        if strncmp(myId, e.identifier, length(myId))
            % leave VALIDATESTRING on the stack, because there was a misuse
            % of VALIDATESTRING itself
            throw(e)
        else
            % strip VALIDATESTRING off the stack so that the error looks like
            % it comes from the caller just as if it had hand-coded its input checking
            throwAsCaller( e )
        end
    end
end

function out = checkString( in, validStrings, optional_inputs )

    if isstring(validStrings) && any(ismissing(validStrings))
        throwError(optional_inputs, 'missingValueStringList', 'unrecognizedStringChoice');
    end

    try
        if ~(ischar(in) && strcmp(in,''))
            validateattributes(in, {'char', 'string'}, {'scalartext'});
        end
    catch e
        me = createValidateattributesException(validStrings, optional_inputs,e);
        throwAsCaller(me);
    end

    % do a case insensitive search, but use the case from validStrings,
    % not the case from the input
    
    if isstring(in) && ismissing(in)
        out={};
    else
        in_char = char(in);
        if isempty(in_char)
            out = validStrings(ismember(validStrings,in_char));
        else
            out = validStrings(strncmpi(in_char, validStrings, numel(in_char)));
        end
    end

    if isscalar(out)
        if iscell(out)
            out = out{1};
        end
    elseif numel(out) > 1
        % possibly ambiguous match

        % determine if all the matching strings are substrings of each other
        [shortestMatchLength, shortestMatchIdx] = min(cellfun('length', cellstr(out)));
        
        shortestMatch = out{shortestMatchIdx};
        allSubstrings = all(strncmpi(shortestMatch, out, shortestMatchLength));

        if allSubstrings
            % return the shortest match
            if iscellstr(out)
                out = shortestMatch;
            else
                out = string(shortestMatch);
            end
        else
            throwErrorWithArgDescriptor(in, validStrings, optional_inputs, 'ambiguousStringChoice', 'ambiguousStringChoice');
        end
    else
        if ismissing(in)
            throwError(optional_inputs, 'missingValueInputString', 'unrecognizedStringChoice');
        else
            throwErrorWithArgDescriptor(in, validStrings, optional_inputs, 'unrecognizedStringChoice3', 'unrecognizedStringChoice');
        end 
    end
end

function throwError(optional_inputs, catalogID, mnemonic)

	fname = matlab.internal.validators.generateArgumentDescriptor(optional_inputs, 'validatestring' );

    msg = getString(message(['MATLAB:validatestring:' catalogID]));

    error(matlab.internal.validators.generateId(fname, mnemonic), '%s', msg);
end

function throwErrorWithArgDescriptor(in, validStrings, optional_inputs, catalogID, mnemonic)

    [fname, msgId, argname, argpos] = matlab.internal.validators.generateArgumentDescriptor(optional_inputs, 'validatestring');

    argDes = matlab.internal.validators.getArgumentDescriptor(msgId, argname, argpos);
    
    msg = getString(message(['MATLAB:validatestring:' catalogID], argDes, createCommaSeparatedText(validStrings), in));

    error(matlab.internal.validators.generateId(fname, mnemonic), '%s', msg);
end

function me = createValidateattributesException(validStrings, optional_inputs, e)

    [fname, msgId, argname, argpos] = matlab.internal.validators.generateArgumentDescriptor(optional_inputs, 'validatestring');
    
    argDes = matlab.internal.validators.getArgumentDescriptor(msgId, argname, argpos);
    
    msg = getString(message('MATLAB:validatestring:unrecognizedStringChoice2', argDes, createCommaSeparatedText(validStrings)));
    
    me = MException(matlab.internal.validators.generateId(fname, 'unrecognizedStringChoice' ), '%s', msg);
    me = me.addCause(e);
end

function s = createCommaSeparatedText(validStrings)

    if isempty(validStrings)
        s = '';
        return
    end

    s = sprintf( '''%s'', ', validStrings{:});
    if ~isempty(s)
        s(end-1:end) = [];
    end
end

function [in, validStrings, inputs] = checkInputs(inputs)
     
    in = inputs{1};
    validStrings = inputs{2};

    if ~iscellstr(validStrings) && ~isstring(validStrings)
        error(message('MATLAB:validatestring:invalidStringList'))
    end

    inputs(1:2) = [];
end

%   Copyright 1993-2021 The MathWorks, Inc.
