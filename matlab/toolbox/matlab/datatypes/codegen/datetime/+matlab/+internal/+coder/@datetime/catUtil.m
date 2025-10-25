function [processedArgs,prototype] = catUtil(varargin) %#codegen
%CATUTIL Convert datetimes into doubledouble values that can be concatenated directly.
%   [PROCESSEDARGS,PROTOTYPE] = CATUTIL(ARGS) returns a cell array of
%   doubledouble values PROCESSEDARGS corresponding to those in cell array
%   ARGS respectively and a PROTOTYPE datetime, which has the same format
%   as the datetime object occuring first in ARGS.

%   Copyright 2019-2022 The MathWorks, Inc.
prototype.fmt = '';
prototype.tz = '';
for j = 1:nargin
   if isa(varargin{j},'datetime')
      prototype.fmt = varargin{j}.fmt;
      
      break;
   end
end

unzoned = isempty(prototype.tz);
leapSecs = strcmp(prototype.tz,datetime.UTCLeapSecsZoneID);
processedArgs = cell(1,nargin);

for i = 1:nargin
    coder.internal.errorIf(matlab.internal.coder.datatypes.isText(varargin{i}),'MATLAB:datetime:TextConstructionCodegen');
    coder.internal.assert(isa(varargin{i},'datetime') ||  isequal(varargin{i},[]), 'MATLAB:datetime:InvalidComparison',class(varargin{i}),'datetime');
    if isa(varargin{i},'datetime')
        checkCompatibleTZ(varargin{i}.tz,unzoned,leapSecs);
   elseif isequal(varargin{i},[])
        processedArgs{i} = []; % leave the data as just []
        continue
    end
   processedArgs{i} = varargin{i}.data;
end

