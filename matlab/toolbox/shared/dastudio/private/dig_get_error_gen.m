function generator = dig_get_error_gen( type, err )
% DIG_GET_ERROR_GEN takes a callback info and returns a generator for an error
% schema. 
%
%   DIG_GET_ERROR_GEN TYPE ERR
%     Returns a generator for either a ContainerSchema or an ActionSchema, 
%     depending on whether TYPE is 'action' or 'container'. The generator
%     consists of a cell-array pair, the first entry of which is a schema
%     generator for an ErrorSchema and the second of which is Err, the 
%     MException associated with this error.
%
%   See also private/dig_get_error_schema, private/dig_get_interface,
%   private/dig_get_schema, private/dig_get_menu, MException.
%
%   Copyright 2011 The MathWorks, Inc.
    assert( nargin == 2);
    
    % Make sure that cbinfo.userdata is an MException, if not, create one.
    if isempty( err ) || ~isa( err, 'MException' )
        % We need to create a generic exception to place here.
        err = loc_createGenericException;
    end
    
    switch type
        case 'container'
            generator = { @loc_ErrorMenu, err };
        case 'action'
            generator = { @loc_ErrorItem, err };
        otherwise
            % Assume container. We don't want to throw errors.
            generator = { @loc_ErrorMenu, err };
    end
end

% Error schema generators.
function schema = loc_ErrorMenu( cbinfo )
    schema = DAStudio.ContainerSchema;
    % TODO: Make a more generic string
    schema.label = DAStudio.message('dastudio:studio:DIGError'); 
    schema.tag = 'DIG:ErrorMenu';
    schema.childrenFcns = { { @loc_ErrorItem, cbinfo.userdata } };  
    schema.autoDisableWhen = 'Never';
end

function schema = loc_ErrorItem( cbinfo )
    schema = DAStudio.ActionSchema;
    schema.label = DAStudio.message('dastudio:studio:DIGErrorPrintSchemaTree');
    schema.tag = 'DIG:ErrorItem';
    schema.userdata = cbinfo.userdata;
    schema.callback = @loc_ErrorItemCB;    
    schema.autoDisableWhen = 'Never';
end

function loc_ErrorItemCB( cbinfo )
    err = cbinfo.userdata;
    disp(err.getReport);
end

function ex = loc_createGenericException
    msg = message( 'dastudio:dig:unknown_generation_error' );
    ex = MException( 'dastudio:DIGError', msg.getString );
end

% LocalWords: cbinfo userdata 

% EOF
