classdef ComparatorService < matlab.unittest.internal.services.Service
    %
    
    % Copyright 2019 The MathWorks, Inc.
    
    methods (Abstract, Access=protected)
        % getComparators - Returns a comparator value.
        %
        %   getComparators(SERVICE) should be implemented to
        %   return the located comparator(s).It returns a value 
        %   of class matlab.unittest.constraints.Comparator.
        
        comparators = getComparators(service)
    end
    
    methods (Sealed)
        function fulfill(services, liaison)
            %   fulfill(SERVICES, LIAISON)- fulfills a comparator service
            %   by calling the getComparators method on all elements of
            %   the array and then returns array of located comparator value.
            
            comparators = arrayfun(@(s)s.getComparators, services, 'UniformOutput', false);
            liaison.LocatedComparators = [matlab.unittest.constraints.Comparator.empty, comparators{:}];
             
        end
    end
    
end
