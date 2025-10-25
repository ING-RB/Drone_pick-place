classdef (CaseInsensitiveProperties=true) h5vlen < hdf5.hdf5type
%hdf5.h5vlen class
%   hdf5.h5vlen extends hdf5.hdf5type.
%
%    hdf5.h5vlen properties:
%       Name - Property is of type 'character vector'  
%       Data - Property is of type 'MATLAB array'  
%
%    hdf5.h5vlen methods:
%       setData -  Set the hdf5.h5vlen's data.

%   Copyright 2017 The MathWorks, Inc.

    methods  % constructor block
        function hObj = h5vlen(varargin)
        %H5VLEN  Constructor for an hdf5.h5vlen object.
        %   hdf5.h5vlen is not recommended.  Use H5READ or H5T instead.
        %
        %   Example:
        %       HDF5STRING = hdf5.h5vlen({0 [0 1] [0 2] [0:10]});
        %
        %   See also H5READ, H5T.
        
        
        narginchk(0,1);
        if (nargin == 1)
                    hObj.setData(varargin{1});
        else
                end
        
        end  % h5vlen
        
    end  % constructor block

    methods  % public methods
        %----------------------------------------
       function setData(hObj, data)
       %SETDATA  Set the hdf5.h5vlen's data.
       %   hdf5.h5vlen.setData is not recommended.  Use H5D and H5T instead.
       %
       %   Example:
       %       HDF5VLEN = hdf5.h5vlen;
       %       HDF5VLEN.setData({0:5 0:10});
       %
       %   See also H5D, H5T.
       
       if isempty(data)
           hObj.Data = data;
           return
       end
       
       if iscell(data)
           % We do not want to support cell arrays containing only strings
           % OR only a combination of strings and char vectors
           matlab.io.internal.imagesci.validateTextInCell(data, 'deprecatedHDF5');
       end
       
       data = convertStringsToChars(data);
              
       if (numel(data) ~= length(data))
           error(message('MATLAB:imagesci:deprecatedHDF5:notVector'))
          
           if (((~isnumeric(data)) && (~isa(data, 'hdf5.hdf5type'))) && ...
               (~iscell(data)))
               error(message('MATLAB:imagesci:deprecatedHDF5:badType'))
           end
       
       else
         if (isa(data, class(data(1))))
           if iscell(data)
               hObj.Data = hdf5.internal.convertCellToMat(data);
           else
               hObj.Data = data;
           end
         else
           error(message('MATLAB:imagesci:deprecatedHDF5:inconsistentType'));
         end
       end
       
       end  % setData
       
end  % public methods 

end  % classdef

