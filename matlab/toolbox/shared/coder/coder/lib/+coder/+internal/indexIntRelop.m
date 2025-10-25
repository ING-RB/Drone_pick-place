function p = indexIntRelop(relop,a,b)
%MATLAB Code Generation Private Function

%   Copyright 2011-2019 The MathWorks, Inc.
%#codegen

coder.inline('always');
coder.internal.allowHalfInputs;
coder.internal.assert(nargin == 3, ...
    'MATLAB:minrhs');
coder.internal.prefer_const(relop);
coder.internal.assert(coder.internal.isConst(relop) && ischar(relop), ...
    'Coder:toolbox:indexIntRelop_unrecognizedRelop');
isIndexInta = isa(a,indexIntClass);
isIndexIntb = isa(b,indexIntClass);
coder.internal.assert(isIndexInta || isIndexIntb, ...
    'Coder:toolbox:indexIntRelop_neitherIsIndexInt');
coder.internal.assert(~(isIndexInta && isIndexIntb), ...
    'Coder:toolbox:indexIntRelop_bothAreIndexInt');
coder.internal.assert(is_supported(a), ...
    'Coder:toolbox:indexIntRelop_unsupportedInput',class(a));
coder.internal.assert(is_supported(b), ...
    'Coder:toolbox:indexIntRelop_unsupportedInput',class(b));
if isfloat(a) || isfloat(b)
    p = apply_float_relop(relop,a,b);
else
    p = apply_integer_relop(relop,a,b);
end

%--------------------------------------------------------------------------

function p = is_supported(x)
p = isa(x,indexIntClass) || ...
    isa(x,'int8') || ...
    isa(x,'int16') || ...
    isa(x,'int32') || ...
    isa(x,'int64') || ...
    isa(x,'uint8') || ...
    isa(x,'uint16') || ...
    isa(x,'uint32') || ...
    isa(x,'uint64') || ...
    isa(x,'single') || ...
    isa(x,'double') || ...
    isa(x,'half');

%--------------------------------------------------------------------------

function p = apply_integer_relop(relop,a1,b1)
% Evaluate (a1 relop b1) for integers a1 and b1 of different types.
coder.inline('always');
coder.internal.prefer_const(relop);
AZERO = zeros(class(a1));
BZERO = zeros(class(b1));
a1signed = coder.const(intmin(class(a1)) < zeros(class(a1)));
a1NBits = coder.const(coder.internal.int_nbits(class(a1))-double(a1signed));
b1signed = coder.const(intmin(class(b1)) < zeros(class(b1)));
b1NBits = coder.const(coder.internal.int_nbits(class(b1))-double(b1signed));
if a1NBits >= b1NBits
    % class(a1) contains the non-negative integers of class(b1).
    a = a1;
    b = eml_cast(b1,class(a1),'spill');
    % We only need to add a sign check when casting from a signed class to
    % an unsigned class.
    checksign = coder.const(~a1signed && b1signed);
else
    % class(b1) contains the non-negative integers of class(a1).
    a = eml_cast(a1,class(b1),'spill');
    b = b1;
    % We only need to add a sign check when casting from a signed class to
    % an unsigned class.
    checksign = coder.const(a1signed && ~b1signed);
end
% Below we use & and | in lieu of && and || because it generates better
% code. There is no other reason. Sometimes && and || result in the
% creation of unnecessary logical temporaries when the predicate is
% evaluated as part of an if condition.
switch relop
    case {'eq','=='}
        if checksign
            if a1signed
                p = (a1 >= AZERO) & (a == b);
            else
                p = (b1 >= BZERO) & (a == b);
            end
        else
            p = (a == b);
        end
    case {'neq','~='}
        if checksign
            if a1signed
                p = (a1 < AZERO) | (a ~= b);
            else
                p = (b1 < BZERO) | (a ~= b);
            end
        else
            p = (a ~= b);
        end
    case {'gt','>' }
        if checksign
            if a1signed
                p = (a1 > AZERO) & (a > b);
            else
                p = (b1 < BZERO) | (a > b);
            end
        else
            p = (a > b);
        end
    case {'lt','<' }
        if checksign
            if a1signed
                p = (a1 < AZERO) | (a < b);
            else
                p = (b1 > BZERO) & (a < b);
            end
        else
            p = (a < b);
        end
    case {'ge','>='}
        if checksign
            if a1signed
                p = (a1 >= AZERO) & (a >= b);
            else
                p = (b1 <= BZERO) | (a >= b);
            end
        else
            p = (a >= b);
        end
    case {'le','<='}
        if checksign
            if a1signed
                p = (a1 <= AZERO) | (a <= b);
            else
                p = (b1 >= BZERO) & (a <= b);
            end
        else
            p = (a <= b);
        end
    otherwise
        coder.internal.assert(false, ...
            'Coder:toolbox:indexIntRelop_unrecognizedRelop');
        p = false;
end

%--------------------------------------------------------------------------

function y = indexIntClass
coder.inline('always');
y = coder.internal.indexIntClass;

%--------------------------------------------------------------------------

function y = indexInt(x)
coder.inline('always');
y = coder.internal.indexInt(x);

%--------------------------------------------------------------------------

function p = is_signed_indexIntClass
coder.inline('always');
p = coder.const(intmin(indexIntClass) < zeros(indexIntClass));

%--------------------------------------------------------------------------

function n = indexIntNBits
% Returns the effective number of bits in the indexInt class used to
% represent non-negative numbers.
coder.inline('always');
n = coder.const( ...
    coder.internal.int_nbits(indexIntClass) - ...
    double(is_signed_indexIntClass));

%--------------------------------------------------------------------------

function p = float_class_contains_indexIntClass(fltcls)
coder.inline('always');
coder.internal.prefer_const(fltcls);
[base,mantissaLen] = coder.internal.floatModel(fltcls);
p = coder.const(mantissaLen >= indexIntNBits);
coder.internal.assert(base == int32(2), ...
    'Coder:toolbox:indexIntRelop_nonBinaryFP',base,fltcls, ...
    'IfNotConst','Fail');
% The above is not a user-visible error at this time. We have not
% implemented non-binary floating-point support, but eml_float_model allows
% you to define it for purposes of computing eps, realmin, realmax, and
% flintmax. If we do start supporting non-binary types of floating-point,
% developers will need feedback that this file needs to be generalized and
% re-qualified.

%--------------------------------------------------------------------------

function M = pow2indexIntNBits(fltcls)
coder.inline('always');
M = coder.const(pow2(cast(indexIntNBits,fltcls)));
coder.internal.assert(isfinite(M), ...
    'Coder:toolbox:indexIntRelop_floatOverflow',fltcls, ...
    'IfNotConst','Fail');
% The above can't happen with 'single' or 'double', since
% realmax('single'), our "smallest" floating-point type, is greater than
% intmax('uint64'), our largest built-in MATLAB integer type. However it
% could happen in the future with a smaller floating point type or with a
% larger integer type. It should be simple enough to add this support later
% if it is needed, but if added now, the code for the additional cases
% would all be unreachable.

%--------------------------------------------------------------------------

function p = apply_float_relop(relop,a,b)
% (a relop b), where one input is a float and the other is an indexInt.
coder.inline('always');
coder.internal.prefer_const(relop);
% Unfortunately, unlike with single and double precision, with half
% precision we don't have the property that realmin(fcls) <= intmin(icls)
% and intmax(icls) <= realmax(fcls) for all supported integer types. Rather
% than add the extra code to handle the new cases, it seems expedient here
% to cast half precision inputs to single precision.
if isa(a,'half')
    p = apply_float_relop(relop,single(a),b);
    return
elseif isa(b,'half')
    p = apply_float_relop(relop,a,single(b));
    return
end
isfloatb = isfloat(b);
switch relop
    case {'eq','=='}
        if isfloatb
            p = idx_eq_flt(a,b);
        else
            p = idx_eq_flt(b,a);
        end
    case {'neq','~='}
        if isfloatb
            p = ~idx_eq_flt(a,b);
        else
            p = ~idx_eq_flt(b,a);
        end
    case {'lt','<' }
        if isfloatb
            p = idx_lt_flt(a,b);
        else
            p = idx_gt_flt(b,a);
        end
    case {'le','<='}
        if isfloatb
            p = idx_le_flt(a,b);
        else
            p = idx_ge_flt(b,a);
        end
    case {'gt','>' }
        if isfloatb
            p = idx_gt_flt(a,b);
        else
            p = idx_lt_flt(b,a);
        end
    case {'ge','>='}
        if isfloatb
            p = idx_ge_flt(a,b);
        else
            p = idx_le_flt(b,a);
        end
    otherwise
        coder.internal.assert(false, ...
            'Coder:toolbox:indexIntRelop_unrecognizedRelop');
end

%--------------------------------------------------------------------------

function p = idx_eq_flt(idx,flt)
% p = (idx > flt), where idx is an indexInt and flt is a float.
if float_class_contains_indexIntClass(class(flt))
    coder.inline('always');
    p = (cast(idx,class(flt)) == flt);
else
    % Use short-circuiting && here to avoid the possibility of an overflow
    % warning on indexInt(flt) when flt is a large constant.
    p = float_ge_idxmin(flt) && float_le_idxmax(flt) && ...
        (floor(flt) == flt) && (idx == indexInt(flt));
end

%--------------------------------------------------------------------------

function p = idx_gt_flt(idx,flt)
% p = (idx > flt), where idx is an indexInt and flt is a float.
if float_class_contains_indexIntClass(class(flt))
    coder.inline('always');
    p = (cast(idx,class(flt)) > flt);
elseif float_lt_idxmin(flt)
    p = true;
elseif float_ge_idxmax(flt) || isnan(flt)
    p = false;
else
    % Use short-circuiting && and || here to avoid the possibility of an
    % overflow warning on indexInt(flt) when flt is a large constant.
    % idxmin <= flt < idxmax
    ceilflt = ceil(flt);
    fltidx = indexInt(ceilflt);
    p = (idx > fltidx) || (fltidx == idx && ceilflt > flt);
end

%--------------------------------------------------------------------------

function p = idx_lt_flt(idx,flt)
% p = (idx < flt), where idx is an indexInt and flt is a float.
if float_class_contains_indexIntClass(class(flt))
    coder.inline('always');
    p = (cast(idx,class(flt)) < flt);
elseif float_gt_idxmax(flt)
    p = true;
elseif float_le_idxmin(flt) || isnan(flt)
    p = false;
else
    % Use short-circuiting && and || here to avoid the possibility of an
    % overflow warning on indexInt(flt) when flt is a large constant.
    % idxmin < flt <= idxmax
    floorflt = floor(flt);
    fltidx = indexInt(floorflt);
    p = (idx < fltidx) || (fltidx == idx && floorflt < flt);
end

%--------------------------------------------------------------------------

function p = idx_ge_flt(idx,flt)
% p = (idx >= flt), where idx is an indexInt and flt is a float.
if float_class_contains_indexIntClass(class(flt))
    coder.inline('always');
    p = (cast(idx,class(flt)) >= flt);
else
    % Use short-circuiting && and || here to avoid the possibility of an
    % overflow warning on indexInt(flt) when flt is a large constant.
    p = float_le_idxmin(flt) || ...
        (float_le_idxmax(flt) && (idx >= indexInt(ceil(flt))));
end

%--------------------------------------------------------------------------

function p = idx_le_flt(idx,flt)
% p = (idx <= flt), where idx is an indexInt and flt is a float.
if float_class_contains_indexIntClass(class(flt))
    coder.inline('always');
    p = (cast(idx,class(flt)) <= flt);
else
    % Use short-circuiting && and || here to avoid the possibility of an
    % overflow warning on indexInt(flt) when flt is a large constant.
    p = float_ge_idxmax(flt) || ...
        (float_ge_idxmin(flt) && (idx <= indexInt(floor(flt))));
end

%--------------------------------------------------------------------------

function p = float_ge_idxmin(x)
% p = (x >= intmin(coder.internal.indexIntClass)) for floating point x for
% use when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
if is_signed_indexIntClass
    M = coder.const(-pow2indexIntNBits(class(x)));
    p = (x >= M);
else
    p = (x >= zeros(class(x)));
end

%--------------------------------------------------------------------------

function p = float_lt_idxmin(x)
% x < intmin(coder.internal.indexIntClass) for floating point x for use
% when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
if is_signed_indexIntClass
    M = coder.const(-pow2indexIntNBits(class(x)));
    p = (x < M);
else
    p = (x < zeros(class(x)));
end

%--------------------------------------------------------------------------

function p = float_le_idxmin(x)
% p = (x <= intmin(coder.internal.indexIntClass)) for floating point x for
% use when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
if is_signed_indexIntClass
    M = coder.const(-pow2indexIntNBits(class(x)));
    p = (x <= M);
else
    p = (x <= zeros(class(x)));
end

%--------------------------------------------------------------------------

function p = float_gt_idxmax(x)
% p = (x > intmin(coder.internal.indexIntClass)) for floating point x for
% use when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
M = coder.const(pow2indexIntNBits(class(x)));
p = (x >= M);

%--------------------------------------------------------------------------

function p = float_ge_idxmax(x)
% p = (x >= intmax(coder.internal.indexIntClass)) for floating point x for
% use when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
M = coder.const(pow2indexIntNBits(class(x)));
% Mathematically, M = intmax(indexIntClass) + 1. However, M - 1 == M in
% class(x) because we assume this function is only called when the mantissa
% length of the floating-point class is too short to contain the index
% class. Even if the index class has only one additional bit and float M -
% 1 were to round down so that M - 1 < M, the resulting float y = M - 1
% would be less than (not equal to) intmax(indexIntClass). In other words,
% there are no floating point numbers in the half-open (mathematical)
% interval [intmax(indexIntClass),M). Consequently,
% x >= intmax(indexIntClass) iff x >= M.
p = (x >= M);

%--------------------------------------------------------------------------

function p = float_le_idxmax(x)
% p = (x <= intmax(coder.internal.indexIntClass)) for floating point x for
% use when the mantissa length of the floating-point class is too short to
% contain the index class.
coder.inline('always');
M = coder.const(pow2indexIntNBits(class(x)));
% Mathematically, M = intmax(indexIntClass) + 1. However, M - 1 == M in
% class(x) because we assume this function is only called when the mantissa
% length of the floating-point class is too short to contain the index
% class. Even if the index class has only one additional bit and float M -
% 1 were to round down so that M - 1 < M, the resulting float y = M - 1
% would be less than (not equal to) intmax(indexIntClass). In other words,
% there are no floating point numbers in the half-open (mathematical)
% interval [intmax(indexIntClass),M). Consequently,
% x <= intmax(indexIntClass) iff x < M.
p = (x < M);

%--------------------------------------------------------------------------
