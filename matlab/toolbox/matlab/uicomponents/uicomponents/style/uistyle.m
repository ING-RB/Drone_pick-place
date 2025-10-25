function styleObject = uistyle(varargin)
%UISTYLE Create style for table or tree UI component
%   s = UISTYLE  creates an empty style for a table or tree UI component
%   and returns the Style object. Use this syntax to create a style you
%   want to modify later.
%
%   s = UISTYLE(Name,Value) specifies Style property values using one or
%   more name-value pair arguments.
%
%   Example: Create Style and Add Style to Table
%      % Create a style with a specific background color. 
%      s = UISTYLE('BackgroundColor','red'); 
%
%      % Apply the style to the second column of a table using the addStyle
%      % function.
%      fig = uifigure;
%      fig.Position = [100 100 520 220];
%      tbl = uitable(fig);
%      tbl.Data = rand(5);
%      tbl.Position = [20 30 480 135];
%
%      addStyle(tbl,s,'column',2)
%
%   See also MATLAB.UI.CONTROL.TABLE/ADDSTYLE, MATLAB.UI.CONTROL.TABLE/REMOVESTYLE, UITABLE
%

%   Copyright 2017-2021 The MathWorks, Inc.


try
    styleObject = matlab.ui.style.Style(varargin{:});
     
catch ex
        
    % There are several well established generic error messages
    % that are useful to users because they represent a well 
    % known specific issue.  A few of the popular ones are
    % worth looking out for and passing on as is as opposed to
    % the general uifunction error message that just says
    % there's a problem somewhere.
    throwAsCaller(ex);

end
