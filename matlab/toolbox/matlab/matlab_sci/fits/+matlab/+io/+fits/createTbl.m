function fptr = createTbl(fptr,tbltype,nrows,ttype,tform,tunit,extname)
%createTbl create new ASCII or binary table extension
%   FPTR = createTbl(FPTR,TBLTYPE,NROWS,TTYPE,TFORM,TUNIT,EXTNAME) creates
%   a new ASCII or bintable table extension.  TBLTYPE must be either
%   'binary' or 'ascii'.  NROWS gives the initial number of rows to be
%   created in the table and should normally be zero.  TUNIT specifies the
%   units for each column, but may be an empty cell array if no units are 
%   desired.  EXTNAME specifies the extension name, but may be omitted.
%
%   TFORM specifies the format of the column.  For binary tables, the 
%   values should be in the form of 'rt', where 'r' is the repeat count and
%  't' is one of the following letters:
%
%       'A' - ASCII character
%       'B' - byte or uint8
%       'C' - complex (single precision)
%       'D' - double precision
%       'E' - single precision
%       'I' - int16
%       'J' - int32
%       'K' - int64
%       'L' - logical
%       'M' - complex (double precision)
%       'X' - bit (int8 zeros and ones)
%
%   A column may also be specified as having variable-width if the TFORM
%   value has the form '1Pt' or '1Qt', where 't' specifies the datatype as 
%   above.
%
%   For ASCII tables, the TFORM values take the form:
%
%       Iw     - int16 column with width 'w' 
%       Aw     - ASCII column with width 'w'
%       Fww.dd - Fixed point 
%       Eww.dd - single precision with width 'ww' and precision 'dd
%       Dww.dd - double precision with width 'ww' and precision 'dd
%
%   This function corresponds to the "fits_create_tbl" (ffcrtb) function in 
%   the CFITSIO library C API.
%
%   Example:  Create a binary table.  The first column will contain strings 
%   of nine characters each.  The second column will contain four-element
%   sequences of bits.  The third column will contain three-element
%   sequences of uint8 values.  The fourth column will contain double 
%   precision scalars.
%       import matlab.io.*
%       fptr = fits.createFile('myfile.fits');
%       ttype = {'Col1','Col2','Col3','Col4'};
%       tform = {'9A','4X','3B','1D'};
%       tunit = {'m/s','kg','kg/m^3','candela'};
%       fits.createTbl(fptr,'binary',10,ttype,tform,tunit,'my-table');
%       fits.closeFile(fptr);
%       fitsdisp('myfile.fits');
%
%   Example:  Create a two-column table where the first column has a single
%   double precision value, but the second column has a variable-length 
%   double precision value.
%       import matlab.io.*
%       fptr = fits.createFile('myfile2.fits');
%       ttype = {'Col1','Col2'};
%       tform = {'1D','1PD'};
%       fits.createTbl(fptr,'binary',0,ttype,tform);
%       fits.closeFile(fptr);
%       fitsdisp('myfile2.fits');
%
%   See also fits, insertATbl, insertBTbl, readCol, writeCol, createImg.

%   Copyright 2011-2020 The MathWorks, Inc.

if nargin > 1
    tbltype = convertStringsToChars(tbltype);
end

if nargin > 3
    if isstring(ttype)
        ttype = cellstr(ttype);
    end
end

if nargin > 4
    if isstring(tform)
        tform = cellstr(tform);
    end
end

if nargin > 5
    if isstring(tunit)
        tunit = cellstr(tunit);
    end
end

if nargin > 6
    extname = convertStringsToChars(extname);
end

validateattributes(fptr,{'uint64'},{'scalar'},'','FPTR');
validateattributes(tbltype,{'char'},{'nonempty'},'','TBLTYPE');
tbltype_str = validatestring(tbltype,{'binary','ascii'});
switch(tbltype_str)
	case 'binary'
		tbltype = matlab.internal.imagesci.fitsiolib('get_constant_value','BINARY_TBL');
	case 'ascii'
		tbltype = matlab.internal.imagesci.fitsiolib('get_constant_value','ASCII_TBL');
end
validateattributes(nrows,{'double'},{'scalar','nonnegative'},'','NROWS');

validateattributes(ttype,{'cell'},{'nonempty','row'},'','TTYPE');
n = numel(ttype);

validateattributes(tform,{'cell'},{'nonempty','size',[1 n]},'','TFORM');

% validating the input arguments and creating them wherever necessary
switch nargin
    case 5
        tunit = create_tunit(n);
        extname = '';
    case 6
        if isempty(tunit)
            tunit = create_tunit(n);
        else
            validateattributes(tunit,{'cell'},{'size',[1 n]},'','TUNIT');
        end
        extname = '';
    case 7
        if isempty(tunit)
            tunit = create_tunit(n);
        else
            validateattributes(tunit,{'cell'},{'size',[1 n]},'','TUNIT');
        end
        validateattributes(extname,{'char'},{'nonempty','row'},'','EXTNAME');
end

matlab.internal.imagesci.fitsiolib('create_tbl',fptr,tbltype,nrows,ttype,tform,tunit,extname);
end

% function to create the units as empty char if it has not been provided
function tunit = create_tunit(n)
    tunit = cell(1,n);
    for j = 1:n
        tunit{j} = '';
    end
end


