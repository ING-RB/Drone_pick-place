function classes = findSubClasses(packageName, superclassName)
%FINDSUBCLASSES   Find sub-classes within a package
%
%   CLASSES = FINDSUBCLASSES(PACKAGE, SUPERCLASS) is an array of meta.class
%   objects, each element being a sub-class of SUPERCLASS and a member of
%   the given PACKAGE.
%
%   Note that only non-abstract classes are returned.
%
%   Example
%      classes = optim.internal.findSubClasses('optim.options', 'optim.options.SolverOptions')

%   Copyright 2015-2022 The MathWorks, Inc.

arguments
    packageName
    superclassName
end

% Get the package object
package = meta.package.fromName(packageName);

% For each class in the package ...
%  1. check for given super-class
%  2. check for abstract classes
classes = package.ClassList;
keep = arrayfun( ...
    @(x) isAClass(superclassName, x.SuperClasses ) && ~x.Abstract, classes);

% Return list of non-abstract classes that sub-class the given super-class
classes = classes(keep);

function tf = isAClass( className, list )
% Check the LIST of classes and their superclasses for given CLASSNAME
tf = false;
for i = 1:length( list )
    tf = strcmp( className, list{i}.Name ) || isAClass( className, list{i}.SuperClasses );
    if tf
        break
    end
end