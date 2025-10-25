function c = structToCategorical(s)
%For use with coder.internal.categoricalToStruct
% MATLAB Code Genearation Private Function
%#codegen

%   Copyright 2022 The MathWorks, Inc.

c = categorical(s.values, uint32(1:numel(s.categories)), s.categories,...
    'Ordinal',s.isOrdinal, 'Protected',s.isProtected);

end
