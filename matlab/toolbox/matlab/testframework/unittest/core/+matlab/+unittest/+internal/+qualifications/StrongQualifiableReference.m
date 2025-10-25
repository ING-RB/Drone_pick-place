classdef StrongQualifiableReference
    %

    % Copyright 2024 The Mathworks, Inc.

    properties
        Handle
    end

    methods
        function obj = StrongQualifiableReference(qualifiable)
            obj.Handle = qualifiable;
        end
    end
end