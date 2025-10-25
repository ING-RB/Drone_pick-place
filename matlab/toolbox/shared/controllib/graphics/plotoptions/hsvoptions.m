function p = hsvoptions(varargin)
%HSVOPTIONS  Creates option list for Hankel singular value plot.
%
%   OPT = HSVOPTIONS returns the default options for Hankel singular value
%   plots. This list of options allows you to customize the Hankel singular
%   value plot appearance from the command line. For example
%         opt = hsvoptions;
%         % Set the Y axis scale to linear in options 
%         opt.YScale = 'linear'; 
%         % Create plot with the options specified by OPT
%         h = hsvplot(rss(10,2,3),opt);
%   creates a Hankel singular value plot with a linear scale for the Y axis.  
%
%   P = HSVOPTIONS('cstpref') initializes the plot options with 
%   the Control System Toolbox preferences.
%
%   Available options include:
%      Title, XLabel, YLabel    Label text and style
%      TickLabel                Tick label style
%      Grid   [off|on]          Show or hide the grid 
%      XlimMode, YlimMode       Limit modes
%      Xlim, Ylim               Axes limits
%      YScale [linear|log]      Scale for Y axis
%      
%   See also HSVPLOT, BALREDOPTIONS, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%  Copyright 1986-2021 The MathWorks, Inc.
p = plotopts.HSVOptions(varargin{:});
