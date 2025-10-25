function p = sectorplotoptions(varargin)
%SECTORPLOTOPTIONS Creates option list for relative index plots.
%
%   OPT = SECTORPLOTOPTIONS returns the default options for sector index plots.
%   This list of options allows you to customize the sector index plot
%   appearance from the command line. For example
%         OPT = sectorplotoptions;
%         % Set the frequency units to Hz in options 
%         OPT.FreqUnits = 'Hz'; 
%         % Create plot with the options specified by OPT
%         sectorplot([tf(1,[1 2]);1],diag([0.1,-0.2]),OPT);
%   creates a sector index plot with the frequency units in Hz. 
%
%   OPT = SECTORPLOTOPTIONS('cstprefs') initializes the plot options with the
%   Control System Toolbox preferences.
%
%   Available options include:
%      Title, XLabel, YLabel         Label text and style
%      TickLabel                     Tick label style
%      Grid   [off|on]               Show or hide the grid 
%      XlimMode, YlimMode            Limit modes
%      Xlim, Ylim                    Axes limits
%      IOGrouping                    Grouping of input-output pairs
%         [none|inputs|outputs|all] 
%      InputLabels, OutputLabels     Input and output label styles
%      InputVisible, OutputVisible   Visibility of input and output
%                                    channels
%      FreqUnits                     Frequency units
%      FreqScale [linear|log]        Frequency scale
%      IndexScale [linear|log]       Index scale
%
%   See also DYNAMICSYSTEM/SECTORPLOT, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

p = plotopts.SectorPlotOptions(varargin{:});