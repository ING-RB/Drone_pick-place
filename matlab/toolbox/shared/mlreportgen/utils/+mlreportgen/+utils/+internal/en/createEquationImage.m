%CREATEEQUATIONIMAGE returns empty or a TeX warning after parsing the equation
%    TEXWARNING=MLREPORTGEN.UTILS.INTERNAL.CREATEEQUATIONIMAGE(FILENAME,EQUATIONTEXT,FORMATTYPE,FONTSIZE)
%
%    FILENAME output image path
%    EQUATIONTEXT the TeX equation. For example: 'x^2+e^{\pi i}'
%    FORMATTYPE like the formattype argument at print figure command.
%      For example: '-dsvg'
%    FONTSIZE font size of equation text
%
%    CREATEEQUATIONIMAGE(filename,equationText,formattype,fontsize) saves
%     the equation text to an image file in the specified format and fontsize.
%
%    CREATEEQUATIONIMAGE(filename,equationText,formattype,fontsize, ...
%          color,backgroundColor) saves the equation text to an image file
%     in the specified format, fontsize, color, and background color.

 
    %   Copyright 2016-2025 The MathWorks, Inc.

