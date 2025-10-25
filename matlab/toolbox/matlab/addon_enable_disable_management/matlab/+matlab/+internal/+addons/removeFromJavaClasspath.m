function removeFromJavaClasspath(jarFile)

% Removes the specified jar file from javaclasspath

% Copyright 2017-2018 The MathWorks Inc.

% Ignore warning if not found in path
w = warning('off','MATLAB:GENERAL:JAVARMPATH:NotFoundInPath');
clean = onCleanup(@()warning(w));

javarmpath(char(jarFile));

end