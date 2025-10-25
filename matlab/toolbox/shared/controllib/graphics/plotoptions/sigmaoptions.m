function p = sigmaoptions(varargin)
%SIGMAOPTIONS Creates option list for singular value plots.
%
%   P = SIGMAOPTIONS returns the default options for singular value plots.
%   This list of options allows you to customize the singular value plot
%   appearance from the command line. For example
%         P = sigmaoptions;
%         % Set the frequency units to Hz in options 
%         P.FreqUnits = 'Hz'; 
%         % Create plot with the options specified by P
%         h = sigmaplot(rss(2,2,3),P);
%   creates a singular value plot with the frequency units in Hz. 
%
%   P = SIGMAOPTIONS('cstprefs') initializes the plot options with the
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
%      MagUnits [dB|abs]             Magnitude units
%      MagScale [linear|log]         Magnitude scale
%
%   See also LTI/SIGMAPLOT, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

p = plotopts.SigmaOptions(varargin{:});