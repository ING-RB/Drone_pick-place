function tf = isheif(filename)
% ISHEIF Returns true for a HEIF/HEIC file.
%   TF = ISHEIF(FILENAME)

%   Copyright 2024-2025 The MathWorks, Inc.

arguments
    filename (1,:) char {mustBeFile}
end

fid = matlab.internal.fopen(filename, 'r', 'ieee-le');
assert(fid ~= -1, message('MATLAB:imagesci:validate:fileOpen', filename));
headerData = fread(fid, 32, 'uint8');
fclose(fid);

% The following arrays represent decimal ASCII values for specific strings
% that are expected to be part of a valid HEIC/HEIF file's header. These
% strings are crucial identifiers used to verify the file format.
% The task is to search for these subarrays within the main header data
% array to ascertain whether the file is indeed a valid HEIF/HEIC file.
% The subarrays correspond to:
% - 'ftyp' (66747970 in hexadecimal)
% - 'mif1' (6D696631 in hexadecimal)
% - 'heic' (68656963 in hexadecimal)
% - 'heif' (68656966 in hexadecimal)
%
% The presence of these identifiers in the header data confirms the file
% format as HEIF/HEIC.

% The HEIF/HEIC file should start with 'ftyp', which is part of the ISO Base Media File Format.
ftypArray = [102;116;121;112];
% 'mif1' indicates the file conforms to the HEIF specification
mif1Array = [109;105;102;49];
% 'heic' Specifically indicates HEIC format
heicArray = [104;101;105;99];
% 'heif' Specifically indicates HEIF format
heifArray = [104;101;105;102];

% Check for each of the above subarray in the header data
isftypPresent = containsSubArray(headerData, ftypArray);
ismif1Present = containsSubArray(headerData, mif1Array);
isheicPresent = containsSubArray(headerData, heicArray);
isheifPresent = containsSubArray(headerData, heifArray);

% If all the conditions for a valid HEIF/HEIC file match, then return true
tf = isftypPresent &&  ismif1Present && (isheicPresent || isheifPresent);

end

% Function to check if a subarray exists within the main array
function found = containsSubArray(mainArray, subArray)
    found = false;
    lenMain = length(mainArray);
    lenSub = length(subArray);
    for i = 1:(lenMain - lenSub + 1)
        if isequal(mainArray(i:i+lenSub-1), subArray)
            found = true;
            break;
        end
    end
end
