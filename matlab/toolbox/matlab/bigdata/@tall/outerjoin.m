function varargout = outerjoin(A,B,varargin)
%OUTERJOIN Outer join between two tables or two timetables.
%   T = OUTERJOIN(TLEFT,TRIGHT) 
%   T = OUTERJOIN(TLEFT,TRIGHT,'Keys',K)
%   T = OUTERJOIN(TLEFT,TRIGHT,'LeftKeys',LK,'RightKeys',RK)
%   T = OUTERJOIN(...,'LeftVariables',LV,'RightVariables',RV)
%   T = OUTERJOIN(...,'MergeKeys',TF)
%   T = OUTERJOIN(...,'Type',LR)
%   [T,ILEFT,IRIGHT] = OUTERJOIN(...) 
%
%   See also TABLE/OUTERJOIN, TIMETABLE/OUTERJOIN,
%            TALL/JOIN, TALL/INNERJOIN

%   Copyright 2019-2023 The MathWorks, Inc.

[varargout{1:nargout}] = joinInnerOuter('outerjoin',A,B,...
    inputname(1),inputname(2),varargin{:});