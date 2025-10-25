function hash = classHash(metaClass)
% This function is unsupported and might change or be removed without 
% notice in a future version.

% Copyright 2023 The MathWorks, Inc.

arguments
    metaClass (1,1) meta.class
end

import matlab.buildtool.internal.whichFile;
import matlab.internal.crypto.BasicDigester;

allClasses = [metaClass; allSuperClasses(metaClass)];
classNames = unique({allClasses.Name});

digester = BasicDigester("Blake-2b");

files = cellfun(@(n)whichFile(n), classNames);
fileHashes = zeros(digester.DigestSize, numel(files), "uint8");
for i = 1:numel(files)
    file = files(i);
    if ~startsWith(file, matlabroot()) && isfile(file)
        fh = digester.computeFileDigest(file);
    else
        fh = digester.computeDigest(classNames{i});
    end
    fileHashes(:,i) = fh;
end

hash = digester.computeDigest(fileHashes(:)');
end

function mcs = allSuperClasses(mc)
mcs = mc.SuperclassList;
for k = 1:length(mcs)
    mcs = [mcs; allSuperClasses(mcs(k))]; %#ok<AGROW>
end
end