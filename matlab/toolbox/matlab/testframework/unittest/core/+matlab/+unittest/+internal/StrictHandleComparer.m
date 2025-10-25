classdef (Hidden) StrictHandleComparer < handle
    % This class is undocumented and may change in a future release.
    
    % Copyright 2016-2018 The MathWorks, Inc.
    
    methods (Static)
        function bool = eq(a, b)
            try
                bool = eq@handle(a, b);
            catch ex
                if ex.identifier ~= "MATLAB:class:UndefinedMethod"
                    rethrow(ex);
                end
                bool = a == b; % Fall back to object's eq for Java, OOPS, UDD
            end
        end
    end
end
