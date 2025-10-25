classdef LightnessConverter
    %

    %LIGHTNESSCONVERTER provides tools to perform color conversions that
    %   flip the lightness of RGB color values.
    %   mx3 sRGB values are converted to a modified LCH color space. The
    %   lightness values are transformed such that colors that are
    %   generally light will become dark while maintaining hue and colors
    %   that are generally dark will become light. Colors within the middle
    %   lightness range will have a smaller change. Transformed colors
    %   are converted back to sRGB using an optimized form of chroma
    %   reduction gamut mapping.

    %  Copyright 2024 The MathWorks, Inc.

    properties (Constant)
        % Changing these constant may require updating chromasurface.dat.
        M1 = [... % Conversion matrix from linear-light sRGB to LMS at D65 whitepoint [1].
            0.412176459   0.536273974   0.051440372
            0.211909200   0.680717871   0.107399844
            0.088344814   0.281853963   0.630280869];
        M2 = [... % Conversion matrix from modified LMS to LAB [2].
            0.2104542553   0.7936177850  -0.0040720468
            1.9779984951  -2.4285922050   0.4505937099
            0.0259040371   0.7827717662  -0.8086757660]

        LMSgamma = 3 % Power nonlinearity applied to LMS values [2].
        SkewCorrectionExp = 1.5 % Centralizes lightness distribution around ~0.5.

        % sRGB gamma correction and linearization parmeters [3].
        Gamma = 2.4
        a = 1.055
        b = -0.055
        c = 12.92
        srgbThresh = 0.04045
        lrgbThresh = 0.0031308
    end

    methods (Static)
        function rgb = convertLightness(rgb)
            % convertLightness runs through the conversion steps to flip lightness.
            % rgb is an mx3 matrix of sRGB values in the range [0,1].
            arguments
                rgb (:,3) {mustBeFloat, mustBeInRange(rgb,0,1)}
            end
            % Convert RGB values to a modified LCH color space.
            lch = matlab.graphics.internal.LightnessConverter.rgb2lch(rgb);
            % Transform the lightness values
            lch = matlab.graphics.internal.LightnessConverter.flipLightnessValue(lch);
            % Map LCH colors back into the RGB gamut
            rgb = matlab.graphics.internal.LightnessConverter.gamutmapping(lch);
        end

        function lch = rgb2lch(rgb)
            % Convert sRGB (mx3) to a modified lch space (mx3).
            % Lightness range: [0, 1]
            % Chroma range: [0, ~0.34]
            % Hue range: [0,360];
            arguments
                rgb (:,3) {mustBeFloat, mustBeInRange(rgb,0,1)}
            end
            % MATLAB's sRGB is gamma-correct and must be converted to linear RGB for computation.
            rgblinear = matlab.graphics.internal.LightnessConverter.srgb2lin(rgb);
            lms = rgblinear * matlab.graphics.internal.LightnessConverter.M1.';
            lmsp = nthroot(lms,matlab.graphics.internal.LightnessConverter.LMSgamma);
            oklab = lmsp * matlab.graphics.internal.LightnessConverter.M2.';
            lch = [oklab(:,1), hypot(oklab(:,2),oklab(:,3)), wrap360(atan2d(oklab(:,3),oklab(:,2)))];
        end

        function lch = flipLightnessValue(lch)
            % Perform a skew correction on lightness values and flip
            % lightness. lch is mx3 lch color space values with a
            % Lighness range [0,1].
            arguments
                lch (:,3) {mustBeFloat, mustBeLCHgamut}
            end
            lch(:,1) = nthroot(1 - lch(:,1).^matlab.graphics.internal.LightnessConverter.SkewCorrectionExp, ...
                matlab.graphics.internal.LightnessConverter.SkewCorrectionExp);
        end

        function rgbMapped = gamutmapping(lch)
            % Map LCH (mx3) values back into the RGB gamut using an
            % optimized form of chroma reduction. Values are converted from
            % LCH to RGB; values outside of the RGB gamut (<0 | >1) are
            % remapped in LCH by reducing their chroma values to the
            % approximate maximum chroma for the hue and lightness before
            % converting back into RGB.
            arguments
                lch (:,3) {mustBeFloat, mustBeLCHgamut}
            end
            rgbMapped = matlab.graphics.internal.LightnessConverter.lch2rgb(lch);
            isout = matlab.graphics.internal.LightnessConverter.isOutOfGamut(rgbMapped);
            if any(isout)
                lch(isout,2) = matlab.graphics.internal.LightnessConverter.mapToChromaSurface(lch(isout,:));
                rgbMapped(isout,:) = matlab.graphics.internal.LightnessConverter.lch2rgb(lch(isout,:));
                % rgb values can still be out of gamut by ~0.001 due to
                % approximations in chroma surface interpolation. Round
                % those cases.
                rgbMapped(rgbMapped<0) = 0;
                rgbMapped(rgbMapped>1) = 1;
            end
        end

        function srgb = lch2rgb(lch)
            % Convert LCH (mx3) to sRGB (mx3), pre gamut mapping. sRGB
            % values may be out of [0,1] range.
            arguments
                lch (:,3) {mustBeFloat, mustBeLCHgamut}
            end
            lab = [lch(:,1), lch(:,2).*[cosd(lch(:,3)), sind(lch(:,3))]].';
            lrgb = (matlab.graphics.internal.LightnessConverter.M1\(matlab.graphics.internal.LightnessConverter.M2\lab).^matlab.graphics.internal.LightnessConverter.LMSgamma).';
            srgb = matlab.graphics.internal.LightnessConverter.lin2srgb(lrgb);
        end

        function maxChroma = mapToChromaSurface(lch)
            % Map LCH colors that are out of the RGB gamut using chroma reduction.
            % maxChroma (mx1) is the max chroma value for each (hue,
            % lightness) value in the LCH inputs (mx3). LCH inputs are
            % outside of the RGB gamut with lightness values in
            % the range [0,1]. The maxChroma is computed by interpolating
            % from a 3D surface created by a grid of hue and lightness values
            % along with their corresponding maximum chroma values that are in
            % the RGB gamut.
            % Visually inspect chroma surface and points mapped to surface:
            % surf(hueDefs,lightnessDefs,chromaSurf,EdgeColor='none')
            % hold on; plot3(lch(:,3), lch(:,1), maxChroma, 'ko', LineWidth=2)
            arguments
                lch (:,3) {mustBeFloat, mustBeLCHgamut}
            end
            persistent file
            if isempty(file)
                % The dat file shares the same location as this file.
                % chromasurface.dat generation: generateChromasurfaceDatFile.m
                namespace = class(matlab.graphics.internal.LightnessConverter);
                file = fullfile(fileparts(which(namespace)),'chromasurface.dat'); % [4]
            end
            % Read in and convert base 16 hexidecimal values for the
            % chroma surface.
            fid = fopen(file,'r');
            cleanupFID = onCleanup(@()fclose(fid));
            M = textscan(fid,'%xu16');
            M = cast(M{:},'like',lch);
            % Reconstruct rows for Lightness=1|0 and a column for h=360
            % which is a duplicate of h=0.
            expectedSize = [199,360];
            chromaSurf = 0.0001 * reshape(M,flip(expectedSize)).';
            chromaSurf = [zeros(1,expectedSize(2),'like',lch); chromaSurf; zeros(1,expectedSize(2),'like',lch)];
            chromaSurf(:,end+1) = chromaSurf(:,1);
            % Compute max chroma values along the chroma surface.
            % Hue values must be wrapped to [0,360].
            hueDefs = 0:360;
            lightnessDefs = 0:.005:1;
            maxChroma = interp2(hueDefs, lightnessDefs, chromaSurf, wrap360(lch(:,3)), lch(:,1));
        end

        function TF = isOutOfGamut(rgb)
            % Determines if any RGB values are out of the RGB gamut.
            % rgb is mx3 RGB values that may exceed [0,1].
            % TF is mx1 logical vector where TRUE is out of gamut.
            arguments
                rgb (:,3) {mustBeFloat}
            end
            TF = any(rgb<0 | rgb>1,2);
        end

        function lrgb = srgb2lin(srgb)
            % Linearize gamma corrected sRGB values; no gamut restrictions.
            arguments
                srgb (:,3) {mustBeFloat}
            end
            isLinRange = srgb < matlab.graphics.internal.LightnessConverter.srgbThresh;
            lrgb = zeros(size(srgb),'like',srgb);
            lrgb(~isLinRange) = exp(matlab.graphics.internal.LightnessConverter.Gamma .* ...
                log(1/matlab.graphics.internal.LightnessConverter.a * srgb(~isLinRange) - matlab.graphics.internal.LightnessConverter.b/matlab.graphics.internal.LightnessConverter.a));
            lrgb(isLinRange) = 1/matlab.graphics.internal.LightnessConverter.c * srgb(isLinRange);
        end

        function srgb = lin2srgb(lrgb)
            % Appy gamma correction to linear RGB values; no gamut
            % restrictions.
            arguments
                lrgb (:,3) {mustBeFloat}
            end
            isnegative = lrgb<0;
            lrgb = abs(lrgb);
            isLinRange = lrgb  < matlab.graphics.internal.LightnessConverter.lrgbThresh;
            srgb = zeros(size(lrgb),'like',lrgb);
            srgb(~isLinRange) = matlab.graphics.internal.LightnessConverter.a * ...
                exp(1/matlab.graphics.internal.LightnessConverter.Gamma .* log(lrgb(~isLinRange))) + matlab.graphics.internal.LightnessConverter.b;
            srgb(isLinRange) = matlab.graphics.internal.LightnessConverter.c * lrgb(isLinRange);
            srgb(isnegative) = -1*srgb(isnegative);
        end
    end

end

function w = wrap360(d)
% Wrap d to [0,360] while preserving values at 360.
w = mod(d, 360);
w(d==360) = 360;
end

function mustBeLCHgamut(lch)
% Validation function for range of LCH values.
% Lightness range: [0,1]
% Chroma range: [0,inf] there is no fixed upper limit, though typically <0.34)
% Hue range: unbounded (degrees, internally wrapped to [0,360])
if any(lch(:,[1,2])<0 | lch(:,1)>1,'all')
    error(message('MATLAB:LightnessConverter:LCHmustBeInRange'))
end
end

%% Footnotes
% [1] M1 is the result of multiplying the linear-light sRGB-to-CEIXYZ
%   conversion matrix (A) and the XYZ-to-LMS conversion matrix (B).
%   M1 = B*A
%
%   Source: IEC 61966-2-1:1999
%   A = [0.412390799265959   0.357584339383878   0.180480788401834
%        0.212639005871510   0.715168678767756   0.072192315360734
%        0.019330818715592   0.119194779794626   0.950532152249661]
%
%   Source: Ottosson, B. (2020, December 23). Oklab; https://bottosson.github.io/posts/oklab
%   B = [0.8189330101, 0.3618667424, -0.1288597137
%        0.0329845436, 0.9293118715, 0.0361456387
%        0.0482003018, 0.2643662691, 0.6338517070]
%
% [2] M2 Source: Ottosson, B. (2020, December 23). Oklab; https://bottosson.github.io/posts/oklab
% [3] sRGB gamma correction parmeters: https://www.mathworks.com/help/images/understanding-color-spaces-and-color-space-conversion.html
% [4] chromasurface.dat was computed from a grid of (hue,lightness) values
%   and the approximate maximum chroma value for each (hue,lightness)
%   combination. Values are stored as base 16 (headecimal).