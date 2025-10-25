classdef LineProperties
%LineProperties   Line properties of Hardware Manager scopes
%
%   l = matlab.hwmgr.scopes.LineProperties(<NAME>,<VALUE>) creates a
%   LineProperties object using one or more optional name-value argument
%   pairs used by Hardware Manager scopes.
%
%   LineProperties properties:
%       LineColor - Line color
%       LineStyle - Line style
%       LineWidth - Line width
%       Marker - Marker symbol
%       MarkerSize - Marker Size
%       MarkerEdgeColor - Marker outline color
%       MarkerFaceColor - Maker fill color
%
%   See also TimeScope, BasicScope
    
%   Copyright 2019-2020 The MathWorks, Inc.
    
    properties
        %LineColor - Line color
        %   Line color, specified as 'auto', a color name, or a hexadecimal
        %   color code. The default is 'auto'.
        LineColor (1, 1) string
        
        %LineStyle - Line style
        %   Line style, specified as one of the options: '-'| '--' | ':' |
        %   '-.' The default is '-'.
        LineStyle {mustBeMember(LineStyle, ["-", ":", "-.", "--"])} = "-"
        
        %LineWidth - Line width
        %   Line width, specified as a positive value. The default is 1.
        LineWidth (1, 1) double {mustBePositive} = 1;
        
        %Marker - Marker symbol
        %   Marker symbol, specified as one of the values of
        %   matlab.hwmgr.scopes.Markers. The default is 'None'.
        Marker (1, 1) matlab.hwmgr.scopes.Markers = matlab.hwmgr.scopes.Markers.None;
        
        %MarkerSize - Marker Size
        %   Marker size, specified as a positive value. The default is 6.
        MarkerSize  (1, 1) double {mustBePositive} = 6;
        
        %MarkerEdgeColor - Marker outline color
        %   Marker outline color, specified as 'auto', a color name, or a
        %   hexadecimal color code. The default is 'auto'.
        MarkerEdgeColor (1, 1) string
        
        %MarkerFaceColor - Maker fill color
        %   Marker fill color, specified as 'none', a color name, or a
        %   hexadecimal color code. The default is 'none'.
        MarkerFaceColor (1, 1) string
    end
    
    methods
        function obj = LineProperties(varargin)
            p = inputParser;
            p.FunctionName = "LineProperties";
            
            defaultLineColor = "auto";
            defaultLineStyle = "-";
            defaultLineWidth = 1;
            defaultMarker = matlab.hwmgr.scopes.Markers.None;
            defaultMarkerSize = 6;
            defaultMarkerEdgeColor = "auto";
            defaultMarkerFaceColor = "none";
            
            addParameter(p, "LineColor", defaultLineColor);
            addParameter(p, "LineStyle", defaultLineStyle);
            addParameter(p, "LineWidth", defaultLineWidth);
            addParameter(p, "Marker", defaultMarker);
            addParameter(p, "MarkerSize", defaultMarkerSize);
            addParameter(p, "MarkerEdgeColor", defaultMarkerEdgeColor);
            addParameter(p, "MarkerFaceColor", defaultMarkerFaceColor);
            
            parse(p, varargin{:});
            obj.LineColor = p.Results.LineColor;
            obj.LineStyle = p.Results.LineStyle;
            obj.LineWidth = p.Results.LineWidth;
            obj.Marker = p.Results.Marker;
            obj.MarkerSize = p.Results.MarkerSize;
            obj.MarkerEdgeColor = p.Results.MarkerEdgeColor;
            obj.MarkerFaceColor = p.Results.MarkerFaceColor;
        end
    end
end