classdef (Hidden) PositionUtils
    % Helper function for position related things
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods (Static)
        function newPos = convertFromZeroToOneOrigin(pos)
            newPos =  [pos(1) + 1, pos(2) + 1, pos(3), pos(4)];
        end
        
        function newPos = convertFromOneToZeroOrigin(pos)
            newPos =  [pos(1) - 1, pos(2) - 1, pos(3), pos(4)];
        end
    end
end

