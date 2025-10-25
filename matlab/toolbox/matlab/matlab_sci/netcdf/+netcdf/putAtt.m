function putAtt(ncid,varid,attname,attvalue,xtype)
%netcdf.putAtt Write netCDF attribute.
%   netcdf.putAtt(ncid,varid,attrname,attrvalue) writes an attribute
%   to a NetCDF variable specified by varid.  In order to specify a
%   global attribute, use netcdf.getConstant('GLOBAL') for the varid.
%
%   netcdf.putAtt(ncid,varid,attrname,attrvalue,xtype) writes an attribute
%   of the NetCDF datatype specified by xtype. Specify the value of xtype
%   as a string scalar or character vector (e.g. 'NC_DOUBLE'), or as the
%   equivalent numeric value returned by the netcdf.getConstant function.
%   For user-defined NC_VLEN types, specify xtype as the numeric value
%   returned by the netcdf.defVlen function.
%
%   Note: You cannot use netcdf.putAtt to set the _FillValue attribute of
%   NetCDF4 files. Use the netcdf.defVarFill function to set the fill value
%   for a variable.
%
%   This function corresponds to the "nc_put_att" family of functions in
%   the netCDF library C API.
%
%   Example:
%       ncid = netcdf.create('myfile.nc','CLOBBER');
%       varid = netcdf.getConstant('GLOBAL');
%       netcdf.putAtt(ncid,varid,'creation_date',datestr(now));
%       netcdf.close(ncid);
%
%   Please read the libnetcdf.rights or netcdf.rights file for more
%   information.
%
%   See also netcdf, netcdf.getAtt, netcdf.defVarFill, netcdf.getConstant.
%

%   Copyright 2008-2023 The MathWorks, Inc.

narginchk(4,5);

if nargin > 2
    attname = convertStringsToChars(attname);
end

% 'cell' is for NC_VLEN data
validateattributes(attvalue,{'numeric','char','string','cell'},{},'','ATTVALUE');

nc_classes = { 'double', 'single', 'int64', 'uint64', 'int32', 'uint32', ...
    'int16', 'uint16', 'int8', 'uint8', 'char', 'string', 'cell'};
validatestring(class(attvalue), nc_classes);

if nargin == 5 % datatype was specified
    xtype = validateNetCDFType(xtype, "xtype");

    % if it is an atomic type
    if xtype < netcdf.getConstant('NC_FIRSTUSERTYPEID')

        % determine corresponding MATLAB datatype
        datatype = internal.matlab.imagesci.nc.xTypetoDatatype(xtype);

        % cast provided attvalue as needed based on specified datatype
        if isnumeric(attvalue) % numeric attvalue
            % if specified type was NC_CHAR or NC_STRING
            if xtype == 2 || xtype == 12
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(attvalue), datatype));
            end
            attvalue = cast(attvalue, datatype);
        elseif isstring(attvalue)||ischar(attvalue) % text attvalue
            if xtype == 2 % specified xtype was NC_CHAR
                attvalue = convertStringsToChars(attvalue);

                if iscell(attvalue) % trying to write several strings
                    error(message('MATLAB:imagesci:netcdf:invalidCharAttribute'))
                end

            elseif xtype == 12 % specified xtype was NC_STRING
                % do not allow character matrices
                if ischar(attvalue) && ~isvector(attvalue)
                    error(message('MATLAB:imagesci:netcdf:charMatrixString'));
                end

                attvalue = convertCharsToStrings(attvalue);
            else
                % specified type was not NC_CHAR or NC_STRING, so cannot write
                % a text-based attvalue
                error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                    class(attvalue), datatype));
            end

        else 
            % if class is not numeric or text, it cannot be written as
            % atomic type
            error(message('MATLAB:imagesci:netcdf:datatypeMismatch', ...
                class(attvalue), datatype));
        end
    end

else % datatype was not specified
    
    % Cell array data can only be written as user-defined NC_VLEN
    if iscell(attvalue)
        error(message('MATLAB:imagesci:netcdf:needUserDefinedType', ...
            'NC_VLEN', class(attvalue)));
    end

    % determine corresponding atomic NetCDF type
    xtype = internal.matlab.imagesci.nc.dataClasstoxType(class(attvalue));

    % represent uint8 based on file format
    if isa(attvalue, 'uint8')
        fmt = netcdf.inqFormat(ncid);
        if strcmp(fmt,'FORMAT_CLASSIC') ...
                || strcmp(fmt,'FORMAT_64BIT') ...
                || strcmp(fmt,'NETCDF4_FORMAT_CLASSIC')
            xtype = netcdf.getConstant('NC_BYTE'); % 1
        else
            % can use 'NC_UBYTE' only for NETCDF4 files
            xtype = netcdf.getConstant('NC_UBYTE'); % 7
        end
    end

    % write scalar strings as NC_CHAR by default
    % (for compatibility)
    if isstring(attvalue) && length(attvalue)==1
        xtype = netcdf.getConstant('NC_CHAR');
        attvalue = convertStringsToChars(attvalue);
    end

end

% Determine correct routine based on NetCDF type
switch (xtype)
    case netcdf.getConstant('NC_DOUBLE')
        funstr = 'putAttDouble';
    case netcdf.getConstant('NC_FLOAT')
        funstr = 'putAttFloat';
    case netcdf.getConstant('NC_INT64')
        funstr = 'putAttInt64';
    case netcdf.getConstant('NC_UINT64')
        funstr = 'putAttUint64';
    case netcdf.getConstant('NC_INT')
        funstr = 'putAttInt';
    case netcdf.getConstant('NC_UINT')
        funstr = 'putAttUint';
    case netcdf.getConstant('NC_SHORT') 
        funstr = 'putAttShort';
    case netcdf.getConstant('NC_USHORT') 
        funstr = 'putAttUshort';
    case netcdf.getConstant('NC_BYTE')
        % both uint8 and int8 can be represented by NC_BYTE,
        % pick routine based on signedness
        if isa(attvalue, 'uint8')
            funstr = 'putAttUchar';  
        elseif isa(attvalue, 'int8')
            funstr = 'putAttSchar';
        end
    case netcdf.getConstant('NC_UBYTE') 
        funstr = 'putAttUbyte';
    case netcdf.getConstant('NC_CHAR') 
        funstr = 'putAttText';
    case netcdf.getConstant('NC_STRING') 
        funstr = 'putAttString';
    otherwise
        % is it an existing User-Defined Type?
        try
            [~,~,~,~, classID] = netcdf.inqUserType(ncid, xtype);
        catch
            error(message('MATLAB:imagesci:netcdf:unrecognizedVarDatatype', xtype));
        end
        % is it a supported User-Defined Type?
        if classID == netcdf.getConstant('NC_VLEN')
            attvalue = validateVLEN(attvalue, ncid, xtype);
            funstr = 'putAttVlen';
        else
            error(message('MATLAB:imagesci:netcdf:unrecognizedVarDatatype', xtype));
        end
end


% Invoke the chosen NetCDF library routine
matlab.internal.imagesci.netcdflib(funstr,ncid,varid,attname,xtype,attvalue);




