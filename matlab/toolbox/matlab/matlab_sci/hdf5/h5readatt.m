function attval = h5readatt(Filename,Location,Attname,varargin)
%H5READATT Read attribute from HDF5 file.
%   ATTVAL = H5READATT(FILENAME,LOCATION,ATTR) retrieves the value for
%   named attribute ATTR from the given location, which can refer to either
%   a group or a dataset.  LOCATION must be a full pathname of an existing
%   group or dataset to which the attribute belongs.
%
%   ATTVAL = H5READATT(URL,LOCATION,ATTR) retrieves the value for named
%   attribute ATTR from the given location which can refer to either a
%   group or a dataset, for an H5 file stored at a remote location.
%   LOCATION must be a full pathname of an existing group or dataset to
%   which the attribute belongs. When reading data from remote locations,
%   you must specify the full path using a uniform resource locator
%   (URL). For example, to read a dataset in an HDF5 file from
%   Amazon S3 cloud specify the full URL for the file:
%       s3://bucketname/path_to_file/example.h5
%   For more information on accessing remote data, see "Work with Remote Data"
%   in the documentation.
%
%   Example:  Read a group attribute.
%       attval = h5readatt('example.h5','/','attr2');
%
%   Example:  Read a dataset attribute.
%       h5disp('example.h5','/g4/lon');
%       attval = h5readatt('example.h5','/g4/lon','units');
%
%   Example:  Read a group attribute from an h5 file in Amazon S3..
%       attval =
%       h5readatt('s3://bucketname/path_to_file/example.h5','/','attr2');
%
%   See also H5WRITEATT, H5DISP.

%   Copyright 2010-2023 The MathWorks, Inc.

if nargin > 0
    Filename = convertStringsToChars(Filename);
end

if nargin > 1
    Location = convertStringsToChars(Location);
end

if nargin > 2
    Attname = convertStringsToChars(Attname);
end

p = inputParser;
p.addRequired('Filename', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','FILENAME'));
p.addRequired('Location', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','LOCATION'));
p.addRequired('Attname', ...
    @(x) validateattributes(x,{'char', 'string'},{'nonempty', 'scalartext'},'','ATTR'));
p.parse(Filename,Location,Attname,varargin{:});
options = p.Results;

% Just use the defaults for now?
lapl = 'H5P_DEFAULT';

if Location(1) ~= '/'
    error(message('MATLAB:imagesci:h5readatt:notFullPathName'));
end

file_id = open_file(options.Filename);

try
    obj_id = H5O.open(file_id,options.Location,lapl);
catch me
    if H5L.exists(file_id,options.Location,lapl)
        rethrow(me);
    else
        error(message('MATLAB:imagesci:h5readatt:invalidLocation', options.Location));
    end
end


attr_id = H5A.open_name(obj_id,options.Attname);
raw_att_val = H5A.read(attr_id,'H5ML_DEFAULT');

% Read the datatype information and use that to possibly post-process
% the attribute data.
attr_type = H5A.get_type(attr_id);
attr_class = H5T.get_class(attr_type);

persistent H5T_ENUM H5T_OPAQUE H5T_STRING H5T_INTEGER H5T_FLOAT H5T_BITFIELD H5T_REFERENCE;
if isempty(H5T_ENUM)
    H5T_ENUM = H5ML.get_constant_value('H5T_ENUM');
    H5T_OPAQUE = H5ML.get_constant_value('H5T_OPAQUE');
    H5T_STRING = H5ML.get_constant_value('H5T_STRING');
    H5T_INTEGER = H5ML.get_constant_value('H5T_INTEGER');
    H5T_FLOAT = H5ML.get_constant_value('H5T_FLOAT');
    H5T_BITFIELD = H5ML.get_constant_value('H5T_BITFIELD');
    H5T_REFERENCE = H5ML.get_constant_value('H5T_REFERENCE');
end

if ((attr_class == H5T_INTEGER) || (attr_class == H5T_FLOAT) || (attr_class == H5T_BITFIELD))
    if isvector(raw_att_val)
        attval = reshape(raw_att_val,numel(raw_att_val),1);
    else
        attval = raw_att_val;
    end
    return
end

aspace = H5A.get_space(attr_id);

% Perform any necessary post processing on the attribute value.
switch (attr_class)
    
    case H5T_ENUM
        attval = h5postprocessenums(attr_type,aspace,raw_att_val);
      
    case H5T_OPAQUE
        attval = h5postprocessopaques(attr_type,aspace,raw_att_val);
        
    case H5T_STRING
        attval = h5postprocessstrings(attr_type,aspace,raw_att_val);
        
    case H5T_REFERENCE
        attval = h5postprocessreferences(attr_id,aspace,raw_att_val);
        
    otherwise
        attval = raw_att_val;
        
end



%---------------------------------------------------------------------------
function fid = open_file(filename)

% Try with the default driver, then the family driver, then the multi 
% driver, then the split driver.
try
    fid = H5F.open(filename,'H5F_ACC_RDONLY','H5P_DEFAULT');
catch me
    rethrow(me);
end
return
