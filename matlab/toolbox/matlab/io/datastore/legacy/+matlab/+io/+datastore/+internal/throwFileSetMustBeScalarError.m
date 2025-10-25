function throwFileSetMustBeScalarError(location)
%THROWFILESETMUSTBESCALARERROR throw mustBeScalar error for a file-set object
%   When the input to a datastore is a DsFileSet, it must be a scalar.
%   FileSet and BlockedFileSet disallow array formation, so this check is not needed for them.

%   Copyright 2021 The MathWorks, Inc.

location = convertStringsToChars(location);
if isa(location, 'matlab.io.datastore.DsFileSet')
    if ~isscalar(location)
        me = MException('MATLAB:datastoreio:dsfileset:mustBeScalar', ...
                 getString(message('MATLAB:datastoreio:dsfileset:mustBeScalar',class(location))));
        throwAsCaller(me);
    end
end

end
