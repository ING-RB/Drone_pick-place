classdef FigureToolsDimsConstants 
    %FigureToolsDims dims of figure tools
    %   This class holds the dims of the figure tools 
    %   which can be used for position calculations 

    %   Copyright 2024 The MathWorks, Inc.

    properties(Constant)
        
        % Height of toolbar
        ToolBarHeight = 27;
    
        % Height of menubar
        MenuBarHeight = 22;
    
        % Height figure toolstrip
        FiguretoolstripHeight = 28;

        % Titlebar height in Linux 
        TitleBarHeightLinux = 37;

        % Titlebar height in Mac
        TitleBarHeightMac = 28;

        % Titlebar height in windows
        TitleBarHeightWindows = 31;

        % Border padding for windows
        BorderEstimateInWindows = 8;

        % Border padding in Linux
        BorderEstimateInLinux = 0;

        % Border padding in mac
        BorderEstimateInMac = 0;

        % Padding value to account backward compatibility
        PaddingEstimate = 6;
        
    end

end