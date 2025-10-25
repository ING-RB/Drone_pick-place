classdef (CaseInsensitiveProperties=true) hdf5type <  matlab.mixin.SetGet & matlab.mixin.Copyable
%hdf5.hdf5type class
%    hdf5.hdf5type properties:
%       Name - Property is of type 'character vector'  
%       Data - Property is of type 'MATLAB array'  
%
%    hdf5.hdf5type methods:
%       disp - DISP for an hdf5.hdf5type object
%       display - Display method for an hdf5.hdf5type object
%       setName -  Set the hdf5.hdf5type object's name.

%   Copyright 2017 The MathWorks, Inc.

properties (SetObservable)
    %NAME Property is of type 'character vector' 
    Name = '';
   %DATA Property is of type 'MATLAB array' 
    Data = [];
end


    methods  % constructor block
        function hObj = hdf5type(varargin)
       
        %HDF5TYPE   Constructor for hdf5.hdf5type objects
        %   hdf5.hdf5type is not recommended.  Use H5D and H5T instead.
        %
        %   See also H5D, H5T.
        
        end  % hdf5type
        
    end  % constructor block

    methods 
        function set.Name(obj,value)
            % DataType = 'character vector'
        
        value = convertStringsToChars(value);
        
        validateattributes(value,{'char'}, {'row'},'','Name')
        obj.Name = value;
        end
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function disp(hObj)
       %DISP DISP for an hdf5.hdf5type object
       %   hdf5.hdf5type.disp is not recommended.  Use h5disp instead.
       %
       %   See also H5DISP.
       
       
       if (numel(hObj) == 1)
           disp([class(hObj) ':']);
           disp(' ');
           disp(get(hObj));
       else
           builtin('disp', hObj);
       end
       
       
       
       
       end  % disp
       
        %----------------------------------------
       function dummy = display(hObj)
       %DISPLAY Display method for an hdf5.hdf5type object
       %   hdf5.hdf5type.display is not recommended.  Use h5disp instead.
       %
       %   See also H5DISP.
       
       
       % Use inputname when UDD works with it:
       %    name = inputname(1);
       %    if isempty(name)
       %        name = 'ans';
       %    end
       
       isloose = strcmp(get(0,'FormatSpacing'),'loose');
       if isloose
          newline=sprintf('\n');
       else
          newline=sprintf('');
       end
       
       fprintf(newline);
       disp(hObj);
       fprintf(newline)
       
       end  % display
       
        %----------------------------------------
       function setName(hObj, name)
       %SETNAME  Set the hdf5.hdf5type object's name.
       %   hdf5.h5type.setName is not recommended.  Use H5T instead.
       %
       %   Example:
       %       HDF5STRING = hdf5.h5string('East Coast');
       %       HDF5STRING.setLength(20);
       %       HDF5STRING.setName('shared datatype #1');
       %
       %   See also H5T.
       
       
       hObj.Name = name;
       
       end  % setName
     
end  % public methods 

end  % classdef

