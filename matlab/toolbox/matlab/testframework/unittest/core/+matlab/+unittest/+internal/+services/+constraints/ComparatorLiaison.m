classdef (Sealed) ComparatorLiaison < handle
    % ComparatorLiaison - Liaison to be used by a ComparatorService.
    
    % Copyright 2019 The MathWorks, Inc.
    
    properties
        LocatedComparators(1,:) matlab.unittest.constraints.Comparator
    end
    
end
