function s = constantPreservingStruct(varargin)
%MATLAB Code Generation Private Function
%   Returns an object that simulates a struct type but preserves constness
%   of individual fields. In MATLAB, s = struct(varargin(:)). For code
%   generation,
%       s = coder.internal.makeConstantPreservingStruct( ...
%           fieldname1,value1,fieldname2,value2,...);
%   works like
%       s = struct(fieldname1,value1,fieldname2,value2,...);
%   but instead of a struct produces a coder.internal.stickyStruct to
%   maintain constness of the field values where possible. The object
%   behaves like a struct in most respects, even claims to be one if you
%   call class(s), but it should only be used internally, not passed back
%   to the user. For one thing, it is essentially read-only. When s must be
%   returned to a user, pass struct(s) back to an external calling
%   function. This converts s to an actual struct.

%   Copyright 2021 The MathWorks, Inc.
%#codegen

if coder.internal.isCompiled
    coder.internal.allowEnumInputs;
    coder.internal.allowHalfInputs;
    coder.internal.prefer_const(varargin);
    s = coder.internal.stickyStruct.parse(varargin{:});
else
    for k = 2:2:nargin
        if iscell(varargin{k})
            varargin{k} = {varargin{k}}; %don't expand into struct arrays
        end
    end
    s = struct(varargin{:});
end
