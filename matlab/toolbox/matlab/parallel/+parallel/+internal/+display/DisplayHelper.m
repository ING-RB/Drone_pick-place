% DisplayHelper - helper for displaying properties

% Copyright 2011-2024 The MathWorks, Inc.

classdef (Hidden) DisplayHelper

    properties ( Constant, GetAccess = private )
        ColumnSeparator = '  ';
        LinePrefix = ' ';
        TableHeadingUnderline = '-';
        SubHeadingPrefix = '   ';
        SubHeadingPostfix = ': '; 
        TruncationString = '...';

        % The minimum length for property names (i.e. how
        % far across will the ":" be?
        MinPropNameLength = 20;
        % How wide each property's value will be
        MinValueDisplayWidth = 50;
        MaxDisplayWidth = 5000;

        % The maximum number of array items in a numeric array that will be
        % displayed
        MaxNumericArrayDisplayItems = 6;

        % The expected columns in the cell array of a table's column data
        ColumnsDataExpectedCell = {'Title', 'Resizeable', 'MinimumWidth'};
        % The first column that will be used for all vector displays
        IndexColumn = {'', true, length( '10' )};
        % Define a minimum column width for columns that are resizeable 
        % in the vector display.  Always make this length(truncationString) + 1
        MinResizeableColumnWidth = length( parallel.internal.display.DisplayHelper.TruncationString ) + 1;   
    end
    
    properties ( Constant )
      % Decide whether or not to display index columns on vector displays
        DisplayIndexColumn = true; 
        DoNotDisplayIndexColumn = false;
    end
    
    properties (GetAccess = private, SetAccess = immutable)
        % The longest property name that this displayer will display
        MaxPropNameLength
        % How far across in the command window a property's value starts.
        PropValueStartPosition
    end
    
    properties (Dependent, SetAccess = immutable)
        ShowLinks
    end
    
    methods

        function tf = get.ShowLinks(~)
            tf = feature('hotlinks');
        end
        
        function obj = DisplayHelper(lengthOfLongestPropName)
            import parallel.internal.display.DisplayHelper;
            validateattributes(lengthOfLongestPropName, {'numeric'}, {});
            obj.MaxPropNameLength = max(DisplayHelper.MinPropNameLength, lengthOfLongestPropName);
            % Take the ':' and space into consideration for the prop value
            % start
            obj.PropValueStartPosition = numel( DisplayHelper.LinePrefix ) + ...
                obj.MaxPropNameLength + 2;
        end
        
        function formattedString = formatCellStr( obj, aCellStr )
            % Format a cell string for display by indenting all lines apart
            % from the first line.
            if isempty( aCellStr )
                formattedString = {''};
                return;
            end
            if ~iscellstr( aCellStr ) %#ok<ISCLSTR> We definitely mean cellstr here.
                error(message('MATLAB:parallel:display:FormatCellStr'));
            end
            
            formattedString = aCellStr{1};
            if numel( aCellStr ) > 1
                % indent all lines except the first
                indentFcn = @(x) sprintf( '%s%s', repmat( ' ', obj.PropValueStartPosition, 1 ), x );
                indentedStrings = cellfun( indentFcn, aCellStr(2:end), ...
                    'UniformOutput', false );

                % and bung everything into a single string
                formattedString = sprintf( '%s\n%s%s', formattedString, ...
                    sprintf( '%s\n', indentedStrings{1:end-1} ), ...
                    indentedStrings{end} );
            end
        end

        function displayProperty( obj, name, value, doFormat )
            import parallel.internal.display.DisplayHelper;
            
            % Display a property.
            validateattributes( name, {'char'}, {} );
            if nargin < 4
                doFormat = true;
            end
            if ~( doFormat || ischar( value ) )
                error(message('MATLAB:parallel:display:UnexpectedFormatError'));
            end
            
            if doFormat
                displayVal = obj.formatValue( value );
            else
                displayVal = value;
            end
            
            padding = repmat(' ', max(obj.MaxPropNameLength - length(name), 0), 1);
            fprintf( '%s%s%s: %s\n', DisplayHelper.LinePrefix, padding, ...
                name, char( displayVal ));
        end
        
        function displayHTMLArray(obj, name, val)
            import parallel.internal.display.DisplayHelper;
            
            if isempty(val)
                valstr = '[]';
            elseif isvector(val) && numel(val) <= DisplayHelper.MaxNumericArrayDisplayItems
                % First do our normal formatting on the HTMLDisplayTypes
                displayHelperFormattedArray = obj.formatValue(val);
                % Then, call char on each formatted HTMLDisplayType to 
                % get the strings we want to display
                arrayOfLinks = arrayfun(@char, displayHelperFormattedArray, 'UniformOutput', false);
                % Finally print our array of HTML display strings with some
                % extra special formatting since we have an array of these
                % items. 
                valstr = sprintf( '[%s]', deblank( sprintf( '%s ', arrayOfLinks{:} ) ) );
            else
                lenstr = sprintf( '%dx', size(val) );
                try
                    % Normally we would expect all the values are able to be concatenated however
                    % it is conceivable that this could fail so we are being careful.
                    aggregateClassName = class( [val.DisplayValue] );
                catch %#ok<CTCH>
                    aggregateClassName = 'array';
                end
                valstr = sprintf( '[%s %s]', lenstr(1:end-1), aggregateClassName );
            end
            
            displayProperty(obj, name, valstr, false);
        end
        
        function wrappedText = wrapText( obj, origString, strLength )
            % Wrap text.  Always returns a cell array of each line of the
            % wrapped text.
            if isempty( origString )
                wrappedText = {''};
                return;
            end
            validateattributes( origString, {'char'}, {} );
            if nargin < 3
                strLength = obj.getMaxValueLength();
            end

            % break up based on linefeed (returns original if none found)
            wrappedText = strsplit( origString, newline );

            % otherwise if there is no linefeed then break up based on the
            % number of characters
            if isscalar( wrappedText )
                wrappedText = textwrap( {origString}, strLength );
            end
        end
        
        function displayTable( obj, columns, data, displayIndexColumn )
            import parallel.internal.display.DisplayHelper;
            % Displays a table of data
            validateattributes( columns, {'cell'}, {'nonempty', 'ncols', numel( DisplayHelper.ColumnsDataExpectedCell )} );
            validateattributes( data, {'cell'}, {'nonempty', 'ncols', size( columns, 1 )} );
            if displayIndexColumn              
                [columns, data] = iAddIndexColumn( columns, data );
            end
            [headingStrings, dataStrings, columnWidths] = obj.formatTable( columns, data );

            numColumns = numel( headingStrings );
            % Prefix each column appropriately
            prefixCell = repmat({DisplayHelper.ColumnSeparator}, 1, numColumns);
            prefixCell{1} = DisplayHelper.LinePrefix;

            cellfun(@(x, y) fprintf('%s%s', x, y), prefixCell, headingStrings);
            fprintf('\n')
            % Follow with an underline which does not appear over the first
            % column. So, we remove the underline from the line prefix, the
            % first column and the column separator between the first and 
            % second columns. 
            underlineLength = sum(columnWidths(2:end)) + ...
                (numColumns - 2) * length(DisplayHelper.ColumnSeparator);
            % Then we print the line prefix, a blank space the width of the
            % first column, and a column separator before starting the
            % underline. The underline will look like:
            % LinePrefix|Column1|separator|column2|separator... separator|columnN
            %                              --------------------------------------  
            fprintf('%s%s%s%s\n', DisplayHelper.LinePrefix, ...
                repmat(' ', 1, columnWidths(1)), DisplayHelper.ColumnSeparator,...
                repmat(DisplayHelper.TableHeadingUnderline, 1, underlineLength));
            % and then each row of data
            for ii = 1:size( data, 1 )
                cellfun(@(x, y) fprintf('%s%s', x, y), prefixCell, dataStrings(ii, :));
                fprintf('\n');
            end
        end

        function formattedString = formatDateTime( ~, timestamp )
            % The time is stored in a MATLAB datetime object
            % Use the default (locale-specific) settings for displaying it
            if isempty( timestamp )
                formattedString = '';
                return;
            end
            validateattributes( timestamp, {'datetime'}, {'nonempty'} );
            formattedString = char( timestamp );
        end

        function formattedString = formatBytes( ~, numBytes )
            if numBytes < 1024
                formattedString = sprintf("%d B", numBytes);
            elseif numBytes < 1024^2
                formattedString = sprintf("%d KB", ceil(numBytes / 1024));
            elseif numBytes <= 1024^3
                formattedString = sprintf("%s MB", iTwoDecimalsShort(numBytes / 1024^2));
            elseif numBytes <= 1024^4
                formattedString = sprintf("%s GB", iTwoDecimalsShort(numBytes / 1024^3));
            else
                formattedString = sprintf("%s TB", iTwoDecimalsShort(numBytes / 1024^4));
            end
        end
           
        function displayMainHeading( ~, headingString, varargin )
            % Display the main heading
            import parallel.internal.display.DisplayHelper;
            validateattributes( headingString, {'char'}, {'row'} );
            headingString = sprintf( headingString, varargin{:} );
            fprintf( '%s%s\n', DisplayHelper.LinePrefix, headingString );
        end

        function displaySubHeading( ~, headingString, varargin )
            % Display a sub-heading
            import parallel.internal.display.DisplayHelper;
            validateattributes( headingString, {'char'}, {'row'} );
            headingString = sprintf( headingString, varargin{:} );
            fprintf( '\n%s%s%s%s\n\n', DisplayHelper.LinePrefix, ...
                 DisplayHelper.SubHeadingPrefix, headingString, ...
                 DisplayHelper.SubHeadingPostfix);
        end
        
        function dimensionString = formatDimension( obj, dimension, classDocLink )
            % Generates the correct string to display the object array
            % dimensions and name.
            dimensionString = formatDimensionTextOnly( obj, dimension, classDocLink );
            dimensionString = sprintf( '%s:\n', dimensionString);
        end
        
        function dimensionString = formatDimensionTextOnly( obj, dimension, classDocLink )
            % Generates the correct string that can be used to display the object array
            import parallel.internal.display.DisplayHelper;
            validateattributes( classDocLink, {'char'}, {'row'} );
            dimStr = makeDimensionString(obj, dimension );
            dimensionString = sprintf( '%s%s', DisplayHelper.LinePrefix, ...
                getString(message('MATLAB:parallel:display:NonScalarArrayHeader',dimStr, classDocLink)) );
        end
        
        function dimensionString = formatEmptyDimension( obj, dimension, classDocLink )
            % Generates the correct string to display the empty object
            % dimensions and name.
            import parallel.internal.display.DisplayHelper;
            validateattributes( classDocLink, {'char'}, {'row'} );
            dimStr = makeDimensionString(obj, dimension );
            dimensionString = sprintf( '%s%s %s', DisplayHelper.LinePrefix, dimStr, classDocLink );
        end
 
        function dimStrLength = displayDimension( obj, dimension, classDocLink )
            % Display a string that looks something like 
            % "3x1 Cluster array: " 
            import parallel.internal.display.DisplayHelper;
            validateattributes( dimension, {'numeric'}, {'vector'} );
            validateattributes( classDocLink, {'char'}, {'row'} );
            if numel(dimension) < 2
                error(message('MATLAB:parallel:display:TooFewDimensionsToFormat'));
            end
                
            dimStr = obj.formatDimension( dimension, classDocLink );
            fprintf('%s', dimStr);
            dimStrLength = length(dimStr);
        end

        function displayDimensionHeading( obj, dimension, classDocLink )
            import parallel.internal.display.DisplayHelper;
            % Display a heading that looks something like 
            % "3x1 Cluster array: " 
            obj.displayDimension( dimension, classDocLink );
            fprintf( '%s\n', DisplayHelper.LinePrefix);
        end

        function duration = getRunningDuration( obj, duration )
            durationInSecs = seconds(duration);
            duration = obj.formatDuration(durationInSecs);
        end
        
        function displayPropertyGroupSeparator(~)
            fprintf('\n');
        end
        
        function dataLocToDisp = formatJobStorageLocation( obj , jobStorageLocationValue)
            if isstruct(jobStorageLocationValue)
                if ispc
                    currLoc = jobStorageLocationValue.windows;
                    otherLoc = sprintf('(Unix: %s)', jobStorageLocationValue.unix);
                else
                    currLoc = jobStorageLocationValue.unix;
                    otherLoc = sprintf('(Windows: %s)', jobStorageLocationValue.windows);
                end
                dataLocToDisp = obj.formatCellStr({currLoc, otherLoc});
            else
                dataLocToDisp = jobStorageLocationValue;
            end
        end

        function tableTextToDisp = formatTableText(~, tableText)
            % Tables can't have newlines in their text data as it
            % would break the table formatting. So we simply
            % remove them. See g1234075.
            tableTextToDisp = strrep(tableText, newline(), ' ');
        end

    end

    methods (Access = private)
        function dimStr = makeDimensionString( ~, dimension )
            % Generates the array dimension with the correct object name
            
            validateattributes( dimension, {'numeric'}, {'vector'} );
            
            if numel(dimension) < 2
                error(message('MATLAB:parallel:display:TooFewDimensionsToFormat'));
            end
            switch length( dimension )
                case {2 3 4}
                    % Use vectorized sprintf and strip the last char ('x')
                    dimStr = sprintf( '%dx', dimension );
                    dimStr = dimStr(1:end-1);
                otherwise
                    dimStr = [num2str( length( dimension ) ) '-D'];
            end
        end
        
        function strLength = getMaxValueLength( obj )
            import parallel.internal.display.DisplayHelper;
            % Gets the maximum length for the value string.  i.e. the
            % max length on the RHS of the :
            displayWidth = iGetDisplayWidth( DisplayHelper.MinValueDisplayWidth, DisplayHelper.MaxDisplayWidth );
            strLength = displayWidth - obj.PropValueStartPosition;
            strLength = max(strLength, DisplayHelper.MinValueDisplayWidth);
        end
        
        % The guarantee of formatValue is to return an object on which you
        % may call length and char (ONLY). The length will be the length of
        % the textual display of the object, and char will be a string
        % suitable for display in the MATLAB command window. You may NOT
        % make any other assumptions about the return of this method.
        function val = formatValue( obj, val, valDisplayLength )
            if nargin < 3
                valDisplayLength = obj.getMaxValueLength();
            end
                          
            if ~isa(val, 'parallel.internal.display.DisplayType')
                % Wrap any values that are not already DisplayType in a
                % "BuiltInDisplayType". When used with formatDispatcher and
                % @formatBaseType, this DisplayType is actually capable of
                % providing a char vector for all types since formatBaseType
                % has a fall-back for types it doesn't know how to format.
                val = parallel.internal.display.BuiltInDisplayType(val);
            end
            
            val = formatDispatcher( val, obj, valDisplayLength, @formatBaseType );
        end
        
        function valstr = formatBaseType( obj, val, valDisplayLength )
            % Generic formatting of a value.
            if isnumeric( val )
                valstr = iFormatNumericArray( val );
            elseif isempty( val ) && iscell( val )
                valstr = '{}';   
            elseif islogical( val ) && isscalar( val )
                if val
                    valstr = 'true';
                else
                    valstr = 'false';
                end
            elseif isa( val, 'function_handle' )
                valstr = func2str( val );
                if length( valstr ) >= 1 && valstr(1) ~= '@'
                    valstr = ['@' valstr];
                end
            elseif ischar( val )
                valstr = obj.truncateEnd( val, valDisplayLength );
            elseif iscellstr( val ) || (isstring(val) && ~isscalar(val))
                % NB cell arrays of strings are truncated at the beginning
                % Currently this corresponds to AttachedFiles and AdditionalPaths
                truncatedStrings = cellfun( @(x) obj.truncateBeginning( x, valDisplayLength ), ...
                    val, 'UniformOutput', false );
                valstr = obj.formatCellStr( truncatedStrings );
            elseif isscalar(val) && (isstring(val) || ismethod( val, 'char' ))
                % Convert to a char if this makes sense
                valstr = obj.truncateEnd( char( val ), valDisplayLength );
            else
                valstr = iFormatArrayDimension( val );
            end
        end
        
        function [headingStrings, dataStrings, columnWidths] = formatTable( obj, columns, data )
            import parallel.internal.display.DisplayHelper;
            % NB don't allow any truncation at this point for the formatted values
            % as we'll be truncating later on.
            columnTitles = columns(:,1);
            columnTitles = columnTitles(:)';
            resizeableCols = columns(:,2);
            resizeableCols = [resizeableCols{:}];
            minColumnWidths = columns(:,3);
            minColumnWidths = [minColumnWidths{:}];
            % Replace all resizeable columns with a minColumnWidth that is at least
            % as wide as DisplayHelper.MinResizeableColumnWidth
            minColumnWidths(resizeableCols) = max( DisplayHelper.MinResizeableColumnWidth, ...
                minColumnWidths(resizeableCols) );
             
            formattedData = cellfun( @(x) obj.formatValue(x, inf), data, 'UniformOutput', false );
          
            % work out the desired column widths based on the contents
            maxColumnWidths = max( max( cellfun( @length, formattedData ), [], 1 ), ...
                minColumnWidths );
            desiredResizeAmount = max( ( maxColumnWidths - minColumnWidths ) .* resizeableCols, 0 );
         
            % Take the space required for the column separators and line prefix
            % into account for the min display width
            numColumns = size( columns, 1 );
            minDisplayWidth = sum( minColumnWidths ) + numel( DisplayHelper.LinePrefix ) ...
                + numel( DisplayHelper.ColumnSeparator ) * ( numColumns - 1 );
            displayWidth = iGetDisplayWidth(minDisplayWidth, DisplayHelper.MaxDisplayWidth);

            if sum( desiredResizeAmount ) == 0 || displayWidth == minDisplayWidth
                % Nothing needs resizing, so stick with the specified
                % column widths.
                columnWidths = minColumnWidths;
            elseif minDisplayWidth + sum( desiredResizeAmount ) < displayWidth
                % Enough room to resize everything, so just do it.
                columnWidths = minColumnWidths + desiredResizeAmount;
            else
                % Adjust everything to fit as best we can.
                availableResizeAmount = displayWidth - minDisplayWidth;
                resizeAmount = floor( desiredResizeAmount ./ sum( desiredResizeAmount ) ...
                    .* availableResizeAmount );
                columnWidths = minColumnWidths + resizeAmount;
            end
           
            % Now format the table, truncating and padding out as required.
            headingStrings = cell( 1, numColumns );
            dataStrings = cell( size(formattedData));
            for ii = 1:numColumns
                headingStrings{ii} = obj.truncateOrPad( columnTitles{ii}, columnWidths(ii) );
                dataStrings(:, ii) = cellfun( @(x) obj.truncateOrPad(x, columnWidths(ii)), ...
                    formattedData(:,ii), 'UniformOutput', false );
            end
        end      
        
        function stringToDisplay = truncateOrPad(obj, data, width)
                    
            if length(data) <= width
                %pad
                padding = repmat(' ', max(width - length(data), 0), 1);
                stringToDisplay = sprintf('%s%s', padding, char(data));
            else
                %truncate
                truncatedData = obj.truncateEnd(data, width);
                stringToDisplay = char(truncatedData);
            end
            
        end
        
        function data = truncateBeginning( obj, data, truncLength ) %#ok<*DEFNU>
            import parallel.internal.display.DisplayHelper;
            % Truncate a display string at the beginning and return the
            % display item
            if nargin < 3
                truncLength = obj.getMaxValueLength();
            end
            
            if length( data ) <= truncLength
                return
            end
            
            truncateOffsetFromEnd = truncLength - numel( DisplayHelper.TruncationString ) - 1;
            
            [ string, setter ] = iGetStringDataAndSetter( data );
            
            truncatedString = sprintf( '%s%s', DisplayHelper.TruncationString, string(end - truncateOffsetFromEnd:end));
            data = setter( data, truncatedString );
            
        end
        
        
        function data = truncateEnd( obj, data, truncLength )
            import parallel.internal.display.DisplayHelper;
            % Truncate a display string at the end and return the
            % display item
            if nargin < 3
                truncLength = obj.getMaxValueLength();
            end
            
            if length( data ) <= truncLength
                return
            end
            
            [ string, setter ] = iGetStringDataAndSetter( data );
            
            truncatedString = [ string(1:truncLength-length(obj.TruncationString)), obj.TruncationString ];
            data = setter( data, truncatedString );
            
        end
        
    end

    methods (Static)
        function warningsList = formatWarningsList(warnings)
            warningMessages = arrayfun( ...
                @(x) message('MATLAB:parallel:display:WarningsListItem', x.message).getString(), ...
                warnings, 'UniformOutput', false);
            warningsList = sprintf('  %s\n', warningMessages{:});
        end

        function durationStr = formatDuration(durationInSecs)
            validateattributes( durationInSecs, {'numeric'}, {'scalar'} );
            % Formats a duration in seconds into a helpful string
            if durationInSecs <= 0
                days = 0;
                hours = 0;
                mins = 0;
                secs = 0;
            else
                % Convert running duration to a readable format
                secPerMin = 60;
                secPerHour = 60*60;
                secPerDay = 24*secPerHour;

                days = floor( durationInSecs / secPerDay );
                remainingSecs = durationInSecs - days * secPerDay;

                hours = floor( remainingSecs / secPerHour );
                remainingSecs = remainingSecs - hours*secPerHour;

                mins = floor( remainingSecs / secPerMin );
                secs = floor( remainingSecs - mins*secPerMin );
            end

            durationStr = sprintf( '%d days %dh %dm %ds', days, hours, mins, secs );
        end
    end
    
end


%------------------------------------------------------------
function valstr = iFormatArrayDimension( val )
% Formats the dimension of an array.
lenstr = sprintf( '%dx', size( val ) );
valstr = sprintf( '[%s %s]', lenstr(1:end-1), class( val ) );
end

%------------------------------------------------------------
function valstr = iFormatNumericArray( val )
% Formats a numeric array for display
import parallel.internal.display.DisplayHelper;
if isscalar( val )
    valstr = num2str( val );
elseif isequal(val, [])
    valstr = '[]';
elseif isvector( val ) && numel( val ) <= DisplayHelper.MaxNumericArrayDisplayItems
    valstr = sprintf( '[%s]', strtrim( sprintf( '%d ', val ) ) );
else
    valstr = iFormatArrayDimension( val );
end
end

%------------------------------------------------------------
function displayWidth = iGetDisplayWidth( minWidth, maxWidth )
% Get the display width to use for display.  If the current command
% window size is between minWidth and maxWidth, then the current
% window size is used.  Otherwise, the supplied minWidth is used.
cmdWSize = minWidth;
try
    cmdWSize = distcomp.dctCmdWindowSize();
catch err
end
displayWidth = max( minWidth, min( cmdWSize, maxWidth ) );
end

%------------------------------------------------------------
function [columns, data] = iAddIndexColumn( columns, data )
% Adds an index column to the beginning of a table
import parallel.internal.display.DisplayHelper;
columns = [DisplayHelper.IndexColumn; columns];
columnIndex = num2cell(1:size(data, 1));
data = [columnIndex', data];
end
%------------------------------------------------------------
function [ string, setter ] = iGetStringDataAndSetter( data )
if isa(data, 'parallel.internal.display.DisplayType')
    string = data.DisplayValue;
    setter = @iDisplayTypeSet;
else
    string = data;
    setter = @(~, newString) newString;
end
end
%------------------------------------------------------------
function value = iDisplayTypeSet( value, newString )
    value.DisplayValue = newString;
end
%------------------------------------------------------------
function text = iTwoDecimalsShort(number)
    text = sprintf('%1.2f', number);
    while endsWith(text, '0')
        text = text(1:end-1);
    end
    if endsWith(text, '.')
        text = text(1:end-1);
    end
end

