function s = categoricalToStruct(c)
%For use with coder.internal.structToCategorical
%MATLAB Code Generation Private Function

%   Copyright 2022 The MathWorks, Inc.



s = struct('values', uint32(c),...
           'categories', {categories(c)},...
           'isOrdinal', isordinal(c),...
           'isProtected', isprotected(c));


end