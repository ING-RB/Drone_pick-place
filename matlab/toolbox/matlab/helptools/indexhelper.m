function indexhelper(demosroot,source,callback,product,label,file)
% INDEXHELPER A helper function for the demos index page.

% Matthew J. Simoneau, January 2004
% Copyright 1984-2020 The MathWorks, Inc.

% Remove escaping.
if (nargin > 0)
    demosroot = decode(demosroot);
end
if (nargin > 1)
    source = decode(source);
end
if (nargin > 2)
    callback = decode(callback);
end
if (nargin > 3)
    product = decode(product);
end
if (nargin > 4)
    label = decode(label);
end
if (nargin > 5)
    file = decode(file);
end

if isempty(callback)
    callback = source;
end
if isempty(file)
   body = '';
   base = '';
else
   fullpath = fullfile(demosroot,file);
   f = fopen(fullpath);
   if (f == -1)
      error(message('MATLAB:indexhelper:OpenFailed', fullpath));
   end
   body = fread(f,'char=>char')';
   fclose(f);
   base = ['file:///' fullpath];
end
   
if isempty(callback)
   web(fullpath,'-helpbrowser')
else
   demowin(callback,product,label,body,base)
end

%===============================================================================
function label=decode(label)
label = char(matlab.net.internal.urldecode(char(label)));