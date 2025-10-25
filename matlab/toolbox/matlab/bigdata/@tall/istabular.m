function tf = istabular(a)
%ISTABULAR True for tall table or timetable.
%   TF = ISTABULAR(T)
%   
%   See also ISTABULAR, TALL.

%   Copyright 2022-2024 The MathWorks, Inc.

tf = a.Adaptor.Class == "table" || a.Adaptor.Class == "timetable";