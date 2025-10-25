function tf = isMethodImplemented(className, methodName)
%ISIMPLEMENTED Checks if className implements methodName
%   Returns true of className implemented methodName. Returns false if
%   className relies on a positioning base class for the implementation.

% Does not support codegen. Intended to be called as extrinsic.

%   Copyright 2022 The MathWorks, Inc.

mcls = meta.class.fromName(className);

methlist = mcls.MethodList;

metameth = findobj(methlist, 'Name', methodName);

defcls = metameth.DefiningClass; % This should be a scalar. 
                                 % It can only be defined in one place.
assert(isscalar(defcls));

dcname = defcls.Name; % Name of the defining class

% The method is implemented if the defining class is not one of our public
% base classes.

ours = {'positioning.INSSensorModel', 'positioning.INSMotionModel'};

tf = ~ismember(dcname, ours); % is the defining class one of our base classes

