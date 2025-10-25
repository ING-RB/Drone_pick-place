function out = isValidParent(parent)
%isValidParent Check whether given parent is valid

%   Copyright 2018-2020 The MathWorks, Inc.

    out = isa(parent, 'matlab.settings.FactoryGroup') && ...
        (isempty(parent) || isscalar(parent));
end

