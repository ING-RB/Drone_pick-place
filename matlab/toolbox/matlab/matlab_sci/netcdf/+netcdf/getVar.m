function data = getVar(ncid,varid,varargin)
%netcdf.getVar Return data from netCDF variable. 
%   data = netcdf.getVar(ncid,varid) reads an entire variable.  The 
%   class of the output data will match that of the netCDF variable.
%
%   data = netcdf.getVar(ncid,varid,start) reads a single value starting
%   at the specified index.
%
%   data = netcdf.getVar(ncid,varid,start,count) reads a contiguous
%   section of a variable.
%
%   data = netcdf.getVar(ncid,varid,start,count,stride) reads a strided
%   section of a variable.
% 
%   This function can be further modified by using a datatype string as 
%   the final input argument.  This has the effect of specifying the 
%   output datatype as long as the netCDF library allows the conversion.
%
%   The list of allowable datatype strings consists of 'double', 
%   'single', 'uint64', 'int64', 'uint32', 'int32', 'uint16', 'int16', 
%   'uint8', 'int8', and 'char'.
%   
%   This function corresponds to the "nc_get_var" family of functions in 
%   the NetCDF library C API.
%
%   Example:  Read the entire example variable 'temperature' in as double
%   precision.
%       ncid = netcdf.open('example.nc','NOWRITE');
%       varid = netcdf.inqVarID(ncid,'temperature');
%       data = netcdf.getVar(ncid,varid,'double');
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.putVar.

%   Copyright 2008-2022 The MathWorks, Inc.

if nargin > 2
    [varargin{:}] = convertStringsToChars(varargin{:});
end

narginchk(2,6) ;

% How many index arguments do we have?  This tells us whether we
% are retrieving an entire variable, just a single value, a contiguous 
% subset, or a strided subset.
if (nargin > 2) && ischar(varargin{end})
    num_index_args = nargin - 2 - 1;
else
    num_index_args = nargin - 2;
end
    
% Figure out whether we are retrieving an entire variable, just a single
% value, a contiguous subset, or a strided subset.
switch ( num_index_args ) 
  case 0
    funcstr = 'getVar';  % retrieve the entire variable
  case 1
    funcstr = 'getVar1'; % retrieve just one element
  case 2
    funcstr = 'getVara'; % retrieve a contiguous subset
  case 3
    funcstr = 'getVars'; % retrieve a strided subset.
end

% allowable output datatype values:
nc_classes = { 'double','float','single','int64','uint64', ...
               'int','int32','uint','uint32', 'short','int16', ...
               'ushort','uint16', 'schar','int8','uchar', ...
               'uint8','char','text'};
% allowable output datatype values that are MATLAB datatypes:
nc_classes_matlab = {'double','single','int64','uint64', ...
               'int32','uint32','int16', 'uint16','int8', ...
               'uint8','char'};

if (nargin > 2) && ischar(varargin{end})
    % An output datatype was specified.  Determine which funcstr
    % we need to use, and then don't forget to remove the output
    % datatype from the list of inputs.

    % validate output datatype, making sure to throw an error listing
    % only MATLAB datatypes
    try
        validatestring(varargin{end}, nc_classes);
    catch
        validatestring(varargin{end}, nc_classes_matlab, ...
            '', 'output_type');
    end
   
    % determine funcstr
    switch ( varargin{end} )
      case 'double'
        funcstr = [funcstr 'Double'];
      case { 'float', 'single' }
        funcstr = [funcstr 'Float'];
      case { 'int64' }
        funcstr = [funcstr 'Int64'];
      case { 'uint64' }
        funcstr = [funcstr 'Uint64'];
      case { 'int', 'int32' }
        funcstr = [funcstr 'Int'];
      case { 'uint', 'uint32' }
        funcstr = [funcstr 'Uint'];
      case { 'short', 'int16' }
        funcstr = [funcstr 'Short'];
      case { 'ushort', 'uint16' }
        funcstr = [funcstr 'Ushort'];
      case { 'schar', 'int8' }
        funcstr = [funcstr 'Schar'];
      case { 'uchar', 'uint8' }
        funcstr = [funcstr 'Uchar'];
      case { 'text', 'char' }
        funcstr = [funcstr 'Text'];
    end
    
    data = matlab.internal.imagesci.netcdflib(funcstr,ncid,varid,varargin{1:end-1});            
    
else
    % The last argument is not character, meaning we keep the
    % native datatype.
    [~,xtype] = netcdf.inqVar(ncid,varid);
    switch(xtype)
        case 12 % NC_STRING
            funcstr = [funcstr 'String'];
        case 11 % NC_UINT64
            funcstr = [funcstr 'Uint64'];
        case 10 % NC_INT64
            funcstr = [funcstr 'Int64'];
        case 9 % NC_UINT
            funcstr = [funcstr 'Uint'];
        case 8 % NC_USHORT
            funcstr = [funcstr 'Ushort'];
        case 7 % NC_UBYTE
            funcstr = [funcstr 'Uchar'];
        case 6 % NC_DOUBLE
            funcstr = [funcstr 'Double'];
        case 5 % NC_FLOAT
            funcstr = [funcstr 'Float'];
        case 4 % NC_INT
            funcstr = [funcstr 'Int'];
        case 3 % NC_SHORT
            funcstr = [funcstr 'Short'];
        case 2 % NC_CHAR
            funcstr = [funcstr 'Text'];
        case 1
            % NC_BYTE.  This is an unusual case.  The netCDF datatype
            % is ambiguous here as to whether it is uint8 or int8.
            % We will assume int8.
            funcstr = [funcstr 'Schar'];
        otherwise
            % is it a supported User-Defined Type?
            [~,~,~,~, classID] = netcdf.inqUserType(ncid, xtype);
            if classID == netcdf.getConstant('NC_VLEN')
                funcstr = [funcstr 'Vlen'];
            else
                error(message('MATLAB:imagesci:netcdf:unrecognizedVarDatatype', xtype));
            end
    end

    
    % workaround for netcdf 3p bug related to loss of data for strided
    % reads (when stride != 1) for netcdf4 classic files(a strided subset
    % read on a dataset that has scale factor and offset applied)
    % strided read (nargin >= 5 imples that varargin has start, count,
    % stride) and stride > 1
    if ( nargin >= 5 ) && ( any(varargin{3} > 1) )
        
        start = varargin{1};
        count = varargin{2};
        stride = varargin{3};
        try
            % index of the last element to be read
            % start = start + 1, since MATLAB indexing is 1 based, and
            % start was previous converted to 0 based for C library call
            ind_last_elem = start + 1 + (count - 1).*stride;
        catch ME
            if strcmp(ME.identifier, 'MATLAB:sizeDimensionsMustMatch')
                msgID = 'MATLAB:imagesci:netcdf:badIndexArgumentLength';
                exception = MException(msgID, ME.message);
                throw(exception)
            end
        end
        % copy the varargin to a temp variable
        % read as stride = 1
        temp_args{1} = start;
        temp_args{2} = ind_last_elem - varargin{1};
        temp_args{3} = ones(1, length(varargin{1}));
        % read in all the data from start to count
        data = matlab.internal.imagesci.netcdflib(funcstr,ncid,varid,temp_args{:});

        % create a cell array with the indices of the data values that are
        % needed
        subs = cell(1, length(start));
        % parse the data
        for i = 1:length(start)
            subs{i} = 1:stride(i):size(data, i);
        end

        data = data(subs{:});

    else
        data = matlab.internal.imagesci.netcdflib(funcstr,ncid,varid,varargin{:});   
    end
    
end

    
