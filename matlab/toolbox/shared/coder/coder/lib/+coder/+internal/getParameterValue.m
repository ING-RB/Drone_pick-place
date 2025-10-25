function y = getParameterValue(k,default,varargin)
%MATLAB Code Generation Private Function
%
%   Retrieves parameter values from a varargin list using a lookup value K
%   computed by coder.internal.parseParameterInputs.  See the help for that
%   function for example usage.

%   Copyright 2009-2021 The MathWorks, Inc.
%#codegen

if isempty(coder.target)
    if k == 0
        y = default;
    elseif k <= uint32(65535) % intmax('uint16') = 65535
        y = varargin{k};
    else
        vidx = bitshift(k,-16);
        s = varargin{vidx};
        fidx = bitand(k,uint32(65535));
        names = fieldnames(s);
        fname = names{fidx+1};
        y = s.(fname);
    end
else
    coder.inline('always');
    coder.internal.prefer_const(k);
    coder.internal.allowEnumInputs;
    coder.internal.allowHalfInputs;
    if coder.const(k == zeros('uint32'))
        y = default;
    elseif coder.const(k <= uint32(intmax('uint16')))
        y = varargin{k};
    else
        vidx = eml_rshift(k,int8(16));
        s = varargin{vidx};
        fidx = eml_bitand(k,uint32(intmax('uint16')));
        fname = eml_getfieldname(s,fidx);
        y = eml_getfield(s,fname);
    end
end


