classdef MapHelper < handle
    %This class is for internal use only. It may be removed in the future.

    %   Copyright 2024 The MathWorks, Inc.

    properties
        % Contains desired plot data
        Latitude
        Longitude
    end

    properties (Access = ?matlab.unittest.TestCase)
        % Handle to line graphics object
        LineHandle

        % Handle to data cursor manager of the figure
        DCManager
    end

    methods
        function obj = MapHelper(hAxes, themeColor,  varargin)
            %MapHelper Create a line object on the provided axes
            %   The initial line will not be displayed (no data)
            %   All additional arguments will be passed directly to the line
            %   graphics object through the "geoplot" function.

            obj.LineHandle = geoplot(hAxes, NaN, NaN, varargin{:});
            matlab.graphics.internal.themes.specifyThemePropertyMappings(obj.LineHandle, 'Color', themeColor)
            obj.LineHandle.LatitudeData = [];
            obj.LineHandle.LongitudeData = [];
        end

        function delete(obj)
            %delete Delete line graphics object

            delete(obj.LineHandle)
        end

        function set.Latitude(obj, x)
            %set.Latitude Update the graphic object XData appropriately

            obj.Latitude = x(:).';
            showOrHideLine(obj);
        end

        function set.Longitude(obj, y)
            %set.Longitude Update the graphic object YData appropriately

            obj.Longitude = y(:).';
            showOrHideLine(obj);
        end
    end

    methods (Access = ?matlab.unittest.TestCase)
        function showOrHideLine(obj)
            %showOrHideLine Update line graphics object X and Y data
            %   If the desired XData does not match the length of YData, do not
            %   display the line. Otherwise, show it with desired X and Y data.

            if numel(obj.Latitude) == numel(obj.Longitude)
                obj.LineHandle.LatitudeData = obj.Latitude;
                obj.LineHandle.LongitudeData = obj.Longitude;
            else
                obj.LineHandle.LatitudeData = [];
                obj.LineHandle.LongitudeData = [];
            end
        end
    end
end