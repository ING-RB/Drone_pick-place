function toolbars = dig_get_toolbars( generators, cbinfo, varargin )
% DIG_GET_TOOLBARS Called by DigManager to return a cell-array of the form:
% { { ToolBar1, { ToolItem11, ..., ToolItem1N1 }, { ToolBarItemGen11, ..., ToolBarItemGen1N1 } }, ...
%   { ToolBar2, { ToolItem21, ..., ToolItem2N2 }, { ToolBarItemGen21, ..., ToolBarItemGen2N2 } }, ...
%   ...
% }
% 
%   DIG_GET_TOOLBARS CBINFO MENUFCN GATEFCN
%     calls gateFcn( menuFcn, 'ToolBars', cbinfo ) if gateFcn exists and is 
%     non-empty. This returns the cell-array of valid generators for the
%     toolbars. Then it gets the children and calls dig_get_menu on them to
%     get a list of children ToolSchemas. All of these are packaged up in
%     the aforementioned cell-array
%
%   DIG_GET_INTERFACE CBINFO MENUFCN GATEFCN AUTODISABLEFCN
%     Same as above, except AUTODISABLEFCN is used to check autodisable for
%     generated toolschemas.
%
%   DIG_GET_TOOLBARS CBINFO MENUFCN GATEFCN AUTODISABLEFCN AUTDISABLEGATE
%   Same as the previous version, except AUTODISABLEGATE is used to access
%   an AUTODISABLEFCN that resides in a private directory.
%
%   See also private/dig_get_schema, private/dig_get_menu, private/dig_get_interface,
%   private/dig_get_error_gen, private/dig_get_error_schema
%
%   Copyright 2011 The MathWorks, Inc.
    % Do some validation here. We are expecting a cell array of generators.
    schemas = dig_get_menu( generators, cbinfo, varargin{:} );
        
    num_toolbars = length( schemas );
    
    toolbars = cell( 1, num_toolbars );
    
    for index = 1:num_toolbars
        schema = schemas{ index };
        % Some error schemas come in the form of ActionSchemas. We need to
        % wrap these in a container for display. Error schemas that are
        % Containers already will be handled by the normal code.
        if isa( schema, 'DAStudio.ActionSchema' ) && strcmp( schema.tag, 'DIG:ErrorItem' )
            toolbars{ index } = loc_createToolBarFromErrorSchema( schema, cbinfo );
        elseif ~isa( schema, 'DAStudio.ContainerSchema' )
            toolbars{ index } = loc_createToolBarFromErrorId( 'dastudio:dig:toolbar_not_container', cbinfo );          
        else
            if ~isempty( schema.childrenFcns )
                childrenFcns = schema.childrenFcns;
            elseif ~isempty( schema.generateFcn ) || isa( schema.generateFcn, 'function_handle' )
                old_userdata = cbinfo.userdata;
                cbinfo.userdata = schema.userdata;
                
                childrenFcns = schema.generateFcn( cbinfo );
                    
                cbinfo.userdata = old_userdata;
            else
                % no children functions??? that's no good.
                toolbars{ index } = loc_createToolBarFromErrorId( 'dastudio:dig:toolbar_without_children_fcns', cbinfo );
                continue;
            end
            
            if nargin < 4
                children = dig_get_menu( childrenFcns, cbinfo );
            else
                children = dig_get_menu( childrenFcns, cbinfo, varargin{:} );
            end
            
            if isempty( children )
                toolbars{ index } = loc_createToolBarFromErrorId( 'dastudio:dig:toolbar_without_children', cbinfo );
            else
                toolbars{ index } = { schema, children, childrenFcns };
            end
        end
    end
end

function error_result = loc_createToolBarFromErrorSchema( schema, cbinfo )
    error_result = loc_createToolBarFromError( schema.userdata, cbinfo );
end

function error_result = loc_createToolBarFromError( err, cbinfo )
    error_toolbar = dig_get_error_schema( 'container', err );
    error_gen = error_toolbar.childrenFcns{1};
    error_schema = dig_get_schema( error_gen, cbinfo );
    error_result = { error_toolbar, { error_schema }, { error_gen } };
end

function error_result = loc_createToolBarFromErrorId( id, cbinfo )
    err = loc_getException( id );
    error_result = loc_createToolBarFromError( err, cbinfo );
end

function err = loc_getException( id, varargin )
    msg = message( id, varargin{:} );
    err = MException( 'dastudio:DIGError', msg.getString );
end

% LocalWords: CBINFO MENUFCN GATEFCN cbinfo AUTODISABLEFCN autodisable toolschemas
% lOCALwORDS: AUTDISABLEGATE

% EOF
