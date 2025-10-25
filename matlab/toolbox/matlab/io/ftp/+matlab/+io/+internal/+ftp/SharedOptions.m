classdef SharedOptions < handle
%SHAREDOPTIONS 

%   Copyright 2024 The MathWorks, Inc.

    properties
        ConnectionTimeout = minutes(5);
        TransferTimeout = minutes(inf);
        CertificateFilename (1, 1) string {mustBeNonmissing} = "default";
    end

    properties(Hidden)
        VerifyHost(1, 1) = true;
        VerifyPeer(1, 1) = true;
        LowConnectionSpeed(1, 1) = 0;
        LowConnectionTime(1, 1) = 0;
    end

    methods(Hidden)
        function configureProperties(obj,options)

            if isfield(options, "ConnectionTimeout")
                obj.ConnectionTimeout = options.ConnectionTimeout;
            end

            if isfield(options, "TransferTimeout")
                obj.TransferTimeout = options.TransferTimeout;
            end

            if isfield(options, "VerifyHost")
                validateLogical(options.VerifyHost, 'Verify Host');
                obj.VerifyHost = options.VerifyHost;
            end

            if isfield(options, "VerifyPeer")
                validateLogical(options.VerifyPeer, 'Verify Peer');
                obj.VerifyPeer = options.VerifyPeer;
            end

            if isfield(options, "CertificateFilename")
                obj.CertificateFilename = options.CertificateFilename;
            end

            if isfield(options, "LowConnectionSpeed")
                validateConnection(options.LowConnectionSpeed, 'Low Connection Speed');
                obj.LowConnectionSpeed = options.LowConnectionSpeed;
            end

            if isfield(options, "LowConnectionTime")
                validateConnection(options.LowConnectionTime, 'Low Connection Time');
                obj.LowConnectionTime = options.LowConnectionTime;
            end
        end
    end

    methods
        function set.ConnectionTimeout(obj, value)
            validateTimeout(value, "ConnectionTimeout");
            millisecondsTimeout = extractLongMilliseconds(value);
            matlab.io.ftp.internal.matlab.connectionTimeout(obj.Connection, millisecondsTimeout);
            obj.ConnectionTimeout = value;
        end

        function set.TransferTimeout(obj, value)
            validateTimeout(value, "TransferTimeout");
            millisecondsTimeout = extractLongMilliseconds(value);
            matlab.io.ftp.internal.matlab.transferTimeout(obj.Connection, millisecondsTimeout);
            obj.TransferTimeout = value;
        end

        function set.CertificateFilename(obj, value)

            matlab.io.ftp.validateCertificate(value);

            obj.CertificateFilename = value;
        end
    end
end

function validateTimeout(timeoutValue, timeoutMessage)
    classes = {'duration'};
    attributes = {'scalar', 'nonnan'};
    validateattributes(timeoutValue, classes, attributes, '', timeoutMessage);

    % Validate that a positive value has been provided.
    validateattributes(milliseconds(timeoutValue), "double", "positive", '', timeoutMessage);
end

function validateLogical(value, message)
    classes = {'logical'};
    validateattributes(value, classes, {}, '', message);
end

function validateConnection(value, message)
    classes = {'double'};
    attributes = {'scalar', 'nonnan', 'positive'};
    validateattributes(value, classes, attributes, '', message);
end

function millisecondsTimeout = extractLongMilliseconds(value)
    value = milliseconds(value);
    if isinf(value)
        % 0 is a sentinel in curl for inf (no timeout).
        millisecondsTimeout = 0;
    else
        % curl uses a "long" in milliseconds to represent timeouts.
        % long is 64 bits on maci64 and glnxa64 but it is 32 bits on win64.
        % Therefore truncate to uint32 before passing to the curl layer.
        % days(milliseconds(intmax('int32'))) is around 24 days, so users
        % can still set a fairly large millisecond timeout even with the 32-bit
        % long restriction.
        millisecondsTimeout = double(uint32(value));
    end
end
