classdef TableSlice< handle
%mlreportgen.utils.TableSlice Container for a table slice
%   A TableSlicer object creates instances of this class to contain the
%   tables slices it creates
%
%   TableSlice properties:
%
%       Table       - Slice table
%       StartCol    - Start column of  slice
%       EndCol      - End column of slice
%
%   See also mlreportgen.utils.TableSlicer

     
    %   Copyright 2018 The MathWorks, Inc.

    methods
    end
    properties
        %EndCol Ending column index of this slice
        %   The value of this read-only property is the index of the column
        %   in the original table where this slice ends.
        EndCol;

        %StartCol Starting column index of this slice
        %   The value of this read-only property is the index of the column
        %   where this slice starts in the original table
        StartCol;

        %Table Slice of a table
        %   The value of this read-only property is a table that contains
        %   the data from a vertical slice(array of columns) of a table
        %   that has been sliced by a TableSlicer.
        Table;

    end
end
