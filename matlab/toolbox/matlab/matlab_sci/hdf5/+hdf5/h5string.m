classdef (CaseInsensitiveProperties=true) h5string < hdf5.hdf5type
%hdf5.h5string class
%   hdf5.h5string extends hdf5.hdf5type.
%
%    hdf5.h5string properties:
%       Name - Property is of type 'string'  
%       Length - Property is of type 'double'  (read only) 
%       Padding - Property is of type 'string'  (read only) 
%       Data - Property is of type 'string'  (read only) 
%
%    hdf5.h5string methods:
%       setData -  Set the hdf5.h5string's data.
%       setLength -  Set length of the hdf5.h5string datatype.
%       setPadding -  Set padding of hdf5.h5string datatype.

%   Copyright 2017 The MathWorks, Inc.

properties (SetAccess=protected, SetObservable)
    %LENGTH Property is of type 'double'  (read only)
    Length = 0;
    %PADDING Property is of type 'string'  (read only)
    Padding = '';
end


    methods  % constructor block
        function hObj = h5string(varargin)
        %H5STRING  Constructor for hdf5.h5string object.
        %   hdf5.h5string is not recommended.  Use h5read or H5T instead.
        %
        %   Example:
        %       HDF5STRING = hdf5.h5string('temperature');
        %
        %   See also H5READ, H5T.
        
        if (nargin >= 1)
            [varargin{:}] = convertStringsToChars(varargin{:});
            if (nargin == 2)
                        hObj.setData(varargin{1});
                hObj.setPadding(varargin{2});
            elseif (nargin == 1)
                        hObj.setData(varargin{1});
                hObj.setPadding('nullterm');
            else
                error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'))
            end
            
        elseif (nargin == 0)
                    hObj.setLength(0);
            hObj.setPadding('nullterm');
        end
            
        
        end  % h5string
        
    end  % constructor block

    methods 
        function set.Length(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Length')
        value = double(value); %  convert to double
        obj.Length = value;
        end

        function set.Padding(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Padding')
        obj.Padding = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function setData(hObj, data)
       %SETDATA  Set the hdf5.h5string's data.
       %   hdf5.h5string.setData is not recommended.  Use H5D and H5T instead.
       %
       %   Example:
       %       HDF5STRING = hdf5.h5string;
       %       HDF5STRING.setData('East Coast');
       %
       %   See also H5D, H5T.
       
       data = convertStringsToChars(data);
       
       if ~isempty(data)
           validateattributes(data, {'char'}, {'vector'});
       end
       
       % To preserve old behaviour.
       if iscolumn(data)
           data = data';
       end
       
       thisLength = numel(data);
       maxLength = hObj.Length;
       
       if (thisLength ~= length(data))
           error(message('MATLAB:imagesci:deprecatedHDF5:badRank'))
       end
       
       if (maxLength == 0)
           hObj.setLength(thisLength);
       elseif (thisLength > maxLength)
           warning(message('MATLAB:imagesci:deprecatedHDF5:stringTruncation'))
       end
       
       hObj.Data = data;
       
       end  % setData
       
        %----------------------------------------
       function setLength(hObj, len)
       %SETLENGTH  Set length of the hdf5.h5string datatype.
       %   hdf5.h5string.setLength is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5STRING = hdf5.h5string('East Coast');
       %       HDF5STRING.setLength(20);
       %
       %   See also H5T.
       
       
       hObj.Length = len;
       
       end  % setLength
       
        %----------------------------------------
       function setPadding(hObj, padding)
       %SETPADDING  Set padding of hdf5.h5string datatype.
       %   hdf5.h5string.setPadding is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5STRING = hdf5.h5string('East Coast');
       %       HDF5STRING.setLength(20);
       %       HDF5STRING.setPadding('spacepad');
       %
       %   See also H5T.
       
       padding = convertStringsToChars(padding);
       
       list = {'spacepad', 'nullterm', 'nullpad'};
       padding = validatestring(padding,list);
       
       hObj.Padding = padding;
       
       end  % setPadding
       
end  % public methods 

end  % classdef

