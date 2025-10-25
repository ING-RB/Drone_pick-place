function  [fid,BOM] = updateFIDforBOM(fid,encoding)
%UPDATEFIDFORBOM Checks a file's leading bytes to see if it has a Byte Order Mark
% [encoding, byteorder, sz] = checkBOM(fid) checks a file id for a BOM and skips
% it. If a BOM is found, encoding is the associated name of the encoding,
% and byteorder is 'b' for big endian or 'l' for little endian. Otherwise
% these outputs are empty. sz is the number of bytes in the Mark, or zero if not found.
% NOTE: fid can be modified by this function.

% Copyright 2018 The MathWorks, Inc.

% It's not likely this will change, but checkBOMFromBytes will error appropriately
% if the number of bytes needed increases
maxNumBytesForBom = 5;

assert(ftell(fid)==0);
bytes = fread(fid, maxNumBytesForBom, 'uint8=>uint8');
if numel(bytes) < maxNumBytesForBom
    % File might have been too short
    bytes = ones(maxNumBytesForBom, 1, "uint8"); % not a BOM.
end
BOM = matlab.io.text.internal.checkBOMFromBytes(bytes);
[name,mode,~,actEnc] = fopen(fid);

fseek(fid, BOM.NumBytes, 'bof');
if BOM.NumBytes == 0
    % nothing left to do; there is no BOM in the file.
    return
end

% If the encoding is SYSTEM, switch silently to UTF-8 when we detect the
% UTF-8 BOM.
if all(strcmp({encoding, BOM.Encoding},["system", "UTF-8"]))
    fclose(fid);
    fid = fopen(name,mode,"n","UTF-8");
    fseek(fid,BOM.NumBytes,"bof");
    return
end

matlab.io.internal.utility.warnOnBOMmismatch(BOM,actEnc);

