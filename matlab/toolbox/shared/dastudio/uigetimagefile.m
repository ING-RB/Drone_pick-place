function [filename, userCanceled] = uigetimagefile(varargin)
%   UIGETIMAGEFILE Open Image dialog box.
%
%   This is a private copy of IMGETFILE to be used by DAStudio. The file
%   filter in our case is fixed and much simpler than the one used by 
%   IMGETFILE. We are interested in common image types which are used by 
%   html browsers and word processing applications.
%
%   [FILENAME, USER_CANCELED] = UIGETIMAGEFILE displays the Open Image 
%   dialog box for the user to fill in and returns the full path to the 
%   file selected in FILENAME. If the user presses the Cancel button,
%   USER_CANCELED will be TRUE. Otherwise, USER_CANCELED will be FALSE.
%
%   [FILENAME, USER_CANCELED] = UIGETIMAGEFILE(..., Name, Value) specifies
%   additional name-value pairs described below:
%
%   'MultiSelect'    A boolean scalar or a string used to specify the
%                    selection mode.  The value of true or 'on' turns 
%                    multiple selection on, and value of false or 'off' 
%                    turns multiple selection off. If multiple selection is
%                    turned on, the output parameter FILENAME is a cell
%                    array of strings containing the full paths to the
%                    selected files.
%                   
%                    Default: false
%   
%   The Open Image dialog box is modal; it blocks the MATLAB command line
%   until the user responds. 

%   Copyright 2013-2023 The MathWorks, Inc.

    persistent cached_path;

    % Create file chooser if necessary;
    if isempty(cached_path)
        cached_path = '';
    end

    % Get filter spec for image formats
    filterSpec = createImageFilterSpec();
    
    useMultiSelect = parseInputs(varargin{:});
    
    % Form string 'Get Image' vs. 'Get Images' based on whether or not MultiSelect
    % is enabled.
    multiSelect = strcmp(useMultiSelect,'on');
    dialogTitle = getString(message('mg:textedit:ImageInsertTitle'));
    
    [fname, pathname,filterindex] = uigetfile(filterSpec,...
                                    dialogTitle,...
                                    cached_path,...
                                    'MultiSelect',useMultiSelect);

    % If user successfully chose file, cache the path so that we can open the
    % dialog in the same directory the next time imgetfile is called.
    userCanceled = (filterindex == 0);
    if ~userCanceled
        cached_path = pathname;
        filename = fullfile(pathname, fname);
        if iscell(filename)
            % Remove invalid image files from the cell array
            for i=numel(filename):-1:1
                if ~GLUE2.Util.isValidImage(filename{i})
                    filename(i)=[];
                end
            end
            % If no files to return, pretend the user cancelled the dialog
            if numel(filename) == 0
                userCanceled = true;
            end
        elseif ~GLUE2.Util.isValidImage(filename)
            userCanceled = true;
        end
    end
        
    if userCanceled
        % If user cancelled, return empty {} or empty string depending on
        % MultiSelect state.
        if multiSelect
            filename = {};
        else
            filename = '';
        end
    end
end

%--------------------------------------------------------------------------
function filterSpec = createImageFilterSpec()
%   Creates filterSpec argument expected by uigetfile

%   Generate filterSpec cell array

    formats = {...
        '*.png',                    'Portable Network Graphics';...
        '*.bmp;*.dib;*.rle',        'Windows Bitmap';...
        '*.jpg;*.jpeg;*.jfif;*.jpe','JPEG File Interchange Format';...
        '*.gif;*.gfa',              'Graphics Interchange Format';...
        '*.tif;*.tiff',             'Tag Image File Format';...
        '*.svg',                    'Scalable Vector Graphics';...
    };

    nformats = length(formats);

    % Create "All Image Files" and "All Files" options
    filterSpec{ 1, 2 } = 'All Image Files';
    filterSpec{ nformats + 2, 1 } = '*.*';
    filterSpec{ nformats + 2, 2 } = 'All Files (*.*)';
    
    for i = 1:nformats
        extString = formats{i, 1};
        dscString = formats{i, 2};
        % Add current extension to "All Images" list
        if (i == 1)
            filterSpec{1,1} = extString;
        else
            filterSpec{1,1} = strcat(filterSpec{1,1}, ';', extString);
        end
        
        filterSpec{i+1,1} = extString;
        filterSpec{i+1,2} = strcat( dscString,' (', extString,')');
    end
end

%--------------------------------------------------------------------------
function useMultiSelect = parseInputs(varargin)
%   parameter parsing
    parser = inputParser;
    parser.addParamValue('MultiSelect', false, @checkMultiSelect);
    parser.parse(varargin{:});
    useMultiSelect = parser.Results.MultiSelect;

    if isnumeric(parser.Results.MultiSelect) || islogical(parser.Results.MultiSelect)
        if (parser.Results.MultiSelect)
            useMultiSelect = 'on';
        else
            useMultiSelect = 'off';
        end
    end
end

%--------------------------------------------------------------------------
function tf = checkMultiSelect(useMultiSelect)
    tf = true;
    validateattributes(useMultiSelect, {'logical', 'numeric', 'char'}, ...
        {'vector', 'nonsparse'}, ...
        mfilename, 'MultiSelect');
    if ischar(useMultiSelect)
        validatestring(useMultiSelect, {'on', 'off'}, mfilename, 'UseMultiSelect');
    else
        validateattributes(useMultiSelect, {'logical', 'numeric'}, {'scalar'}, ...
            mfilename, 'MultiSelect');
    end
end
