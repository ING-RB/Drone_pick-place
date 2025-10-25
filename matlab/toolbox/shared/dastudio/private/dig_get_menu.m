function schemas = dig_get_menu( elements, cbinfo, varargin )
% DIG_GET_MENU converts a cell-array of schema generators into a cell-array
% of ToolSchemas. 
%
%   DIG_GET_MENU ELEMENTS CBINFO
%     The ELEMENTS cell-array must contain a list of valid schema generator 
%     elements. These may be:
%       - a function handle to a function that takes callback info and
%         returns a ToolSchema. We call these schema generator functions.
%       - a cell-array pair consisting of a schema generator function and its
%         associated userdata.
%       - the string 'separator'
%     The string 'separator' will be copied directly from the elements
%     array into the return array. All returned ToolSchemas will have been
%     custom filtered before being returned.
%
%   DIG_GET_MENU ELEMENTS CBINFO AUTODISABLEFCN
%     Same as above, except the AUTODISABLEFCN is used to determine if the
%     resulting schmas should be auto-disabled and their state is adjusted
%     accordingly.
%   DIG_GET_MENU ELEMENTS CBINFO AUTODISABLEFCN AUTODISABLEGATE
%     Same as above, except the AUTODISABLEGATE is used to access the
%     AUTODISABLEFCN if it resides in a private directory.
%
%   See also private/dig_get_schema, private/dig_get_interface, private/dig_get_error_gen,
%   private/dig_get_error_schema
%
%   Copyright 2011 The MathWorks, Inc.
    assert( nargin >= 2 && nargin < 5 );
    assert( iscell( elements ) );
    
    num_elements = length( elements );
    
    % Pre-create the results array to avoid looped resize.
    schemas = cell( 1, num_elements );
    
    % Since dig_get_schema handles any errors that come from attempting to
    % call a generator that doesn't exist, this code should not have to
    % try/catch.
    for index = 1:num_elements
        element = elements{index};
        schemas{ index } = dig_get_schema( element, cbinfo, varargin{:} );
    end
end

% LocalWords: CBINFO userdata AUTODISABLEFCN AUTODISABLEGATE cbinfo

% EOF
