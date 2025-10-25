function hash = createFileHash(appCode)
    %CREATEFILEHASH Creates a sha1 hash based on the argued app code
    %       Before creating hash this will strip out any non-executing code
    %       resulting in no formatting or comments. Doing this allows apps
    %       to load clean even after we make trivial changes to formatting
    %       or comments between releases.

    % Copyright 2021, MathWorks inc.
    
    code = appdesigner.internal.codegeneration.removeNonExecutingCode(appCode);

    msg = ['string:', num2str(length(code)), ':', code];
    
    % SHA1 Digest
    digestBytes = matlab.internal.crypto.BasicDigester("DeprecatedSHA1");
    uint8Digest = digestBytes.computeDigest(msg);
    hash = sprintf('%.2x', double(uint8Digest));
end

