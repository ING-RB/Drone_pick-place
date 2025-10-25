 function validateattributes(obj, classes, attr, varargin)
%VALIDATEATTRIBUTES Check validity of array.
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES) 
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,ARGINDEX) 
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME) 
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME,VARNAME) 
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME,VARNAME,ARGINDEX)
%
%  Calling validateattributes on quaternions is supported for all
%  ATTRIBUTES except 'real' and 'nonzero'. 
%

%   Copyright 2018-2022 The MathWorks, Inc.

%#codegen 

    % Check for any unsupported attributes : nonzero, real
    
  
    % Ensure these work:
    %   validateattributes(q, {'quaternion'}, ...
    %   validateattributes(q, ["quaternion"], ..
    %   validateattributes(q, 'quaternion', ...
    % it's okay to error on
    %   validateattributes(q, {"quaternion"} ...  % as in base MATLAB
    if ischar(classes)
        clslist = {classes};
    else
        clslist = classes;
    end
    coder.internal.assert(iscellstr(clslist) || isstring(clslist), ...
        'MATLAB:validateattributes:badClassList');
        
    % If quaternion is not in the classes list, we want to throw that error
    % rather than one of the other errors below.
    found = false;
    for ii=1:numel(clslist)
        if isstring(clslist)
            c = clslist(ii);
        else
            c = clslist{ii};  % this syntax works for strings too in MATLAB, but not codegen
        end
        if contains(c, 'quaternion') 
            found = true;
            break;
        end
    end
    if ~found
        % throw the builtin error
        builtin('validateattributes', obj, clslist, attr, varargin{:});
    end
    
    % Filter out bad attributes. Make sure attr is a cell array or string
    coder.internal.assert(iscell( attr ) || isstring(attr), ...
        'MATLAB:validateattributes:badAttributeList');
    
    if coder.target('MATLAB')
        % Important to code in this pattern. Ideally, we'd use a new
        % variable and not change the type of attr below. But then we'd
        % have a codegen path where we assign attr to the new variable
        % also. That seems to break the const-ness of the attr cell array
        % which is needed for coder.
        % String arrays are not supported in codegen now anyway, so this
        % pattern works. 
        if isstring(attr)
            % Convert to a cell string
            attr = cellstr(attr);
        end
    end

    % Check that only legal attributes for quaternions are found
    checkattrs(attr);

    builtin('validateattributes', obj, clslist, attr, varargin{:});
 end

 function checkattrs(attr)
 %CHECKATTRS - Check that only attributes for quaternions are found.
 %  Ensure that attributes 
 %      nonzero
 %      real
 %  do not appear in the attr cell array. The don't have good meaning for
 %  quaternions.

    for ii=1:numel(attr)
        v = attr{ii};   
        if (isstring(v) || ischar(v))
            coder.internal.assert(~contains(v, 'nonzero'), ...
                'shared_rotations:quaternion:ValAttrNonzero');
            coder.internal.assert(~contains(v, 'real'), ...
                'shared_rotations:quaternion:ValAttrReal');
        end
    end
 end
            
