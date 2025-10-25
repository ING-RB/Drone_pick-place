function hh = bar3h(varargin)
%BAR3H  Horizontal 3-D bar graph.
%     BAR3H(Y) creates a 3-D bar chart, where each element in Y corresponds
%     to one horizontal bar. When Z is a vector, the z-axis scale ranges
%     from 1 to length(Y). When Y is a matrix, the z-axis scale ranges from
%     1 to the number of rows in Y.
%  
%     BAR3H(Z,Y) draws the bars at the locations specified in vector Z.  The 
%     z-values can be nonmonotonic, but cannot contain duplicate values.
%  
%     BAR3H(...,WIDTH) controls the separation between bars. A WIDTH value
%     greater than 1 produces overlapped bars. The default WIDTH value is
%     0.8.
%  
%     BAR3H(...,STYLE) specifies the bar style, where STYLE is either
%     'detached', 'grouped', or 'stacked'. The default STYLE value is
%     'detached'.
% 
%     BAR3H(...,COLOR) specifies the line color. Specify the color as one
%     of these values: 'r', 'g', 'b', 'y', 'm', 'c', 'k', or 'w'.
%  
%     BAR3H(AX,...) plots into the axes AX instead of the current axes.
%  
%     H = BAR3H(...) returns a vector of Surface objects.
%  
%     Example:
%         subplot(1,2,1) 
%         bar3h(peaks(5))
%         subplot(1,2,2) 
%         bar3h(rand(5),'stacked')
%  
%   See also BAR, BARH, BAR3.

%   Mark W. Reichelt 8-24-93
%   Revised by CMT 10-19-94, WSun 8-9-95
%   Copyright 1984-2018 The MathWorks, Inc.

narginchk(1,inf);
h = bar3(varargin{:},'horizontal');

if nargout>0
    hh = h;
end
