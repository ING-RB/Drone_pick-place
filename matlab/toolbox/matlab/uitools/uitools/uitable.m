function [thandle, chandle] = uitable(varargin)
% UITABLE Create table user interface component.
%   UITABLE creates a table user interface component in the current figure
%   and returns the Table UI component object.  If there is no figure
%   available, MATLAB calls the figure function to create one.
%
%   UITABLE('PropertyName1',value1,'PropertyName2',value2,...) specifies
%   property values of the Table UI component using one or more name-value
%   pair arguments.
%
%   UITABLE(PARENT, ...) creates the table in the specified parent
%   container. The parent container can be a figure created with either the
%   figure or uifigure function, or a child container such as a panel.
%
%   H = UITABLE(...) creates a uitable object and returns its handle.
%
%   Execute GET(H), where H is a uitable handle, to see the list of uitable
%   object properties and their current values.
%
%   Execute SET(H) to see the list of uitable object properties that can be
%   set and their legal property values.
%
%   Example: Create a table with data, column names, parent and position.
%      f = figure;
%      data = rand(3);
%      colnames = {'X-Data', 'Y-Data', 'Z-Data'};
%      t = uitable(f, 'Data', data, 'ColumnName', colnames, ...
%                  'Position', [20 20 260 100]);
%
%
%   See also FIGURE, INSPECT, FORMAT, SPRINTF, UICONTROL, UIMENU, UIPANEL

%   Copyright 2002-2018 The MathWorks, Inc.
%   Built-in function.

% If using the 'v0' switch explicitly, use the old uitable.
if (usev0dialog(varargin{:}))
    [thandle, chandle] = uitable_deprecated(varargin{2:end});
else
    % If using the 2-output syntax or using an old, unsupported API,
    % use the old table.
    if (nargout == 2) ||(uitable_parseold(varargin{:}))
        % Warn about using the old undocumented uitable.
        urlHelpUitable = 'matlab:help(''uitable'')';
        urlDocUitable = 'matlab:doc(''uitable'')';

        warnState = warning('backtrace', 'off');
        warning(message('MATLAB:uitable:OldTableUsage', urlHelpUitable, urlDocUitable))
        warning(warnState);
        [thandle, chandle] = uitable_deprecated(varargin{:});
    else
        % If not using the v0 option and using PV pairs that are either supported
        % by the new API or not supported at all, use the new uitable.
        thandle = builtin('uitable', varargin{:});
    end
end
