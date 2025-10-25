classdef (CaseInsensitiveProperties=true) h5enum < hdf5.hdf5type
%hdf5.h5enum class
%   hdf5.h5enum extends hdf5.hdf5type.
%
%    hdf5.h5enum properties:
%       Name - Property is of type 'character vector'  
%       Data - Property is of type 'MATLAB array'  
%       EnumNames - Property is of type 'MATLAB array'  (read only) 
%       EnumValues - Property is of type 'MATLAB array'  (read only) 
%
%    hdf5.h5enum methods:
%       defineEnum -  Add the enum definition to the hdf5.h5enum object.
%       getString -   Returns the hdf5.h5enum data as the enumeration's
%       setData -  Set the data for the hdf5.h5enum object
%       setEnumNames -  Set the hdf5.h5enum's character vector values.
%       setEnumValues -  Set the hdf5.h5enum's numeric values.

%   Copyright 2017 The MathWorks, Inc.

properties (SetAccess=protected, SetObservable)
    %ENUMNAMES Property is of type 'MATLAB array'  (read only)
    EnumNames = [];
    %ENUMVALUES Property is of type 'MATLAB array'  (read only)
    EnumValues = [];
end


    methods  % constructor block
        function hObj = h5enum(varargin)
        %H5ENUM  Constructor for hdf5.h5enum objects
        %   hdf5.h5enum is not recommended.  Use h5read or H5T instead.
        %
        %   Example:
        %       HDF5ENUM = hdf5.h5enum;
        %
        %   Example:
        %       HDF5ENUM = hdf5.h5enum({'RED' 'GREEN' 'BLUE'}, uint8([1 2 3]));
        %
        %   See also H5READ, H5T.
        
        
        if (nargin == 3)
                    hObj.defineEnum(varargin{2}, varargin{3});
            hObj.setData(varargin{1});
        elseif (nargin == 2)
                    hObj.defineEnum(varargin{:});
        elseif (nargin == 0)
                else
            error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'));
        end
        
        end  % h5enum
        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function defineEnum(hObj, stringValues, numberValues)
       %DEFINEENUM  Add the enum definition to the hdf5.h5enum object.
       %   hdf5.h5enum.defineEnum is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5ENUM = hdf5.h5enum;
       %       HDF5ENUM.defineEnum({'RED','BLUE','GREEN','BLACK'}, ...
       %                       uint8([1 2 3 0]);
       %
       %   See also H5T.
       
       % We do not want to support cell arrays containing only strings OR
       % only a combination of strings and char vectors
       if iscell(stringValues)
           matlab.io.internal.imagesci.validateTextInCell(stringValues, 'deprecatedHDF5');
       end
       
       stringValues = convertStringsToChars(stringValues);
       
       % Parse inputs.
       if (~iscellstr(stringValues))
           error(message('MATLAB:imagesci:deprecatedHDF5:badStringValueType'));
       elseif (numel(stringValues) ~= numel(numberValues))
           error(message('MATLAB:imagesci:deprecatedHDF5:unbalancedValues'));
       end
       
       % Put the data.
       hObj.setEnumNames(stringValues);
       hObj.setEnumValues(numberValues);
       
       end  % defineEnum
       
        %----------------------------------------
       function cellstr = getString(hObj)
       %GETSTRING   Returns the hdf5.h5enum data as the enumeration's
       %   hdf5.h5enum.getString is not recommended.  Use h5read instead.
       %
       %   See also H5READ.
       
       
       origSize = size(hObj.Data);
       cellstr = cell(origSize);
       
       for i = 1:numel(hObj.Data)
       
           % This looks up a data value to find the corresponding character
           % vector key in the HDF5 enumeration.
           cellstr{i} = hObj.EnumNames{find(hObj.Data(i) == hObj.EnumValues)};
       end
       
       % Sanity check that cellstr is indeed a cellstr
       if (~iscellstr(cellstr))
           error(message('MATLAB:imagesci:deprecatedHDF5:badEnumData'));
       end
       
       
       end  % getString
       
        %----------------------------------------
       function setData(hObj, data)
       %SETDATA  Set the data for the hdf5.h5enum object
       %   hdf5.h5enum.setData is not recommended.  Use H5D and H5T instead.
       %
       %   Example:
       %       HDF5ENUM = hdf5.h5enum({'ALPHA' 'RED' 'GREEN' 'BLUE'}, ...
       %              uint8([0 1 2 3]));
       %       HDF5ENUM.setData(uint8([3 0 1 2]));
       %
       %   See also H5D, H5T.
       
       
       if isempty(data)
           hObj.Data = data;
           return
       end
       
       
       if ((isempty(hObj.EnumNames)) || (isempty(hObj.EnumValues)))
           error(message('MATLAB:imagesci:deprecatedHDF5:missingEnumData'));
       end
       
       if (~isequal(class(hObj.EnumValues), class(data)))
           error(message('MATLAB:imagesci:deprecatedHDF5:differentEnumType'))
       elseif ((isa(data, 'single')) || (isa(data, 'double')))
           error(message('MATLAB:imagesci:deprecatedHDF5:wrongType'))
       end
       
       if (~isempty(setdiff(data(:), hObj.EnumValues)))
           warning(message('MATLAB:imagesci:deprecatedHDF5:invalidValue'))
       end
       
       hObj.Data = data;
       
       end  % setData
       
        %----------------------------------------
       function setEnumNames(hObj, stringValues)
       %SETENUMNAMES  Set the hdf5.h5enum's character vector values.
       %   hdf5.h5enum.setEnumNames is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5ENUM.setEnumNames({'ALPHA' 'RED' 'GREEN' 'BLUE'});
       %
       %   See also H5T.
       
       
       % We do not want to support cell arrays containing only strings OR
       % only a combination of strings and char vectors
       if iscell(stringValues)
           matlab.io.internal.imagesci.validateTextInCell(stringValues, 'deprecatedHDF5');
       end
       
       stringValues = convertStringsToChars(stringValues);
       
       if (~iscellstr(stringValues))
           error(message('MATLAB:imagesci:deprecatedHDF5:nameValueType'));
           
       elseif (numel(stringValues) ~= length(stringValues))
           error(message('MATLAB:imagesci:deprecatedHDF5:nameValueRank'));
           
       end
       
       hObj.EnumNames = stringValues;
       
       end  % setEnumNames
       
        %----------------------------------------
       function setEnumValues(hObj, numberValues)
       %SETENUMVALUES  Set the hdf5.h5enum's numeric values.
       %   hdf5.h5enum.setEnumValues is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5ENUM = hdf5.h5enum;
       %       HDF5ENUM.setEnumNames({'ALPHA' 'RED' 'GREEN' 'BLUE'});
       %       HDF5ENUM.setEnumValues(uint8([0 1 2 3]));
       %
       %   See also H5T.
       
       
       validateattributes( numberValues, ...
                          { 'int8','uint8','int16','uint16',...
                                'int32','uint32','int64','uint64' }, ...
                          {'nonempty','vector'}, ...
                          '', ...
                          'NUMBERVALUES' );
       
       hObj.EnumValues = numberValues;
       
       end  % setEnumValues
       
end  % public methods 

end  % classdef

