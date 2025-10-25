function p = pzoptions(varargin)
%PZOPTIONS Creates option list for pole/zero plot.
%
%   P = PZOPTIONS returns the default options for pole/zero plots
%   (pole/zero, input-output pole/zero and root locus). This list of
%   options allows you to customize the pole/zero plot appearance from the
%   command line. For example
%         P = pzoptions;
%         % Set the grid to on in options 
%         P.Grid = 'on';
%         % Create plot with the options specified by P
%         h = rlocusplot(tf(1,[1,.2,1,0]),P);
%   creates a root locus plot with the grid turned on.
%
%   P = PZOPTIONS('cstprefs') initializes the plot options with the
%   Control System and System Identification Toolbox preferences.
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
%      FreqUnits                     Frequency units (Only affects display
%                                    of natural frequencies)
%      TimeUnits                     Time units
%      ConfidenceRegionNumberSD      Number of standard deviations to
%                                    use when displaying the confidence
%                                    region characterisitc for identified 
%                                    models (valid only IOPZPLOT)
%
%   See also LTI/PZPLOT, LTI/IOPZPLOT, LTI/RLOCUSPLOT, WRFC/SETOPTIONS,
%   WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

p = plotopts.PZOptions(varargin{:});