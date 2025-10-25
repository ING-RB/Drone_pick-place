function xtype = validateNetCDFType(xtype, argNameForErrorText)
%VALIDATENETCDFTYPE Return valid numeric type ID.
%   Validate provided NetCDF type, whether it was specified as a type name
%   or as numeric id. Convert type name to numeric type id.

%   Copyright 2021 The MathWorks, Inc.

arguments
    xtype
    argNameForErrorText (1,:) {mustBeTextScalar}
end

if ~isnumeric(xtype)
    % validate xtype provided as a type name (char vector or string)
    validateattributes(xtype, {'string', 'char'}, {'scalartext'}, '', ...
        argNameForErrorText)
    xtype = netcdf.getConstant(xtype);
else
    % validate numeric xtype
    validateattributes(xtype, {'numeric'}, ...
        {'nonnan', 'finite', 'scalar', 'integer'}, '', argNameForErrorText)
end
