function schema
%  Definition of @hsvplot class (Hankel singular value plot)

%  Author(s): P. Gahinet
%  Copyright 1986-2005 The MathWorks, Inc. 

% Find parent package
pkg = findpackage('resppack');

% Register class (subclass)
c = schema.class(pkg, 'hsvplot', findclass(pkg, 'respplot'));

