function removeStyle(obj, varargin)
%REMOVESTYLE Remove style from table UI component
%
%   REMOVESTYLE(comp) removes all styles created with the uistyle function
%   from the specified table UI component. To determine which styles are on
%   uit and available to remove, query the value of uit.StyleConfigurations.
%
%   REMOVESTYLE(comp,ordernum) specifies which style to remove.
%   The property uit.StyleConfigurations lists styles in the
%   order that they were added.
%
%   Example: Remove Style from Table 
%      % Remove a single style from a table.
%      % First, create a table and add styles to it.
%      s1 = uistyle('BackgroundColor','red'); 
%      s2 = uistyle('BackgroundColor','yellow'); 
% 
%      fig = uifigure; 
%      fig.Position = [100 100 520 220]; 
%      tbl = uitable(fig); 
%      tbl.Data = rand(5); 
%      tbl.Position = [20 30 480 135]; 
% 
%      addStyle(tbl,s1,'column',3) 
%      addStyle(tbl,s2,'row',4)
%
%      % Now, remove the first style added to the table by specifying order
%      % number 1.
%      removeStyle(tbl,1)
%    
%   See also MATLAB.UI.CONTROL.TABLE/ADDSTYLE, UISTYLE, UITABLE
%

%   Copyright 2019-2021 The MathWorks, Inc.

    narginchk(1, 2);
    
    % removeStyle is not supported with tables parented to a figure
    if ~matlab.ui.control.internal.model.TablePropertyHandling.isValidComponent(obj)
        error(message('MATLAB:ui:uifigure:UnsupportedAppDesignerFunctionality', ...
            'figure'));
    end

    switch nargin
        case 1
            % Remove all styles
            removeFromStyleTable(obj, 'all', '');
        case 2
            removedStyle = varargin{1};
            
            if (isValidOrder(removedStyle))
                % If scalar numeric or numeric array
                % Remove the style at that order number
                removeFromStyleTable(obj, 'numeric', removedStyle);
            else
                messageObject = message('MATLAB:ui:style:invalidRemovalIndex');
                me = MException('MATLAB:ui:Table:invalidRemovalIndex', ...
                    messageObject.getString());
                throw(me)
            end
    end
end

function removeFromStyleTable(obj, indexType, removedStyle)
    matlab.ui.style.internal.StylesMetaData.removeStyle(obj, indexType, removedStyle);
end

function validOrder = isValidOrder(ord)
    % An order is valid if it is a scalar or array of positive integers
    try 
        validateattributes(ord,{'numeric'},{'positive','integer','real','finite','vector','nonempty'});
        validOrder = true;
    catch ME %#ok<NASGU>
        validOrder = false;
    end
end