function draw(cv,cd,NormalRefresh)
%DRAW  Draws peak response characteristic.

%   Author(s): John Glass
%   Copyright 1986-2005 The MathWorks, Inc.
for ct=1:numel(cv.Points)
   set(double(cv.Points(ct)),'XData',NaN,'YData',NaN)
end