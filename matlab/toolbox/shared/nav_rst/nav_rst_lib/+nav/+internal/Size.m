classdef Size
%   This class is for internal use only. It may be removed in the future.

%Size Defined the size used for planning parameters.

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)

        % Default size to used. Currently used for tree, reverse tree etc.
        Default = 1;

        % Size for Path line
        Path = 3;
        % Size for path state marker
        PathState = 5;

        % Size for tree states marker
        TreeState = 2;

        % Size of Markers of end points
        State = 2;
        Start = 10;
        Goal = 15;

        % Size for clearance
        MinClearance = 3;
        StatesClearance = 1.5;
    end
end
