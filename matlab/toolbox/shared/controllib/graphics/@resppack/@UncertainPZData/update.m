function update(this,r)
%UPDATE  Data update method @UncertainTimeData class

%   Author(s): Craig Buhr
%   Copyright 1986-2010 The MathWorks, Inc.


for ct=1:length(wchar.Data)
   % Propagate exceptions
   this.Data(ct).Exception = r.Data(ct).Exception;
   if ~this.Data(ct).Exception
      getUncertainPZData(r.DataSrc,r,this.Data,[],[]);
   end
end

