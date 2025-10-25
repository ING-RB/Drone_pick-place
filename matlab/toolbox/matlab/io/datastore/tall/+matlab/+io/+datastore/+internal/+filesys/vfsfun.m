function varargout = vfsfun(fcn, split)
%VFSFUN Evalulate a function on a VFS location.

%   Copyright 2018 The MathWorks, Inc.

rdr = matlab.io.datastore.splitreader.WholeFileCustomReadSplitReader;
rdr.ReadFcn = fcn;
rdr.Split = split;
rdr.reset();
[varargout{1:min(nargout, 1)}] = rdr.getNext();
end