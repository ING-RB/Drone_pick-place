classdef LineHelper < handle
%This class is for internal use only. It may be removed in the future.

%   Copyright 2022-2023 The MathWorks, Inc.
    
    properties
        % Contains desired plot data
        XData
        YData
    end

    properties (Access = ?matlab.unittest.TestCase)
        % Handle to line graphics object
        LineHandle

        % Handle to data ursor manager of the figure
        DCManager
    end
    
    methods
        function obj = LineHelper(hAxes, varargin)
        %LineHelper Create a line object on the provided axes
        %   The initial line will not be displayed (no data)
        %   All additional arguments will be passed directly to the line
        %   graphics object through the "plot" function.

            obj.LineHandle = plot(hAxes, NaN, NaN, varargin{:});
            obj.LineHandle.XData = [];
            obj.LineHandle.YData = [];

            obj.DCManager = datacursormode(hAxes.Parent.Parent);
            obj.DCManager.UpdateFcn = @updatefcn;

            function txt = updatefcn(~, eventObj)
                pos = eventObj.Position;
                txt = {sprintf('X: %.16g', pos(1)), sprintf('Y: %.16g', pos(2))};
            end
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
    end

    methods (Access = ?matlab.unittest.TestCase)
        function showOrHideLine(obj)
        %showOrHideLine Update line graphics object X and Y data
        %   If the desired XData does not match the length of YData, do not
        %   display the line. Otherwise, show it with desired X and Y data.

            if numel(obj.XData) == numel(obj.YData) && ...
                    (isnumeric(obj.XData) || islogical(obj.XData)) && ...
                    (isnumeric(obj.YData) || islogical(obj.YData))
                obj.LineHandle.XData = obj.XData;
                obj.LineHandle.YData = obj.YData;
            else
                obj.LineHandle.XData = [];
                obj.LineHandle.YData = [];
            end
        end
    end
end

