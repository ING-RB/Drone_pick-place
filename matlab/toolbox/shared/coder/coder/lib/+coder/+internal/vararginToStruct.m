function s = vararginToStruct(pstruct,default,varargin)
%MATLAB Code Generation Private Function
%
%   Fetches input values from varargin using the output of
%   coder.internal.parseInputs or coder.internal.parseParameterInputs.
%
%   If default is a structure, it must have the same field names as
%   pstruct. If it is anything else, it will be assigned in whole as the
%   value for members in s for which inputs are not supplied in varargin.
%
%   In MATLAB execution the output s is a true struct. In code generation
%   it is a stickyStruct in order to preserve constness of members. If a
%   true structure is needed, it can be produced by struct(s).

%   Copyright 2009-2021 The MathWorks, Inc.
%#codegen

coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
narginchk(2,inf);
% coder.internal.isCompiled == ~isempty(coder.target) except during
% interpreted coverage testing, where it returns false regardless of what
% coder.target returns. This is important here because stickyStructs don't
% work properly in interpreted MATLAB execution.
if coder.internal.isCompiled
    coder.inline('always');
    coder.internal.prefer_const(pstruct,default);
    ZERO = coder.internal.indexInt(0);
    s = populateStickyStruct(coder.internal.stickyStruct.parse(), ...
        pstruct,default,ZERO,varargin{:});
else
    s = populateStructML(pstruct,default,varargin);
end

%--------------------------------------------------------------------------

function s = populateStructML(pstruct,default,args)
% Populate a structure with input values. MATLAB execution.
DEFAULTS = isstruct(default);
fn = fieldnames(pstruct);
s = struct();
U65535 = uint32(intmax('uint16'));
for k = 1:length(fn)
    % Streamlined coder.internal.getParameterValue.
    idx = pstruct.(fn{k});
    if idx == 0
        if DEFAULTS
            s.(fn{k}) = default.(fn{k});
        else
            s.(fn{k}) = default;
        end
    elseif idx < U65535
        s.(fn{k}) = args{idx};
    else
        vidx = bitshift(idx,-16);
        ss = args{vidx};
        fidx = bitand(idx,U65535);
        names = fieldnames(ss);
        fname = names{fidx+1};
        s.(fn{k}) = ss.(fname);
    end
end

%--------------------------------------------------------------------------

function [esOut,k] = populateStickyStruct(esIn,pstruct,default,k,varargin)
% Recursively populate stickyStruct's members with input values.
coder.inline('always');
coder.internal.allowEnumInputs;
coder.internal.prefer_const(pstruct,default,k);
DEFAULTS = isstruct(default);
fn = coder.const(fieldnames(pstruct));
nv = coder.const(coder.internal.indexInt(numel(fn)));
if k < nv
    k = coder.const(k + 1);
    if DEFAULTS
        defaultValue = default.(fn{k});
    else
        defaultValue = default;
    end
    value = coder.internal.getParameterValue( ...
        pstruct.(fn{k}),defaultValue,varargin{:});
    [esOut,k] = populateStickyStruct( ...
        set(esIn,fn{k},value), ...
        pstruct,default,k,varargin{:});
else
    esOut = esIn;
end

%--------------------------------------------------------------------------
