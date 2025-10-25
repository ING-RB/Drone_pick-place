classdef ToolstripColumn
    %TOOLSTRIPCOLUMN form class contains information about the width of a
    %toolstrip column, and the alignment of toolstrip elements in the given
    %column.

    % Copyright 2020 The MathWorks, Inc.

    properties
        % The width of the toolstrip column. This indirectly sets the size
        % of a toolstrip elememt.
        Width

        % The horizontal alignment of toolstrip elements in a given
        % toolstrip column.
        HorizontalAlignment (1,1) string {mustBeMember(HorizontalAlignment, ["left", "center", "right"])} = "left"
    end

    methods
        function obj = ToolstripColumn(width, alignment)
            obj.Width = width;
            obj.HorizontalAlignment = alignment;
        end
    end
end