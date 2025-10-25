function schemas = dig_get_interface( whichMenu, cbinfo, menuFcn, gateFcn, varargin )
% DIG_GET_INTERFACE Called by DigManager to return a cell-array of
% ToolSchemas.
%   DIG_GET_INTERFACE WHICHMENU CBINFO MENUFCN GATEFCN 
%     calls gateFcn( menuFcn, whichMenu, cbinfo ) if gateFcn exists and is
%     non-empty. This returns the cell-array of valid menu elements. It then
%     uses the schema generators to generate a cell-array of ToolSchemas.
%
%   DIG_GET_INTERFACE WHICHMENU CBINFO MENUFCN GATEFCN AUTODISABLEFCN
%   Same as above, except AUTODISABLEFCN is used to check autodisable for 
%   generated ToolSchemas.
%       
%   DIG_GET_INTERFACE WHICHMENU CBINFO MENUFCN GATEFCN AUTODISABLEFCN
%   AUTODISABLEGATEFCN
%   Same as the previous version, except AUTODISABLEGATEFCN is used to access
%   an AUTODISABLEFCN that resides in a private directory.
%
%   See also private/dig_get_schema, private/dig_get_menu, private/dig_get_error_gen,
%   private/dig_get_error_schema, private/dig_get_toolbars
%
%   Copyright 2011 The MathWorks, Inc.
    schemas = {}; %#ok<NASGU>
    assert( nargin >= 3 && nargin < 7 ); % Must have whichMenu, cbinfo and menuFcn.
    
    % First, we generate the cell-array of menu elements.
    % A menu element is one of:
    % - function handle to ToolSchema generator.
    % - A cell-array with two entries; the first a handle to a ToolSchema
    % generator, second is anything (for userdata )
    % - The string 'separator'
    elements = {}; %#ok<NASGU>
    try
        if nargin >= 4 && ~isempty( gateFcn )
            elements = feval( gateFcn, menuFcn, whichMenu, cbinfo );
        elseif ~isempty( menuFcn )
            elements = feval( menuFcn, whichMenu, cbinfo );
        else
            % menuFcn should never be invalid.
            msg = message( 'dastudio:dig:get_interface_error' );
            Ex = MException( 'dastudio:DIGError', msg.getString );
            elements = { dig_get_error_gen( 'container', Ex ) };
        end
    catch Ex
        % Generate an Error Schema and attach this exception to it for
        % display in the menus.
        elements = { dig_get_error_gen( 'container', Ex ) };
    end
    
    % Now that we have a list of valid elements, we will pass them on to be
    % generated. This function will ensure that the same number of items
    % that we pass in gets returned. We want to be sure to pass the
    % auto-disable function, if we have one.
    try
        schemas = dig_get_menu( elements, cbinfo, varargin{:} );
    catch Ex
        % We should handle the case in which an error is thrown by
        % dig_get_menu and was not handled by dig_get_menu.
        schemas = dig_get_error_schema( 'container', Ex );
    end
end

% LocalWords: WHICHMENU CBINFO MENUFCN GATEFCN AUTODISABLEFCN AUTODISABLEGATEFCN 
% LocalWords: autodisable userdata cbinfo

% EOF
