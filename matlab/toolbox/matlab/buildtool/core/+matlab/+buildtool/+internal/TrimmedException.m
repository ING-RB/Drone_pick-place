classdef TrimmedException < MException
    % This class is unsupported and might change or be removed without notice
    % in a future version.
    
    % Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = immutable, GetAccess = protected)
        OriginalException MException {mustBeScalarOrEmpty}
    end
    
    methods
        function trimmed = TrimmedException(other)
            arguments
                other (1,1) MException
            end
            
            import matlab.buildtool.internal.TrimmedException;
            
            trimmed = trimmed@MException(other.identifier, "%s", other.message);
            trimmed.OriginalException = other;
            trimmed.type = other.type;
            for idx = 1:numel(other.cause)
                trimmed = trimmed.addCause(TrimmedException(other.cause{idx}));
            end
        end
    end
    
    methods (Access = protected)
        function stack = getStack(trimmed)
            import matlab.buildtool.internal.trimStackEnd;
            stack = trimStackEnd(trimmed.OriginalException.getStack());
        end
    end
end

