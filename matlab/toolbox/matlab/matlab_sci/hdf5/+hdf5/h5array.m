classdef (CaseInsensitiveProperties=true) h5array < hdf5.hdf5type
%hdf5.h5array class
%   hdf5.h5array extends hdf5.hdf5type.
%
%    hdf5.h5array properties:
%       Name - Property is of type 'string'  
%       Data - Property is of type 'MATLAB array'  
%
%    hdf5.h5array methods:
%       setData -  Set the hdf5.h5array's data.

%   Copyright 2017 The MathWorks, Inc.


    methods  % constructor block
        function hObj = h5array(varargin)
        %H5ARRAY  Constructor for hdf5.h5array objects
        %   hdf5.h5array is not recommended.  Use H5T instead.
        %
        %   Example:  
        %      hdf5array = hdf5.h5array;
        %
        %   Example:
        %      hdf5array = hdf5.h5array(magic(5));
        %

        %   See also H5T.
        
        
        if (nargin == 1)
                    hObj.setData(varargin{1});
        elseif (nargin == 0)
                else
            error(message('MATLAB:imagesci:validate:wrongNumberOfInputs'));
        end
        
        end  % h5array
        
    end  % constructor block

    methods  % public methods
        %----------------------------------------
       function setData(hObj, data)
       %SETDATA  Set the hdf5.h5array's data.
       %   hdf5.h5array.setData is not recommended.  Use H5D.write instead.
       %
       %   Example:
       %       HDF5ARRAY = hdf5.h5array;
       %       HDF5ARRAY.setData(magic(100));
       %
       %   See also H5D.write.
       
       if iscell(data)
           % We do not want to support cell arrays containing only strings
           % OR only a combination of strings and char vectors
           matlab.io.internal.imagesci.validateTextInCell(data, 'deprecatedHDF5');
       end
       
       if isempty(data)
           hObj.Data = data;
           return
       end
       
       data = convertStringsToChars(data);
       
       if (((~isnumeric(data)) && (~isa(data, 'hdf5.hdf5type'))) && ...
               (~iscell(data)))
           error(message('MATLAB:imagesci:deprecatedHDF5:badType'));
       end
       
       if (isa(data, class(data(1))))
           if iscell(data)
              hObj.Data = hdf5.internal.convertCellToMat(data);
           else
               hObj.Data = data;
           end
       else
           error(message('MATLAB:imagesci:deprecatedHDF5:differentType'));
       end
       
       end  % setData
       
end  % public methods 

end  % classdef

