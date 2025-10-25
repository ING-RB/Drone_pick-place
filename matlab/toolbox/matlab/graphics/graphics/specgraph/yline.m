function hh = yline(varargin)
%YLINE create a horizontal line
%   YLINE(VALUES) creates constant lines at the specified values of y.
%   VALUE can be either a scalar or a vector. For example, yline(5) creates
%   a line at y = 5.  In 2-D views, the line is typically a horizontal
%   line. In 3-D views, the line appears in the xy-plane in the middle of
%   the z-axis limits. This input can be vectorized.
%   
%   YLINE(VALUES, LINESPEC) specifies either the line style, the color, or 
%   both. For example, ':' creates a dotted line, 'r' creates a red line, 
%   and 'r:' creates a dotted, red line.
%
%   YLINE(VALUES, LINESPEC, LABELS) adds the specified labels to the lines.
%   When VALUES contains multiple elements, you can display different
%   labels for each line by specifying LABELS as either cell array of
%   character vectors or a string array with the same number of elements as
%   VALUES. Alternatively, specify LABELS as a character vector or a string
%   scalar to display the same label on all the lines.
%
%   YLINE(...Name,Value) specifies ConstantLine properties using one or 
%   more name-value pair arguments. Specify name-value pairs after all 
%   other input arguments.
%
%   YLINE(AX, ...) creates the line in the axes specified by ax instead of
%   in the current axes (gca). 
%
%   YL = YLINE(...) returns the line. Use YL to modify the ConstantLine
%   object after it is created.
%
%   See also XLINE

%   Copyright 2018-2020 The MathWorks, Inc.

    args = varargin;
    h = matlab.graphics.internal.xyzline('y', args);
    
    % Prevent outputs when not assigning to variable.
    if nargout > 0
        hh = h; 
    end
end