%   CREATE Create a package
%   matlab.mpm.internal.create(packageName)
%   matlab.mpm.internal.create(packageName, packageFolder)
%
%   Creates a package with the name specified by packageName at location
%   specified by packageFolder. If the specified folder does not exist,
%   a new folder will be created. If packageFolder is not specified, the package
%   will be created in the current folder. The created package will have a
%   random generated unique id. A new id is generated each time
%   matlab.mpm.internal.create is called.

%   Copyright 2023 The MathWorks, Inc. Built-in function.
