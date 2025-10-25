function p = nyquistoptions(varargin)
%NYQUISTOPTIONS Creates option list for Nyquist plot.
%
%   P = NYQUISTOPTIONS returns the default options for Nyquist plots. This
%   list of options allows you to customize the Nyquist plot appearance
%   from the command line. For example
%         P = nyquistoptions;
%         % Set option to show the full contour 
%         P.ShowFullContour = 'on'; 
%         % Create plot with the options specified by P
%         h = nyquistplot(tf(1,[1,.2,1]),P);
%   creates a Nyquist plot with the full contour shown (the response for
%   both positive and negative frequencies).
%
%   P = NYQUISTOPTIONS('cstprefs') initializes the plot options with the
%   Control System and System Identification Toolbox preferences.
%
%   Available options include:
%      Title, XLabel, YLabel           Label text and style
%      TickLabel                       Tick label style
%      Grid   [off|on]                 Show or hide the grid 
%      XlimMode, YlimMode              Limit modes
%      Xlim, Ylim                      Axes limits
%      IOGrouping                      Grouping of input-output pairs
%         [none|inputs|outputs|all] 
%      InputLabels, OutputLabels       Input and output label styles
%      InputVisible, OutputVisible     Visibility of input and output
%                                      channels
%      FreqUnits                       Frequency units
%      MagUnits [dB|abs]               Magnitude units
%      PhaseUnits [deg|rad]            Phase units
%      ShowFullContour [on|off]        Show response for negative frequencies
%      ConfidenceRegionNumberSD        Number of standard deviations to
%                                      use when displaying the confidence
%                                      region characteristic for identified 
%                                      models
%      ConfidenceRegionDisplaySpacing  Spacing between frequency points
%                                      at which the confidence region 
%                                      characteristic is displayed for 
%                                      identified models
%
%   See also LTI/NYQUISTPLOT, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.

p = plotopts.NyquistOptions(varargin{:});