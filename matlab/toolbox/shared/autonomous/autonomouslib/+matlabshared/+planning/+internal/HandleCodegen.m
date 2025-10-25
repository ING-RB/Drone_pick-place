%#codegen

% codegen redirection class. Allows us to overload subsref using
% EnforceScalar* to get the behavior we need in MATLAB and still allows
% codegen. This work around can be removed once g912825 is resolved.

% NOTE: This is a copy of vision.internal.enforcescalar.HandleCodegen

% Copyright 2017-2018 The MathWorks, Inc.

classdef HandleCodegen < matlabshared.planning.internal.HandleBase
    methods(Access = protected, Sealed)
        function enforceNoArray(obj)
            coder.internal.errorIf(true,...
                                   'shared_autonomous:validation:arrayNotSupported',...
                                   class(obj));
        end
    end
end
