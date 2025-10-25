classdef (CaseInsensitiveProperties=true) h5compound < hdf5.hdf5type
%hdf5.h5compound class
%   hdf5.h5compound extends hdf5.hdf5type.
%
%    hdf5.h5compound properties:
%       Name - Property is of type 'character vector'  
%       Data - Property is of type 'MATLAB array'  
%       MemberNames - Property is of type 'MATLAB array'  (read only) 
%
%    hdf5.h5compound methods:
%       addMember -  Add a new member to a compound object.
%       setMember - hdf5.h5compound.setMember  Update a member's data.
%       setMemberNames -  Set the names of the compound object's members.

%   Copyright 2017 The MathWorks, Inc.


properties (SetAccess=protected, SetObservable)
    %MEMBERNAMES Property is of type 'MATLAB array'  (read only)
    MemberNames = [];
end


    methods  % constructor block
        function hObj = h5compound(varargin)
        %H5COMPOUND  Constructor.
        %   hdf5.h5compound is not recommended.  Use H5T instead.
        %
        %   See also H5T.
        
        
        if (~isempty(varargin))
                    hObj.setMemberNames(varargin{:});
        else
                end
        
        end  % h5compound
        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addMember(hObj, memberName, data)
       %ADDMEMBER  Add a new member to a compound object.
       %   h5compound.addMember is not recommended.  Use H5T instead. 
       %
       %   See also H5T.
       
       if isstring(memberName)
           memberName = char(memberName);
       end
       
       validateattributes(memberName,{'char'},{'row','nonempty'},'','MEMBERNAME');
       if nargin == 2
           data = [];
       end
       
       if (any(strcmp(hObj.MemberNames, memberName)))
           error(message('MATLAB:imagesci:deprecatedHDF5:existingName', memberName));
       end
       
       hObj.MemberNames{end + 1} = memberName;
       hObj.setMember(memberName, data);
       
       end  % addMember
       
        %----------------------------------------
       function setMember(hObj, memberName, data)
       %hdf5.h5compound.setMember  Update a member's data.
       %   hdf5.h5compound is not recommended.  Use H5T instead.
       %
       %   Example:
       %       hobj = hdf5.h5compound('a','b','c');
       %       hobj.setMember('a',0);
       %       hobj.setMember('b',uint32(1));
       %       hobj.setMember('c',int32(2));
       %       hdf5write('myfile.h5','ds1',hobj);
       %
       %   See also H5T.
       
       if isstring(memberName)
           memberName = char(memberName);
       end
       
       if iscell(data)
           matlab.io.internal.imagesci.validateTextInCell(data, 'deprecatedHDF5');
       end
       data = convertStringsToChars(data);
       
       idx = strcmp(hObj.MemberNames, memberName);
       
       if (~any(idx))
           error(message('MATLAB:imagesci:deprecatedHDF5:badName'))
       end
       
       if ((~isnumeric(data)) && (~isa(data, 'hdf5.hdf5type')))
           error(message('MATLAB:imagesci:deprecatedHDF5:badType'))
       elseif (numel(data) > 1)
           error(message('MATLAB:imagesci:deprecatedHDF5:badSize'))
       end
       
       hObj.Data{idx} = data;
       
       end  % setMember
       
        %----------------------------------------
       function setMemberNames(hObj, varargin)
       %SETMEMBERNAMES  Set the names of the compound object's members.
       %   hdf5.setMemberNames is not recommended.  Use H5T instead.
       %
       %   See also H5T.
       
       [varargin{:}] = convertStringsToChars(varargin{:});
       
       if (~iscellstr(varargin))
           error(message('MATLAB:imagesci:deprecatedHDF5:badNameTypes'))
       end
       
       for p = 1:(nargin - 1)
           msg = getString(message('MATLAB:imagesci:deprecatedHDF5:adding',varargin{p}));
           disp(msg);
           hObj.addMember(varargin{p});
       end
       
       end  % setMemberNames
       
end  % public methods 

end  % classdef

