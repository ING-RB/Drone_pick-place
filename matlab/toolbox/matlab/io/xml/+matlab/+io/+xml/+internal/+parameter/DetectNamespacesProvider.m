classdef DetectNamespacesProvider < matlab.io.internal.FunctionInterface
% DetectNamespacesProvider An interface for functions that accept DetectNamespaces.

% Copyright 2020 The MathWorks, Inc.

    properties (Parameter)
        %DetectNamespaces
        %   Enables namespace prefix detection and auto-registration.
        %   Defaults to true.
        DetectNamespaces(1, 1) logical = true;
    end
end
