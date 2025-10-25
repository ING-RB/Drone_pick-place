classdef AccessLevel
% AccessLevel - Specification of access level of package

%   Copyright 2024 The MathWorks, Inc.

    enumeration
        % User - Package is visible to current user
        User

        % Temporary - Package is visible only in current MATLAB session
        Temporary
    end
end
