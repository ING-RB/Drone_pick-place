function schema = dig_get_error_schema( type, err )
% DIG_GET_ERROR_SCHEMA takes a callback info and returns an error schema.
%
%   DIG_GET_ERROR_SCHEMA TYPE ERR
%     Returns either a ContainerSchema or an ActionSchema, depending
%     on whether TYPE is 'action' or 'container'. The ToolSchema returned
%     will have a callback that displays the error that is passed in ERR.
%
%   See also private/dig_get_error_gen, private/dig_get_interface,
%   private/dig_get_schema, private/dig_get_menu, MException.
%
%   Copyright 2011 The MathWorks, Inc.
    assert( nargin == 2 );
    
    % get the generator for the error schema.
    generator = dig_get_error_gen( type, err );
    
    % create a dummy cbinfo for rest.
    cbinfo = struct;
    cbinfo.userdata = err;
    
    % Call generator to produce the schema. We could call dig_get_schema,
    % but we want that function to be able to call this one in case it
    % errors. This one must ALWAYS return an error schema.
    schema = feval( generator{1}, cbinfo );
end

% LocalWords: cbinfo

% EOF
