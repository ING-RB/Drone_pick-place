classdef AbstractPlotOptionalInputs < handle
    properties
        Parent {mustBeScalarOrEmpty} = []
        Visible (1,1) matlab.lang.OnOffSwitchState = true
        OuterPosition (1,4) double = [0 0 1 1]
        HandleVisibility (1,1) string {mustBeMember(HandleVisibility,["on","off","callback"])} = "on"
        Units (1,1) string {mustBeMember(Units,["normalized","inches","centimeters","characters","points","pixels"])} = "normalized"

        Options (1,1) plotopts.PlotOptions
        Axes matlab.graphics.axis.Axes {mustBeScalarOrEmpty} = matlab.graphics.axis.Axes.empty
        CreateResponseDataTipsOnDefault (1,1) logical = true
        CreateToolbarOnDefault (1,1) logical = true
    end
end