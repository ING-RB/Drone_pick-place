function schema = dig_get_schema( element, cbinfo, varargin )
% DIG_GET_SCHEMA converts a menu element and callback info into a
% ToolSchema. 
%   DIG_GET_SCHEMA ELEMENT CBINFO
%     A menu element may be one of:
%     - a ToolSchema generator
%     - a cell-array pair of ToolSchema generator and userdata
%     - the string 'separator'
%     This function requires that cbinfo allow replacing of userdata.
%
%   DIG_GET_SCHEMA ELEMENT CBINFO AUTODISABLEFCN
%     Same as above, except it also performs an auto-disable check with the
%     supplied autodisablefcn.
%
%   DIG_GET_SCHEMA ELEMENT CBINFO AUTODISABLEFCN AUTODISABLEGATE
%     Same as above, except it also performs an auto-disable check with the
%     supplied autodisablefcn and autodisablegate. The autodisablegate is a
%     function used to access functions that are in a private directory.
%
%   This function will always return either a valid ToolSchema or the word
%   'separator'.
%
%   See also private/dig_get_interface, private/dig_get_menu, private/dig_get_error_gen,
%   private/dig_get_error_schema
%
%   Copyright 2011 The MathWorks, Inc.
    assert( nargin >= 2 && nargin < 5 );

    schema = {};
    err = {};
    generator = {};
    userdata = {};
    % We support the following generator types
    % function_handle
    % { function_handle, userdata }
    % { string, string, userdata }
    % { { string, string }, userdata }
    switch class( element )
        case 'function_handle'
            % function_handle
            generator = element;
        case 'cell'
            if numel( element ) == 2
                if isa( element{1}, 'function_handle' )
                    % { function_handle, userdata }
                    generator = element{1};
                    userdata = element{2};
                elseif ischar( element{1} ) && ischar( element{2} )
                    % { string, string }
                    generator = element;
                elseif iscell( element{1} ) && numel( element{1} ) == 2 && ...
                        ischar( element{1}{1} ) && ischar( element{1}{2} )
                    % { { string, string }, userdata }
                    generator = element{1};
                    userdata = element{2};
                end
            elseif numel( element ) == 3 && ischar( element{1} ) && ischar( element{2} )
                % { string, string, userdata }
                generator = element(1:2);
                userdata = element{3};
            else
                err = loc_getException( 'dastudio:dig:bad_generator' );
            end
        case 'char'
            if strcmpi( element, 'separator' )
                schema = element;
            else
                err = loc_getException( 'dastudio:dig:bad_generator' );
            end
        otherwise
                err = loc_getException( 'dastudio:dig:bad_generator' );
    end    
    
    % if the generator exists, call it.
    if ~isempty( generator ) 
        old_userdata = cbinfo.userdata;
        cbinfo.userdata = userdata;
        
        try
            % generate the ToolSchema.
            % generator is either a function handle or a cell pair of
            % strings.
            if iscell( generator )
                if isempty( generator{1} )
                    schema = feval( generator{2}, cbinfo );
                else
                    schema = feval( generator{1}, generator{2}, cbinfo );
                end
            else
                schema = feval( generator, cbinfo );
            end
            
            if ~isa(schema, 'DAStudio.ToolSchema')
                ME = loc_getException( 'dastudio:dig:get_schema_error' );
                throw( ME );
            end
    
            % Perform custom filtering.
            loc_applyCustomFilters( schema, cbinfo );
            
            % Perform Auto-Disabling.
            loc_performAutoDisable( schema, cbinfo, varargin{:} );
        catch ME
            err = ME;
        end
        
        cbinfo.userdata = old_userdata; 
    end
    
    % If we got any error involving the actual generation of the
    % ToolSchema, we return an error schema. Any other errors should warn
    % gracefully.
    if ~isempty( err )
        schema = dig_get_error_schema( 'action', err );
    end
end

function err = loc_getException( id )
    msg = message( id );
    err = MException( 'dastudio:DIGError', msg.getString );
end

function loc_applyCustomFilters( schema, cbinfo )
    cm = DAStudio.CustomizationManager;
    custom_filters = cm.getCustomFilterFcns( schema.tag );
    
    % For each custom filter, modify the state of the schema, if necessary.
    for index = 1: length( custom_filters )
        try
            state = feval( custom_filters{ index }, cbinfo );
            switch lower( state )
                case 'hidden'
                    schema.state = 'Hidden';
                case 'disabled'
                    if strcmpi( schema.state, 'Enabled' )
                        schema.state = 'Disabled';
                    end
                case 'enabled'
                    % This just marks an acceptable return value so we can
                    % show warning if the return is not useful.
                otherwise
                    msg = message( 'dastudio:dig:bad_filter_return' );
                    warning( msg );
            end
        catch Ex %#ok<NASGU>
            % TODO: How can we get the Exception report to the user without
            % showing it during the message. Can we pass a link?
            msg = message( 'dastudio:dig:filter_error' );
            warning( msg );
        end
    end
end

function loc_performAutoDisable( schema, cbinfo, varargin )
    if nargin <= 2 || isempty( varargin{1} )
        return;
    end
    if strcmpi( schema.state, 'Enabled' )
        try
            state = 'Enabled';
            if nargin == 3
                autoDisableFcn = varargin{1};
                state = feval( autoDisableFcn, cbinfo, schema.autoDisableWhen );
            elseif nargin == 4
                autoDisableFcn = varargin{1};
                autoDisableGate = varargin{2};
                state = feval( autoDisableGate, autoDisableFcn, cbinfo, schema.autoDisableWhen );
            end

            switch lower( state )
                case 'enabled'
                case 'disabled'
                    schema.state = 'Disabled';
                case 'hidden'
                otherwise
                    msg = message( 'dastudio:dig:bad_auto_disable_return' );
                    warning( msg );                    
            end
        catch Ex %#ok<NASGU>
            % TODO: How can we get the Exception report to the user without
            % showing it during the message. Can we pass a link?
            msg = message( 'dastudio:dig:auto_disable_error' );
            warning( msg );              
        end
    end    
end

% LocalWords: CBINFO userdata cbinfo AUTODISABLEFCN autodisablefcn AUTODISABLEGATE
% LocalWords: autodisablegate 

% EOF
