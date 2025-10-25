function [pstruct,unmatched] = parseParameterInputsML(opArgs,NVPairNames,options,args)
%MATLAB Code Generation Private Function

%   Version of parseParameterInputs to be executed in MATLAB.
%   Note that instead of a varargin list, this version requires a fourth
%   input, and it must be a cell array.

%   Copyright 2009-2021 The MathWorks, Inc.
%#codegen

narginchk(4,4);
if isstruct(NVPairNames)
    pstruct = parseParameterInputsML(opArgs,fieldnames(NVPairNames),options,args);
    return
end
if ~iscell(opArgs) && ~isstruct(opArgs)
    error(message('Coder:toolbox:eml_parse_parameter_inputs_2','OpArgs'));
end
if ~iscell(NVPairNames)
    error(message( ...
        'Coder:toolbox:eml_parse_parameter_inputs_2','NVPairNames'));
end
if nargout > 1
    unmatched = false(1,numel(args));
end
OPSTRUCT = isstruct(opArgs);
if OPSTRUCT
    opArgNames = fieldnames(opArgs);
else
    opArgNames = opArgs;
end
% Create and initialize the output structure.
pstruct = makeStruct(opArgNames,NVPairNames);
% The output is now defined. If there are no inputs to parse, our work here
% is done. Leave validation of the parsing options input for when the
% options can matter.
nargs = numel(args);
if nargs == 0
    return
end
numOpArgNames = length(opArgNames);
numNVPairNames = length(NVPairNames);
% Enforce technical limitations of the implementation.
if numNVPairNames + numOpArgNames > 65535
    error(message('Coder:toolbox:eml_parse_parameter_inputs_4'));
end
if nargs > 65535
    error(message('Coder:toolbox:eml_parse_parameter_inputs_3'));
end
% Process and validate the options structure input.
[caseSensitive,partialMatch,expandStructs,ignoreNulls,supportOverrides] = ...
    processOptions(options);
% Define match functions.
[isMatch,isExactMatch] = parmMatchFunctions(caseSensitive,partialMatch);
next = uint32(1);
if numOpArgNames > 0
    % Parse optional inputs.
    jnext = uint32(1);
    for k = uint32(1):nargs
        foundopt = false;
        for j = jnext:numOpArgNames
            if isNVName(args{k},NVPairNames,isMatch)
                % Input matches an NV pair name. Stop looking for optional
                % inputs now.
                break
            elseif ~OPSTRUCT || ...
                    (isa(opArgs.(opArgNames{j}),'function_handle') && ...
                    opArgs.(opArgNames{j})(args{k}))
                foundopt = true;
                if ~ignoreNulls || ~isnull(args{k})
                    pstruct.(opArgNames{j}) = k;
                end
                jnext = j + 1;
                next(1) = k + 1;
                break
            end
        end
        if ~foundopt || jnext > numOpArgNames
            break
        end
    end
end
if next <= nargs
    % Parse name-value pairs.
    t = inputTypes(args,next);
    if t(end) == 'n'
        % Search for varargin{end} in NVPairNames.
        [~,nmatch] = findParmKernel(args{nargs},NVPairNames, ...
            isMatch,isExactMatch,partialMatch);
        if next == nargs && next <= numOpArgNames && nmatch == 0
            % We are supposed to be parsing name-value pairs at this point
            % but this is just one extra input (next == nargs). We failed
            % to match at least one optional input (next < numOpArgNames),
            % and varargin{nargs} does not appear to match any of the valid
            % parameter names. Assume this is an invalid optional input,
            % one that isn't valid and wasn't matched.
            error(message( ...
                'Coder:toolbox:UnmatchedOption',args{nargs}));
        elseif nmatch == 0
            % This is an unrecognized parameter name.
            error(message( ...
                'Coder:toolbox:UnmatchedParameter',args{nargs}));
        else
            % This is a valid parameter name without a value. It might be
            % ambiguous or redundant, but that doesn't matter.
            error(message( ...
                'Coder:toolbox:ParamMissingValue',args{nargs}));
        end
    end
    for k = next:nargs
        tk = t(k - next + 1);
        if tk == 'n' % name
            % Find the index of the field args{k} in PARMS.
            pidx = findParm(args{k},NVPairNames, ...
                isMatch,isExactMatch,caseSensitive,partialMatch);
            if pidx == 0
                if nargout < 2
                    error(message('Coder:toolbox:UnmatchedParameter',args{k}));
                else
                    unmatched(k) = true;
                    unmatched(k + 1) = true;
                end
            else
                if ~supportOverrides && pstruct.(NVPairNames{pidx}) ~= 0
                    error(message( ...
                        'Coder:toolbox:ParameterSuppliedTwice',NVPairNames{pidx}));
                end
                % The parameter value is in args{k+1}. Set the value of
                % the field in PARMS accordingly.
                if ~ignoreNulls || ~isnull(args{k+1})
                    pstruct.(NVPairNames{pidx}) = uint32(k+1);
                end
            end
        elseif expandStructs && tk == 's' % expand structure
            opStructfieldNames = fieldnames(args{k});
            nOpStructFields = length(opStructfieldNames);
            for fidx = 1:nOpStructFields
                fname = opStructfieldNames{fidx};
                % Find the index of the corresponding field in PARMS. The
                % parameter value is in the struct args{k} at field index
                % fieldidx. Set the value of the field in PARMS
                % accordingly.
                pidx = findParm(fname,NVPairNames, ...
                    isMatch,isExactMatch,caseSensitive,partialMatch);
                if pidx == 0
                    error(message('Coder:toolbox:UnmatchedParameter',fname));
                elseif ~supportOverrides && pstruct.(NVPairNames{pidx})~=0
                    error(message( ...
                        'Coder:toolbox:ParameterSuppliedTwice', ...
                        NVPairNames{pidx}));
                end
                if ~ignoreNulls || ~isnull(args{k}.(fname))
                    pstruct.(NVPairNames{pidx}) = ...
                        combineIndices(uint32(k),uint32(fidx-1));
                end
            end
        elseif tk ~= 'v'
            error(message('Coder:toolbox:ExpectedParameterName'));
        end
    end
end

%--------------------------------------------------------------------------

function [caseSensitive,partialMatch,expandStructs,ignoreNulls, ...
    supportOverrides] = processOptions(options)
% Extract parse options from options input structure, supplying default
% values if needed.
% Set defaults.
caseSensitive = false;
expandStructs = true;
partialMatch = 'n'; % none
ignoreNulls = false;
supportOverrides = true;
% Read options.
if ~isempty(options)
    if ~isstruct(options)
        error(message( 'Coder:toolbox:eml_parse_parameter_inputs_10'));
    end
    fnames = fieldnames(options);
    nfields = length(fnames);
    for k = 1:nfields
        fname = fnames{k};
        if strcmp(fname,'PartialMatching')
            % Convert PartialMatching input to a single char indicator.
            pm = options.PartialMatching;
            if isscalar(pm)
                % Legacy behavior
                if logical(pm)
                    partialMatch = 'f'; % first
                else
                    partialMatch = 'n'; % none
                end
            elseif strcmp(pm,'unique')
                partialMatch = 'u'; % unique
            elseif strcmp(pm,'first')
                partialMatch = 'f'; % first
            elseif strcmp(pm,'none')
                partialMatch = 'n'; % none
            else
                error(message( ...
                    'Coder:toolbox:eml_parse_parameter_inputs_13'));
            end
        elseif strcmp(fname,'CaseSensitivity')
            caseSensitive = options.CaseSensitivity;
            if ~islogical(caseSensitive) || ~isscalar(caseSensitive)
                error(message( ...
                    'Coder:toolbox:eml_parse_parameter_inputs_11'));
            end
        elseif strcmp(fname,'IgnoreNulls')
            ignoreNulls = options.IgnoreNulls;
            if ~islogical(ignoreNulls) || ~isscalar(ignoreNulls)
                error(message('Coder:toolbox:BadIgnoreNulls'));
            end
        elseif strcmp(fname,'StructExpand')
            expandStructs = options.StructExpand;
            if ~islogical(expandStructs) || ~isscalar(expandStructs)
                error(message( ...
                    'Coder:toolbox:eml_parse_parameter_inputs_12'));
            end
        elseif strcmp(fname,'SupportOverrides')
            supportOverrides = options.SupportOverrides;
            if ~islogical(supportOverrides) || ~isscalar(supportOverrides)
                error(message('Coder:toolbox:BadSupportOverrides'));
            end
        else
            error(message('Coder:toolbox:eml_parse_parameter_inputs_14'));
        end
    end
end

%--------------------------------------------------------------------------

function t = inputTypes(args,startIdx)
% Returns an array indicating the classification of each argument as a
% parameter name, parameter value, option structure, or unrecognized. The
% return value must be constant folded.
nargs = numel(args) - startIdx + 1;
t = blanks(nargs);
isval = false;
for k = 1:nargs
    argsk = args{k + startIdx - 1};
    if isval
        t(k) = 'v'; % value
        isval = false;
    elseif (ischar(argsk) && isrow(argsk)) || ...
            (isstring(argsk) && isscalar(argsk))
        t(k) = 'n'; % name
        isval = true;
    elseif isstruct(argsk)
        t(k) = 's'; % structure
        isval = false;
    else
        t(k) = 'u'; % unrecognized
        isval = false;
    end
end

%--------------------------------------------------------------------------

function n = findParm(parm,parms,matchFun,exactMatchFun, ...
    caseSensitive,partialMatch)
% Find the index of parm in the parms list. Asserts if parm is not found.
[n,ncandidates] = findParmKernel(parm,parms,matchFun,exactMatchFun, ...
    partialMatch);
if ncandidates > 1
    error(message( ...
        'Coder:toolbox:AmbiguousPartialMatch',parm, ...
        coder.internal.partialParameterMatchString( ...
        coder.internal.toCharIfString(parm),parms,caseSensitive)));
end

%--------------------------------------------------------------------------

function [n,ncandidates] = findParmKernel(parm,parms, ...
    isMatch,isExactMatch,partialMatch)
uPartMatch = partialMatch == 'u'; % unique partial matching
n = 0;
ncandidates = 0;
nparms = length(parms);
for j = 1:nparms
    if isMatch(parms{j},parm)
        if isExactMatch(parms{j},parm)
            % An exact match rules out all other candidates.
            n = j;
            ncandidates = 1;
            break
        elseif uPartMatch || n == 0
            n = j;
            ncandidates = ncandidates + 1;
        else
            % In this case, partialMatch == 'f', we have a first partial
            % match in hand, and we are only scanning through the rest of
            % the parameters looking for an exact match. Consequently, this
            % partial match is ignored.
        end
    end
end

%--------------------------------------------------------------------------

function [isMatch,isExactMatch] = parmMatchFunctions(casesens,prtmatch)
% Return function handles for matching of parameter names. The matchFun
% respects the casesens and prtmatch options. The exactMatchFun replaces
% prtmatch with PM_NONE (no partial matching). Note that if prtmatch is
% PM_NONE to begin with, exactMatchFun simply returns true without doing
% any work, since it is meant to be used only after detecting a match with
% matchFun.
partial = prtmatch ~= 'n';
if casesens
    if partial
        isMatch = @isCaseSensitivePartialMatch;
        isExactMatch = @isCaseSensitiveMatch;
    else
        isMatch = @isCaseSensitiveMatch;
        isExactMatch = @returnTrue;
    end
else
    if partial
        isMatch = @isCaseInsensitivePartialMatch;
        isExactMatch = @isCaseInsensitiveMatch;
    else
        isMatch = @isCaseInsensitiveMatch;
        isExactMatch = @returnTrue;
    end
end

function p = isCaseSensitivePartialMatch(mstrparm,userparm)
if isempty(userparm)
    p = false;
else
    p = strncmp(mstrparm,userparm,strlength(userparm));
end

function p = isCaseInsensitivePartialMatch(mstrparm,userparm)
if isempty(userparm)
    p = false;
else
    p = strncmpi(mstrparm,userparm,strlength(userparm));
end

function p = isCaseSensitiveMatch(mstrparm,userparm)
if isempty(userparm)
    p = false;
else
    p = strcmp(mstrparm,userparm);
end

function p = isCaseInsensitiveMatch(mstrparm,userparm)
if isempty(userparm)
    p = false;
else
    p = strcmpi(mstrparm,userparm);
end

function p = returnTrue(~,~)
p = true;

%--------------------------------------------------------------------------

function n = combineIndices(vargidx,stfldidx)
% Returns a 'uint32'. Stores the struct field index (zero-based) in the
% low bits and the varargin index in the low bits.
% n = (struct_field_ordinal << 16) + vargidx;
n = bitor(bitshift(vargidx,16),stfldidx);

%--------------------------------------------------------------------------

function p = isnull(x)
% Returns true if x is [] and fixed-size.
p = isa(x,'double') && isequal(size(x),[0,0]);

%--------------------------------------------------------------------------

function pstruct = makeStruct(opArgNames,NVPairNames)
% Convert a cell array of string scalars or char arrays to a parms
% structure.
for k = 1:length(opArgNames)
    pstruct.(opArgNames{k}) = uint32(0);
end
for k = 1:length(NVPairNames)
    pstruct.(NVPairNames{k}) = uint32(0);
end

%--------------------------------------------------------------------------

function p = isNVName(x,NVPairNames,isMatch)
p = false;
if (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))
    for k = 1:numel(NVPairNames)
        if isMatch(NVPairNames{k},x)
            p = true;
            break
        end
    end
end

%--------------------------------------------------------------------------

