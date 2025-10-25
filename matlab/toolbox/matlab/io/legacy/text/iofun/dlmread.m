function result= dlmread(filename,delimiter,r,c,range)

import matlab.io.internal.legacy.guessdelim;
fid = -1;
if nargin==0
    error(message('MATLAB:dlmread:Nargin'));
end

% Get Filename
if ~ischar(filename) && ~(isstring(filename) && isscalar(filename))
    error(message('MATLAB:dlmread:InvalidInputType'));
end
filename = char(filename);

% Get Delimiter
if nargin==1 % Guess default delimiter
    [fid, theMessage] = fopen(filename);
    if fid < 0
        error(message('MATLAB:dlmread:FileNotOpened', filename, theMessage));
    end
    str = fread(fid, 4096,'*char')';
    frewind(fid);
    delimiter = guessdelim(str);
    if isspace(delimiter)
        delimiter = '';
    end
else
    delimiter = sprintf(delimiter); % Interpret \t (if necessary)
    delimiter = char(delimiter);
end
if length(delimiter) > 1
    error(message('MATLAB:dlmread:InvalidDelimiter'));
end

% Get row and column offsets
offset = 0;
if nargin<=2 % dlmread(file) or dlmread(file,dim)
    r = 0;
    c = 0;
    nrows = -1; % Read all rows
    range = [];
elseif nargin==3 % dlmread(file,delimiter,range)
    range = r;
    if ischar(range) || (isstring(range) && isscalar(range))
        range = char(range);
        range = local_str2rng(range);
    elseif length(r)==1 % Catch obsolete syntax dlmread(file,delimiter,r)
        warning(message('MATLAB:dlmread:ObsoleteSyntax'));
        result= dlmread(filename,delimiter,r,0);
        return
    end
    r = range(1);
    c = range(2);
    nrows = range(3) - range(1) + 1;
elseif nargin==4 % dlmread(file,delimiter,r,c)
    nrows = -1; % Read all rows
    range = [];
elseif nargin==5 % obsolete syntax dlmread(file,delimiter,r,c,range)
    if ischar(range) || (isstring(range) && isscalar(range))
        range = char(range);
        range = local_str2rng(range);
    end
    rold = r; cold = c;
    if r > range(3) || c > range(4), result= []; return, end
    if r ~= range(1) || c ~= range(2)
        warning(message('MATLAB:dlmread:InvalidRowsAndColumns'))
        offset = 1;
    end
    % For compatibility
    r = max(range(1),r);
    c = max(range(2),c);
    nrows = range(3) - r + 1;
end

% attempt to open data file
if fid == -1
    [fid, theMessage] = fopen(filename);
    if fid < 0
        error(message('MATLAB:dlmread:FileNotOpened', filename, theMessage));
    end
end

% Read the file using textscan
try
    tsargs = {...
        'HeaderLines',r,...
        'HeaderColumns',c,...
        'ReturnOnError',false,...
        'EmptyValue',0,...
        'CollectOutput',true,...
        'EndOfLine','\r\n'};

    if ~isempty(delimiter)
        delimiter = sprintf(delimiter);
        delimiter = char(delimiter);
        whitespace = setdiff(sprintf(' \b\t'),delimiter);
        tsargs = [tsargs, {'Delimiter',delimiter,'Whitespace',whitespace}];
    end

    result  = textscan(fid,'',nrows,tsargs{:});

catch exception
    fclose(fid);
    throw(exception);
end

% close data file
fclose(fid);
result = result{1};
% textscan only trims leading columns, trailing columns may need clipping
if ~isempty(range)
    ncols = range(4) - range(2) + 1;

    % adjust ncols if necessary
    if ncols ~= size(result,2)
        result= result(:,1:ncols);
    end
end

% num rows should be correct, textscan clips
if nrows > 0 && nrows ~= size(result,1)
    error(message('MATLAB:dlmread:InternalSizeMismatch'))
end


% When passed in 5 args, we have an offset and a range.  If the offset is
% not equal to the top left corner of the range the user wanted to read
% range Ai..Bj and start looking in that matrix at rold and cold.  For
% backwards compatibility we create a result the same size as the specified
% range and place the data in the result at the requested offset.

% For example, given a file with [1 2 3; 4 5 6], reading A1..C2 with offset
% 1,2 produces this result:
% 0 0 0
% 0 5 6

if nargin==5 && offset
    rowIndex = rold+1:rold+nrows;
    columnIndex = cold+1:cold+ncols;
    if rold == 0
        rowIndex = rowIndex + 1;
    end
    if cold == 0
        columnIndex = columnIndex + 1;
    end

    % assign into a new matrix of the desired size
    % need to create temp matrix here cuz we want the
    % offset region filled with zeros
    new_result(rowIndex,columnIndex) = result;
    result = new_result;
end

function m=local_str2rng(str)
m = [];

% convert to upper case
str = upper(str);

% parse the upper-left and bottom-right cell locations
k = strfind(str,'..');
if length(k)~=1, return; end % Couldn't find '..'

ulc = str(1:k-1);
brc = str(k+2:end);

% get upper-left col
k = find(~isletter(ulc), 1 );
if isempty(k) || k<2, return; end
topl(2) = sum(cumprod([1 26*ones(1,k-2)]).*(ulc(k-1:-1:1)-'A'+1))-1;
topl(1) = str2double(ulc(k:end))-1;

% get bottom-right col
k = find(~isletter(brc), 1 );
if isempty(k) || k<2, return; end
botr(2) = sum(cumprod([1 26*ones(1,k-2)]).*(brc(k-1:-1:1)-'A'+1))-1;
botr(1) = str2double(brc(k:end))-1;

m=[topl botr];

%   Copyright 1984-2024 The MathWorks, Inc.
