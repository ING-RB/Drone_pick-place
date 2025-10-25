classdef Marker
%   This class is for internal use only. It may be removed in the future.

%Marker Defines names for the markers and line type used in LineSpec
% for plot functions.

%   Copyright 2023 The MathWorks, Inc.

    properties(Constant)
        % Markers
        Square = 'square';
        Star = 'pentagram';
        Circle = 'o';
        Point = '.';

        % Line Type
        Line = '-';
        DashedDotLine = '-.';
        None = 'none';
    end
end
