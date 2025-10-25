classdef TextComparison< comparisons.Comparison
%TextComparison - Comparison of two text files
%
%  TextComparison properties:
%     Left - Name of text file on left of comparison
%    Right - Name of text file on right of comparison
%
%  See also comparisons.Comparison

 
    % Copyright 2022-2023 The MathWorks, Inc.

    methods
        function out=publish(~) %#ok<STOUT>
        end

    end
    properties
        Left;

        Right;

    end
end
