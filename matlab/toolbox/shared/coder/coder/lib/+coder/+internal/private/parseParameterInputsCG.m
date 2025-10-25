function [pstruct,unmatched] = parseParameterInputsCG(opArgs,NVPairNames,options,varargin)
%MATLAB Code Generation Private Function

%   Version of parseInputs to be executed by the codegen constant-folder.

%   Copyright 2009-2022 The MathWorks, Inc.
%#codegen

coder.inline('always');
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
narginchk(3,inf);
coder.internal.prefer_const(opArgs,NVPairNames,options);
unmatched = false(1,nargin - 3);
if isstruct(NVPairNames)
    pstruct = parseParameterInputsCG(opArgs, ...
        coder.const(fieldnames(NVPairNames)),options,varargin{:});
    return
end
coder.internal.assert(iscell(opArgs) || isstruct(opArgs), ...
    'Coder:toolbox:eml_parse_parameter_inputs_2','OpArgs');
coder.internal.assert(iscell(NVPairNames), ...
    'Coder:toolbox:eml_parse_parameter_inputs_2','NVPairNames');
[caseSensitive,partialMatch,expandStructs,ignoreNulls,supportOverrides] = ...
    coder.const(@processOptions,options);
[isMatch,isExactMatch] = coder.const(@parmMatchFunction, ...
    caseSensitive,partialMatch);
OPSTRUCT = isstruct(opArgs);
if OPSTRUCT
    opArgNames = fieldnames(opArgs);
else
    opArgNames = opArgs;
end
numOpArgNames = coder.const(length(opArgNames));
numNVPairNames = coder.const(length(NVPairNames));
nargs = coder.const(numel(varargin));
% These are technical limitations of this implementation, so we check them
% here, regardless of whether another limitation may make them impossible
% to violate.
coder.internal.assert(nargs <= 65535, ...
    'Coder:toolbox:eml_parse_parameter_inputs_3', ...
    'IfNotConst','Fail');
coder.internal.assert(numNVPairNames + numOpArgNames <= 65535, ...
    'Coder:toolbox:eml_parse_parameter_inputs_4', ...
    'IfNotConst','Fail');
% Create and initialize the output structure.
pstruct = coder.const(makeStruct(opArgNames,NVPairNames));
next = uint32(1);
if nargs > 0 && numOpArgNames > 0
    % Parse optional inputs.
    jnext = uint32(1);
    coder.unroll;
    for k = uint32(1):nargs
        foundopt = false;
        coder.unroll;
        for j = jnext:numOpArgNames
            if coder.const(isNVName(varargin{k},NVPairNames,isMatch))
                % Input matches an NV pair name. Stop looking for optional
                % inputs now.
                break
            elseif OPSTRUCT && isa(opArgs.(opArgNames{j}),'function_handle')
                isOpt = opArgs.(opArgNames{j})(varargin{k});
                if coder.internal.isConstTrue(isOpt)
                    foundopt = true;
                    if coder.const(~ignoreNulls || ~isnull(varargin{k}))
                        pstruct.(opArgNames{j}) = k;
                    end
                    jnext = j + 1;
                    next(1) = k + 1;
                    break
                end
            else
                foundopt = true;
                if coder.const(~ignoreNulls || ~isnull(varargin{k}))
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
    % If there is just one more input (next == nargs), it is a non-constant
    % text row, and we have not matched all optional inputs, issue an error
    % message that assumes it is an unmatched optional input rather than a
    % parameter name without a value. If varargin{nargs} is a constant, we
    % will handle it later because we'll first want to check whether it
    % matches any valid parameter names.
    coder.internal.assert(next ~= nargs || next > numOpArgNames || ...
        ~coder.internal.isTextRow(varargin{nargs}) || ...
        coder.internal.isConst(varargin{nargs}), ...
        'Coder:toolbox:UnmatchedOption',varargin{nargs});
end
if next <= nargs
    % Parse name-value pairs.
    if ~supportOverrides
        assigned = false(numNVPairNames,1);
    end
    t = coder.const(inputTypes(varargin{next:end}));
    if t(end) == 'n'
        % Search for varargin{end} in NVPairNames.
        [~,nmatch] = findParmKernel(varargin{nargs}, ...
            NVPairNames,isMatch,isExactMatch,partialMatch);
        % Check whether to treat this as an unmatched optional input.
        coder.internal.errorIf(next <= numOpArgNames && nmatch == 0, ...
            'Coder:toolbox:UnmatchedOption',varargin{nargs});
        % Check whether this is an unrecognized parameter name.
        coder.internal.errorIf(nmatch == 0, ...
            'Coder:toolbox:UnmatchedParameter',varargin{nargs});
        % This is a valid parameter name without a value. It might be
        % ambiguous or redundant, but that doesn't matter.
        coder.internal.assert(false, ...
            'Coder:toolbox:ParamMissingValue', ...
            varargin{nargs});
    end
    coder.unroll;
    for k = next:nargs
        tk = t(k - next + 1);
        if coder.const(tk == 'n') % name
            % Find the index of the field varargin{k} in PARMS.
            pidx = coder.const(findParm(varargin{k},NVPairNames, ...
                isMatch,isExactMatch,caseSensitive,partialMatch));
            if pidx == 0
                coder.internal.assert(nargout > 1, ...
                    'Coder:toolbox:UnmatchedParameter',varargin{k});
                unmatched(k) = true;
                unmatched(k + 1) = true;
            else
                if ~supportOverrides
                    coder.internal.assert(~assigned(pidx), ...
                        'Coder:toolbox:ParameterSuppliedTwice', ...
                        NVPairNames{pidx},'IfNotConst','Fail');
                    assigned(pidx) = true;
                end
                % The parameter value is in varargin{k+1}. Set the value of
                % the field in PARMS accordingly.
                if coder.const(~ignoreNulls || ~isnull(varargin{k+1}))
                    pstruct.(NVPairNames{pidx}) = coder.const(uint32(k+1));
                end
            end
        elseif coder.const(expandStructs && coder.const(tk == 's')) % struct
            coder.unroll;
            for fieldidx = 0:eml_numfields(varargin{k})-1
                fname = eml_getfieldname(varargin{k},fieldidx);
                % Find the index of the corresponding field in PARMS.
                pidx = coder.const(findParm(fname,NVPairNames,...
                    isMatch,isExactMatch,caseSensitive,partialMatch));
                coder.internal.assert(pidx > 0, ...
                    'Coder:toolbox:UnmatchedParameter',fname);
                if ~supportOverrides
                    coder.internal.assert(~assigned(pidx), ...
                        'Coder:toolbox:ParameterSuppliedTwice', ...
                        NVPairNames{pidx},'IfNotConst','Fail');
                    assigned(pidx) = true;
                end
                if coder.const(~ignoreNulls || ~isnull(varargin{k}.(fname)))
                    % The parameter value is in the struct varargin{k} at
                    % field index fieldidx. Set the value of the field
                    % in PARMS accordingly.
                    pstruct.(NVPairNames{pidx}) = coder.const( ...
                        combineIndices(uint32(k),uint32(fieldidx)));
                end
            end
        else
            % Last entry must be a value if it is not a structure.
            coder.internal.assert(tk == 'v', ...
                'Coder:toolbox:ExpectedParameterName', ...
                'IfNotConst','Fail');
        end
    end
end

%--------------------------------------------------------------------------

function [caseSensitive,partialMatch,expandStructs,ignoreNulls, ...
    supportOverrides] = processOptions(options)
% Extract parse options from options input structure, supplying default
% values if needed.
coder.internal.allowEnumInputs;
coder.internal.prefer_const(options);
coder.internal.assert(coder.internal.isConst(options), ...
    'Coder:toolbox:eml_parse_parameter_inputs_9', ...
    'IfNotConst','Fail');
% Set defaults.
caseSensitive = false;
expandStructs = true;
partialMatch = 'n'; % none
ignoreNulls = false;
supportOverrides = true;
% Read options.
if ~isempty(options)
    coder.internal.assert(isstruct(options), ...
        'Coder:toolbox:eml_parse_parameter_inputs_10', ...
        'IfNotConst','Fail');
    fnames = coder.const(fieldnames(options));
    nfields = coder.const(length(fnames));
    coder.unroll;
    for k = 1:nfields
        fname = fnames{k};
        if coder.const(strcmp(fname,'CaseSensitivity'))
            coder.internal.assert(isscalar(options.CaseSensitivity) && ...
                islogical(options.CaseSensitivity), ...
                'Coder:toolbox:eml_parse_parameter_inputs_11', ...
                'IfNotConst','Fail');
            caseSensitive = coder.const(options.CaseSensitivity);
        elseif coder.const(strcmp(fname,'StructExpand'))
            coder.internal.assert(isscalar(options.StructExpand) && ...
                islogical(options.StructExpand), ...
                'Coder:toolbox:eml_parse_parameter_inputs_12', ...
                'IfNotConst','Fail');
            expandStructs = coder.const(options.StructExpand);
        elseif coder.const(strcmp(fname,'PartialMatching'))
            isfirst = strcmp(options.PartialMatching,'first') || ( ...
                isscalar(options.PartialMatching) && ...
                options.PartialMatching ~= false);
            isnone = strcmp(options.PartialMatching,'none') || ( ...
                isscalar(options.PartialMatching) && ...
                options.PartialMatching == false);
            isunique = strcmp(options.PartialMatching,'unique');
            coder.internal.assert(isfirst || isnone || isunique, ...
                'Coder:toolbox:eml_parse_parameter_inputs_13', ...
                'IfNotConst','Fail');
            if isunique
                partialMatch = 'u'; % unique
            elseif isfirst
                partialMatch = 'f'; % first
            else
                partialMatch = 'n'; % none
            end
        elseif coder.const(strcmp(fname,'IgnoreNulls'))
            coder.internal.assert(isscalar(options.IgnoreNulls) && ...
                islogical(options.IgnoreNulls), ...
                'Coder:toolbox:BadIgnoreNulls', ...
                'IfNotConst','Fail');
            ignoreNulls = coder.const(options.IgnoreNulls);
        elseif coder.const(strcmp(fname,'SupportOverrides'))
            coder.internal.assert(isscalar(options.SupportOverrides) && ...
                islogical(options.SupportOverrides), ...
                'Coder:toolbox:BadSupportOverrides', ...
                'IfNotConst','Fail');
            supportOverrides = coder.const(options.SupportOverrides);
        else
            coder.internal.assert(false, ...
                'Coder:toolbox:eml_parse_parameter_inputs_14', ...
                'IfNotConst','Fail');
        end
    end
end

%--------------------------------------------------------------------------

function t = inputTypes(varargin)
% Returns an array indicating the classification of each argument as a
% parameter name, parameter value, option structure, or unrecognized. The
% return value must be constant folded.
coder.internal.allowEnumInputs;
t = coder.nullcopy(char(zeros(nargin,1)));
isval = false;
coder.unroll;
for k = 1:nargin
    if isval
        t(k) = 'v'; % value
        isval = false;
    elseif coder.internal.isTextRow(varargin{k})
        coder.internal.assert(coder.internal.isConst(varargin{k}), ...
            'Coder:toolbox:ParameterNamesMustBeConstant', ...
            'IfNotConst','Fail');
        t(k) = 'n'; % name
        isval = true;
    elseif isstruct(varargin{k})
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
coder.inline('always');
coder.internal.prefer_const(parm,parms,matchFun,exactMatchFun, ...
    caseSensitive,partialMatch);
[n,ncandidates] = findParmKernel(parm,parms,matchFun,exactMatchFun, ...
    partialMatch);
if ncandidates > 1
    coder.internal.assert(false, ...
        'Coder:toolbox:AmbiguousPartialMatch',parm, ...
        coder.const(feval('coder.internal.partialParameterMatchString', ...
        coder.internal.toCharIfString(parm),parms,caseSensitive)));
end

%--------------------------------------------------------------------------

function [n,ncandidates] = findParmKernel(parm,parms,isMatch, ...
    isExactMatch,partialMatch)
coder.inline('always');
coder.internal.prefer_const(parm,parms,isMatch,isExactMatch,partialMatch);
uPartMatch = partialMatch == 'u'; % unique partial matching
n = 0;
ncandidates = 0;
nparms = coder.const(length(parms));
for j = 1:nparms
    if coder.const(isMatch(parms{j},parm))
        if coder.const(isExactMatch(parms{j},parm))
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

function [isMatch,isExactMatch] = parmMatchFunction(casesens,prtmatch)
% Return function handles for matching of parameter names. The matchFun
% respects the casesens and prtmatch options. The exactMatchFun replaces
% prtmatch with PM_NONE (no partial matching). Note that if prtmatch is
% PM_NONE to begin with, exactMatchFun simply returns true without doing
% any work, since it is meant to be used only after detecting a match with
% matchFun.
coder.internal.prefer_const(casesens,prtmatch);
partial = coder.const(prtmatch ~= 'n');
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
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm);
if coder.const(isempty(userparm))
    p = false;
else
    p = coder.const(strncmp(mstrparm,userparm,strlength(userparm)));
end

function p = isCaseInsensitivePartialMatch(mstrparm,userparm)
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm);
if coder.const(isempty(userparm))
    p = false;
else
    p = coder.const(strncmpi(mstrparm,userparm,strlength(userparm)));
end

function p = isCaseSensitiveMatch(mstrparm,userparm)
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm);
if coder.const(isempty(userparm))
    p = false;
else
    p = coder.const(strcmp(mstrparm,userparm));
end

function p = isCaseInsensitiveMatch(mstrparm,userparm)
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm);
if coder.const(isempty(userparm))
    p = false;
else
    p = coder.const(strcmpi(mstrparm,userparm));
end

function p = returnTrue(mstrparm,userparm)
coder.inline('always');
coder.internal.prefer_const(mstrparm,userparm);
p = true;

%--------------------------------------------------------------------------

function n = combineIndices(vargidx,stfldidx)
% Returns a 'uint32'. Stores the struct field index (zero-based) in the
% low bits and the varargin index in the low bits.
% n = (struct_field_ordinal << 16) + vargidx;
coder.internal.prefer_const(vargidx,stfldidx);
n = coder.const(eml_bitor(eml_lshift(vargidx,int8(16)),stfldidx));

%--------------------------------------------------------------------------

function p = isnull(x)
% Returns true if x is [] and fixed-size.
coder.inline('always');
p = coder.const(isa(x,'double') && coder.internal.isConst(size(x)) && ...
    isequal(size(x),[0,0]));

%--------------------------------------------------------------------------

function pstruct = makeStruct(opArgNames,NVPairNames)
% Convert a cell array of string scalars or char arrays to a parms
% structure.
coder.internal.prefer_const(opArgNames,NVPairNames);
coder.internal.assert(coder.internal.isConst(opArgNames), ...
    'Coder:toolbox:InputMustBeConstant','opArgs');
coder.internal.assert(coder.internal.isConst(NVPairNames), ...
    'Coder:toolbox:InputMustBeConstant','NVPairNames');
coder.unroll;
for k = 1:length(opArgNames)
    coder.internal.assert(coder.internal.isTextRow(opArgNames{k}), ...
        'MATLAB:mustBeFieldName');
    pstruct.(opArgNames{k}) = uint32(0);
end
coder.unroll;
for k = 1:length(NVPairNames)
    coder.internal.assert(coder.internal.isTextRow(NVPairNames{k}), ...
        'MATLAB:mustBeFieldName');
    pstruct.(NVPairNames{k}) = uint32(0);
end

%--------------------------------------------------------------------------

function p = isNVName(x,NVPairNames,isMatch)
coder.internal.prefer_const(NVPairNames,isMatch)
p = false;
if coder.internal.isConst(x) && coder.internal.isTextRow(x)
    coder.internal.prefer_const(x);
    coder.unroll;
    for k = 1:numel(NVPairNames)
        if coder.const(isMatch(NVPairNames{k},x))
            p = true;
            break
        end
    end
end

%--------------------------------------------------------------------------
