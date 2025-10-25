function rgb = convertColorSpecToRGB(spec, outputClass, functionName, argName)
% pointclouds.internal.convertColorSpecToRGB Convert MATLAB ColorSpec to RGB triplet
%
% Example
% -------
% rgbFill = pointclouds.internal.convertColorSpecToRGB('r', 'uint8', 'pointCloud', 'Color')

%  Copyright 2022-2023 The MathWorks, Inc.

%#codegen
    
if isnumeric(spec)
    rgb = cast(spec, outputClass);
else
    if iscell(spec)
        colorCell = spec;
    else
        colorCell = {spec};
    end
    
    numColors = length(colorCell);
    rgb = zeros(numColors, 3, outputClass);
    
    for ii = 1:numColors
        supportedColorStr = {'blue', 'green', 'red', 'cyan', 'magenta', 'yellow',...
            'black', 'white'};

        % Expand color value if the input is "b" to avoid ambiguity between
        % blue and black color.
        if strcmpi(colorCell{ii},'b')
            inputColor = 'blue';
        elseif strcmpi(colorCell{ii},'k')
            inputColor = 'black';
        else
            inputColor = colorCell{ii};
        end

        % validatestring to get partial matches.
        colorString = validatestring(inputColor, supportedColorStr, ...
            functionName, argName);
        idx = strcmp(colorString, supportedColorStr);

        % rgb triplets for the corresponding color strings as mentioned
        % in http://www.mathworks.com/help/techdoc/ref/colorspec.html
        rgbValuesFloat = [0 0 1; 0 1 0; 1 0 0; 0 1 1; 1 0 1; 1 1 0; 0 0 0; 1 1 1];
        switch outputClass
            case {'double', 'single'}
                rgb(ii, :) = rgbValuesFloat(idx, :);
            case {'uint8', 'uint16'}
                rgbValuesUint = rgbValuesFloat*double(intmax(outputClass));
                rgb(ii, :) = rgbValuesUint(idx, :);
            case 'int16'
                rgbValuesInt16 = im2int16(rgbValuesFloat);
                rgb(ii, :) = rgbValuesInt16(idx, :);
        end
    end
end

end