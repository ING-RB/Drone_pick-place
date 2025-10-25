function msg = convertStreamException(streamException, destinationIri)
%convertStreamException  Convert stream exception to a WRITE error message

%   Copyright 2018-2023 The MathWorks, Inc.

exceptionId = streamException.identifier;

if exceptionId == "MATLAB:virtualfileio:stream:permissionDenied"
    % Permission denied writing to the supplied bucket/container
    msg = message(exceptionId, destinationIri);
elseif exceptionId == "MATLAB:virtualfileio:stream:writeNotAllowed"
    % Write operation attempted on a Read-only provider
    msg = message(exceptionId);
elseif startsWith(exceptionId, "MATLAB:virtualfileio:hadooploader")
    msg = message(exceptionId);
elseif any(exceptionId == ["MATLAB:virtualfileio:stream:invalidFilename", ...
        "MATLAB:virtualfileio:stream:CannotFindLocation", "MATLAB:virtualfileio:stream:fileNotFound", ...
        "MATLAB:virtualfileio:stream:unableToOpenStream"])
    % Invalid destination: probably due to attempting to write to a
    % bucket/container that doesn't exist.  Parse out the bucket to embed
    % in the message.
    missingBucket = iParseBucketForErrorMessage(destinationIri);

    msg = message(...
        "MATLAB:virtualfileio:stream:CannotFindLocation", ...
        destinationIri, missingBucket);
elseif startsWith(exceptionId, "MATLAB:virtualfilesystem")
    % Rethrow VFS ExceptionContext errors.
    msg = message(exceptionId, destinationIri);
else
    % All other errors are considered a generic remote failure
    msg = message('MATLAB:virtualfileio:stream:RemoteFailure', destinationIri);
end
end

function bucketName = iParseBucketForErrorMessage(iri)
% Parse the bucket/container part of the IRI along with the scheme part.

iri = convertCharsToStrings(iri);
scheme = extractBefore(iri, "://");
bucketName = extractBetween(iri, "://", "/", "Boundaries", "exclusive");

if isempty(bucketName) || contains(bucketName,":/")
    % No path component
    bucketName = iri;
    return;
end

bucketName = scheme + "://" + bucketName;
end
