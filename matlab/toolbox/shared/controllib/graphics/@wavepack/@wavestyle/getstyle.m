function [Color,LineStyle,Marker] = getstyle(this,RowIndex,ColIndex,RespIndex)
%GETSTYLE  Returns style for given I/O pair and model.

%  Author(s): P. Gahinet
%  Copyright 1986-2004 The MathWorks, Inc.

[s1,s2,s3] = size(this.Colors);

if this.EnableTheming
    % If manual colors are not set, return the semantic colors stored by
    % default
    Color = this.SemanticColors(1+rem(RowIndex-1,s1),1+rem(ColIndex-1,s2),1+rem(RespIndex-1,s3));
else
    % otherwise return manual colors provided
    Color = this.Colors{1+rem(RowIndex-1,s1),1+rem(ColIndex-1,s2),1+rem(RespIndex-1,s3)};
end

[s1,s2,s3] = size(this.LineStyles);
LineStyle = this.LineStyles{1+rem(RowIndex-1,s1),1+rem(ColIndex-1,s2),1+rem(RespIndex-1,s3)};

[s1,s2,s3] = size(this.Markers);
Marker = this.Markers{1+rem(RowIndex-1,s1),1+rem(ColIndex-1,s2),1+rem(RespIndex-1,s3)};