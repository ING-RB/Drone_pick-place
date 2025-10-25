function dlmwrite(filename, m, varargin)

if nargin < 2
    error(message('MATLAB:dlmwrite:Nargin'));
end

if ~ischar(filename) && ~isstring(filename)
    error(message('MATLAB:dlmwrite:InputClass'));
end

try
    %We support having cell arrays be printed out.  Thus, if we get a cell
    %array, with the same type in it, we will convert to a matrix.
    if (iscell(m))
        try
            m = cell2mat(m);
        catch
            error(message('MATLAB:dlmwrite:CellArrayMismatch'));
        end
    end

    [dlm,r,c,NEWLINE,precn,append] = ...
        parseinput(length(varargin),varargin);
    % construct complex precision string from specified format string
    precnIsNumeric = isnumeric(precn);
    if ischar(precn)
        cpxprec = [precn strrep(precn,'%','%+') 'i'];
    end
    % set flag for char array to export
    isCharArray = ischar(m);
catch exception
    throw(exception);
end

% open the file
if append
    fid = fopen(filename ,'Ab');
else
    fid = fopen(filename ,'Wb');
end

% validate successful opening of file
if fid == (-1)
    error(message('MATLAB:dlmwrite:FileOpenFailure', filename));
end

% find size of matrix
[br,bc] = size(m);

% start with offsetting row of matrix
for i = 1:r
    for j = 1:bc+c-1
        fwrite(fid, dlm, 'uchar'); % write empty field
    end
    fwrite(fid, NEWLINE, 'char'); % terminate this line
end

% start dumping the array, for now number format float

realdata = isreal(m);
useVectorized = realdata && precnIsNumeric && ~contains('%\',dlm) ...
    && isscalar(dlm);
if useVectorized
    format = sprintf('%%.%dg%s',precn,dlm);
end
if isCharArray
    vectorizedChar = ~contains('%\',dlm) && isscalar(dlm);
    format = sprintf('%%c%c',dlm);
end
for i = 1:br
    % start with offsetting col of matrix
    if c
        for j = 1:c
            fwrite(fid, dlm, 'uchar'); % write empty field
        end
    end
    if isCharArray
        if vectorizedChar
            str = sprintf(format,m(i,:));
            str = str(1:end-1);
            fwrite(fid, str, 'uchar');
        else
            for j = 1:bc-1  % maybe only write once to file...
                fwrite(fid, [m(i,j),dlm], 'uchar'); % write delimiter
            end
            fwrite(fid, m(i,bc), 'uchar');
        end
    elseif useVectorized
        str = sprintf(format,m(i,:));
        % strip off the last delimiter
        str = str(1:end-1);
        fwrite(fid, str, 'uchar');
    else
        rowIsReal = isreal(m(i,:));
        for j = 1:bc
            if rowIsReal || isreal(m(i,j))
                % print real numbers
                if precnIsNumeric
                    % use default precision or precision specified. Print as float
                    str = sprintf('%.*g',precn,m(i,j));
                else
                    % use specified format string
                    str = sprintf(precn,m(i,j));
                end
            else
                % print complex numbers
                if precnIsNumeric
                    % use default precision or precision specified. Print as float
                    str = sprintf('%.*g%+.*gi',precn,real(m(i,j)),precn,imag(m(i,j)));
                else
                    % use complex precision string
                    str = sprintf(cpxprec,real(m(i,j)),imag(m(i,j)));
                end
            end

            if(j < bc)
                str = [str,dlm]; %#ok<AGROW>
            end
            fwrite(fid, str, 'uchar');
        end
    end
    fwrite(fid, NEWLINE, 'char'); % terminate this line
end

% close file
fclose(fid);
end

function [dlm,r,c,nl,precn,appendmode] = parseinput(options,varargin)

% initialise parameters
dlm = ',';
r = 0;
c = 0;
precn = 5;
appendmode = false;
nl = newline;

if options > 0

    % define input attribute strings
    delimiter = 'delimiter';
    lineterminator = 'newline';
    rowoffset = 'roffset';
    coloffset = 'coffset';
    precision = 'precision';
    append = '-append';
    attributes = {delimiter,lineterminator,rowoffset,coloffset,precision,append};

    varargin = varargin{:}; % extract cell array input from varargin

    % test whether attribute-value pairs are specified, or fixed parameter order
    stringoptions = lower(varargin(cellfun('isclass',varargin,'char')));
    attributeindexesinoptionlist = ismember(stringoptions,attributes);
    newinputform = any(attributeindexesinoptionlist);
    if newinputform
        % parse values to functions parameters
        i = 1;
        while (i <= length(varargin))
            if strcmpi(varargin{i},append)
                appendmode = true;
                i = i+1;
            else
                %Check to make sure that there is a pair to go with
                %this argument.
                if length(varargin) < i + 1
                    error(message('MATLAB:dlmwrite:AttributeList', varargin{ i }))
                end
                if strcmpi(varargin{i},delimiter)
                    dlm = setdlm(varargin{i+1});
                elseif strcmpi(varargin{i},lineterminator)
                    nl = setnewline(varargin{i+1});
                elseif strcmpi(varargin{i},rowoffset)
                    r = setroffset(varargin{i+1});
                elseif strcmpi(varargin{i},coloffset)
                    c = setcoffset(varargin{i+1});
                elseif strcmpi(varargin{i},precision)
                    precn = varargin{i+1};
                else
                    error(message('MATLAB:dlmwrite:Attribute', varargin{ i }))
                end
                i = i+2;
            end
        end
    else % arguments are in fixed parameter order
        % delimiter defaults to Comma for CSV
        if options > 0
            dlm = setdlm(varargin{1});
        end

        % row and column offsets defaults to zero
        if options > 1 && ~isempty(varargin{2})
            r = setroffset(varargin{2});
        end
        if options > 2 && ~isempty(varargin{3})
            c = setcoffset(varargin{3});
        end
    end
end
end

function out = setdlm(in)
tmp = sprintf(in);
if (ischar(in) || (isstring(in) && isscalar(in))) && length(tmp) <= 1
    out = tmp;
else
    error(message('MATLAB:dlmwrite:delimiter',in));
end
end

function out = setnewline(in)
if ischar(in)
    if strcmpi(in,'pc')
        out = sprintf('\r\n');
    elseif strcmpi(in,'unix')
        out = newline;
    else
        error(message('MATLAB:dlmwrite:newline'));
    end
else
    error(message('MATLAB:dlmwrite:newline'));
end
end

function out = setroffset(in)
if isnumeric(in)
    out = in;
else
    error(message('MATLAB:dlmwrite:rowOffset', in));
end
end

function out = setcoffset(in)
if isnumeric(in)
    out = in;
else
    error(message('MATLAB:dlmwrite:columnOffset', in));
end
end

%   Copyright 1984-2024 The MathWorks, Inc.
