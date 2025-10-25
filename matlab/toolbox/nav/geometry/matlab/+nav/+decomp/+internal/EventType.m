classdef EventType < uint8
%EventType - Represent the class of an event that occurs at a vertex

%   Copyright 2024 The MathWorks, Inc.

%#codegen
    enumeration
        Ceiling (0)
        In (1)
        Floor (2)
        Out (3)
        Pinch (4)
        Split (5)
        VertEdge (6)
    end
end
