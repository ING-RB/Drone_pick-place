classdef LineHelper3D < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2023 The MathWorks, Inc.

    properties
        % Contains desired plot data
        XData
        YData
        ZData
    end

    properties (Access = ?matlab.unittest.TestCase)
        % Handle to line graphics object
        LineHandle
    end

    methods
        function obj = LineHelper3D(hAxes, varargin)
            %LineHelper Create a line object on the provided axes
            %   The initial line will not be displayed (no data)
            %   All additional arguments will be passed directly to the line
            %   graphics object through the "plot" function.

            obj.LineHandle = plot3(hAxes, NaN, NaN, NaN, varargin{:});
            obj.LineHandle.XData = [];
            obj.LineHandle.YData = [];
            obj.LineHandle.ZData = [];
        end

        function delete(obj)
            %delete Delete line graphics object

            delete(obj.LineHandle)
        end

        function set.XData(obj, x)
            %set.XData Update the graphic object XData appropriately

            obj.XData = x(:).';
            showOrHideLine(obj);
        end

        function set.YData(obj, y)
            %set.YData Update the graphic object YData appropriately

            obj.YData = y(:).';
            showOrHideLine(obj);
        end

        function set.ZData(obj, z)
            %set.ZData Update the graphic object ZData appropriately

            obj.ZData = z(:).';
            showOrHideLine(obj);
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function showOrHideLine(obj)
            %showOrHideLine Update line graphics object X and Y data
            %   If the desired XData and  does not match the length of YData, do not
            %   display the line. Otherwise, show it with desired X and Y data.

            if numel(obj.XData) == numel(obj.YData) && ...
                    numel(obj.YData) == numel(obj.ZData) && ...
                    numel(obj.XData) == numel(obj.ZData) && ...
                    (isnumeric(obj.XData) || islogical(obj.XData)) && ...
                    (isnumeric(obj.YData) || islogical(obj.YData)) && ...
                    (isnumeric(obj.ZData) || islogical(obj.ZData))
                obj.LineHandle.XData = obj.XData;
                obj.LineHandle.YData = obj.YData;
                obj.LineHandle.ZData = obj.ZData;
            else
                obj.LineHandle.XData = [];
                obj.LineHandle.YData = [];
                obj.LineHandle.ZData = [];
            end
        end
    end
end

