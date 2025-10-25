function validateattributes(obj, classes, attr, varargin)
%VALIDATEATTRIBUTES Check validity of array.
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES)
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,ARGINDEX)
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME)
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME,VARNAME)
%  VALIDATEATTRIBUTES(A,CLASSES,ATTRIBUTES,FUNCNAME,VARNAME,ARGINDEX)
%
%  Calling validateattributes on se2, se3, so2, and so3 is supported for all
%  ATTRIBUTES except 'real' and 'nonzero'.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Check for any unsupported attributes : nonzero, real
    coder.internal.assert(iscellstr(classes) || isstring(classes), ...
                          'MATLAB:validateattributes:badClassList');

    % If SE / SO class is not in the classes list, we want to throw that error
    % rather than one of the other errors below.
    found = false;
    for ii=1:numel(classes)
        if contains(classes{ii}, class(obj)) %{} indexing works for strings too
            found = true;
            break;
        end
    end
    if ~found
        % throw the builtin error
        builtin('validateattributes', obj, classes, attr, varargin{:});
    end

    % Filter out bad attributes. Make sure attr is a cell array
    coder.internal.assert(iscell( attr ), ...
                          'MATLAB:validateattributes:badAttributeList');

    for ii=1:numel(attr)
        v = attr{ii};
        if (isstring(v) || ischar(v))
            coder.internal.assert(~contains(v, 'nonzero'), ...
                                  'shared_spatialmath:matobj:ValAttrNonzero', class(obj));
            coder.internal.assert(~contains(v, 'real'), ...
                                  'shared_spatialmath:matobj:ValAttrReal', class(obj));
        end
    end
    builtin('validateattributes', obj, classes, attr, varargin{:});
end
