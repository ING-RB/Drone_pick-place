function varargout = innerjoin(A,B,varargin)
%INNERJOIN Inner join between two tables or two timetables.
%   T = INNERJOIN(TLEFT,TRIGHT) 
%   T = INNERJOIN(TLEFT,TRIGHT,'Keys',K)
%   T = INNERJOIN(TLEFT,TRIGHT,'LeftKeys',LK,'RightKeys',RK)
%   T = INNERJOIN(...,'LeftVariables',LV,'RightVariables',RV)
%   [T,ILEFT,IRIGHT] = INNERJOIN(...) 
%
%   See also TABLE/INNERJOIN, TIMETABLE/INNERJOIN,
%            TALL/JOIN, TALL/OUTERJOIN

%   Copyright 2016-2023 The MathWorks, Inc.

[varargout{1:nargout}] = joinInnerOuter('innerjoin',A,B,...
    inputname(1),inputname(2),varargin{:});