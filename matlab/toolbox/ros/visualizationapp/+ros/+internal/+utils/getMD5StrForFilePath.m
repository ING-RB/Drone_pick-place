function md5str = getMD5StrForFilePath(filePath)
%This class is for internal use only. It may be removed in the future.

%   This is used for generating MD5 string for the rosbag file

%   Copyright 2023 The MathWorks, Inc.

digester = matlab.internal.crypto.BasicDigester('DeprecatedMD5');
bytes = digester.computeFileDigest(filePath);
md5str = matlab.internal.crypto.hexEncode(bytes);
end

