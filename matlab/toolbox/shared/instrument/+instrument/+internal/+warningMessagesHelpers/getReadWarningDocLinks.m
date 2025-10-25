function [docIDNoDataRef, docIDSomeDataRef] = getReadWarningDocLinks(objectClass, objectType)

%GETREADWARNINGDOCLINKS handles the warning messages that may arise when communication with a device using ICT.

% A=GETREADWARNINGDOCLINKS(OBJECTCLASS, OBJECTTYPE) Takes in the object class
% (serial, serialport, gpib, tcpip, visa, udp) char
% array OBJECTCLASS.
% OBJECTTYPE is a char array that holds the visa type (like visa-serial, visa-usb, etc).
% Calling this helper function returns the appropriate document links corresponding to the
% warnings.

%   Copyright 2017-2023 The MathWorks, Inc.

docIDNoData = '';
docIDSomeData = '';
docIDNoDataRef = '';
docIDSomeDataRef = '';
isVisa = false;
objectClass = instrument.internal.stringConversionHelpers.str2char(objectClass);
if strcmpi(objectClass, 'visa')
    isVisa = true;
    linkTag = message("transportlib:utils:ReadWarningLinkTag","VISA").getString;
    visaType = instrument.internal.stringConversionHelpers.str2char(objectType);
    switch visaType

        % We treat visa-serial similar to serial
        case 'visa-serial'
            objectClass = 'serial';

            % We treat visa-gpib, tcpip and usb similar to gpib
        case {'visa-gpib', 'visa-tcpip', 'visa-usb'}
            objectClass = 'gpib';

        case 'visa-generic'
            docIDNoData = 'tcpsocket_nodata';
            docIDSomeData = 'tcpsocket_somedata';
            objectClass = 'visa';

        otherwise
            objectClass = 'visa';
    end
end

% Exclusively test for matlab bluetooth. This is because the switch below
% does a lower case check for the object type, which would cause a
% collision for the matlab "bluetooth" class and the ICT "Bluetooth" class
if string(objectClass) == "bluetooth"
    % Binary/ASCII/BinBlock
    docIDNoData = 'bluetooth_nodata';
    docIDSomeData = 'bluetooth_somedata';
    linkTag = message("transportlib:utils:ReadWarningLinkTag","bluetooth").getString;
    docIDMapLoc = 'matlab: helpview(''matlab'', ';
    docIDNoDataRef = getDocIDRef(docIDMapLoc, docIDNoData, linkTag);
    docIDSomeDataRef = getDocIDRef(docIDMapLoc, docIDSomeData, linkTag);
    return
end

switch lower(objectClass)
    case 'serialport'
        linkTag = message("transportlib:utils:ReadWarningLinkTag","serialport").getString;
        % Binary/ASCII/BinBlock
        docIDNoData = 'serialport_nodata';
        % Only Binary
        docIDSomeData = 'serialport_somedata';

    case 'serial'
        if ~isVisa
            linkTag = message("transportlib:utils:ReadWarningLinkTag","Serial").getString;
        end
        % Binary/ASCII/BinBlock
        docIDNoData = 'serial_nodata';
        docIDSomeData = 'serial_somedata';

    case 'bluetooth'
        if ~isVisa
            linkTag = message("transportlib:utils:ReadWarningLinkTag","Bluetooth").getString;
        end

        % Binary/ASCII/BinBlock
        docIDNoData = 'bt_nodata';
        docIDSomeData = 'bt_somedata';

    case 'udp'
        if ~isVisa
            linkTag = message("transportlib:utils:ReadWarningLinkTag","UDP").getString;
        end

        % Binary/ASCII/BinBlock
        docIDNoData = 'udp_nodata';
        docIDSomeData = 'udp_somedata';

    case 'tcpip'
        if ~isVisa
            linkTag = message("transportlib:utils:ReadWarningLinkTag","TCPIP").getString;
        end
        % Binary/ASCII/BinBlock
        docIDNoData = 'tcpip_nodata';
        docIDSomeData = 'tcpip_somedata';

    case 'gpib'
        if ~isVisa
            linkTag = message("transportlib:utils:ReadWarningLinkTag","GPIB").getString;
        end
        % Binary/ASCII/BinBlock
        docIDNoData = 'gpib_nodata';
        docIDSomeData = 'gpib_somedata';

    case 'tcpclient'
        linkTag = message("transportlib:utils:ReadWarningLinkTag","tcpclient").getString;
        % ASCII/BinBlock
        docIDNoData = 'tcpclient_nodata';
        % Empty as partial reads not supported
        docIDSomeData = '';

    case 'udpport'
        linkTag = message("transportlib:utils:ReadWarningLinkTag","udpport").getString;
        % Binary/ASCII
        docIDNoData = 'udpport_nodata';
        docIDSomeData = 'udpport_somedata';

    case 'tcpserver'
        linkTag = message("transportlib:utils:ReadWarningLinkTag","tcpserver").getString;
        % Binary/ASCII/BinBlock
        docIDNoData = 'tcpserver_nodata';
        docIDSomeData = 'tcpserver_somedata';
        
    case 'visadev'
        linkTag = message("transportlib:utils:ReadWarningLinkTag","visadev").getString;
        % Binary/ASCII/BinBlock
        docIDNoData = 'visadev_nodata';
        docIDSomeData = 'visadev_somedata';        
end

% Choose whether the anchor IDs are being looked up in the ICT doc or base
% MATLAB doc, based on the interface type. The bluetooth anchor IDs are
% only in MATLAB doc. The serialport and tcpclient anchor IDs are in both
% MATLAB and ICT doc. The visadev and udpport anchor IDs are only in ICT doc.
if requiresICTDoc(objectClass)
    docIDMapLoc = 'matlab: helpview(''instrument'', ';
else
    docIDMapLoc = 'matlab: helpview(''matlab'', ';
end

% Get the doc IDs.
if ~isempty(docIDNoData)
    docIDNoDataRef = getDocIDRef(docIDMapLoc, docIDNoData, linkTag);
end
if ~isempty(docIDSomeData)
    docIDSomeDataRef = getDocIDRef(docIDMapLoc, docIDSomeData, linkTag);
end
end

function docRef = getDocIDRef(docIDMapLoc, docID, linkTag)
% Get the doc reference link for the specified anchor id.

linkExecutionFunction = [docIDMapLoc '''' docID '''' ')'];
docRef = ['<a href=' '"' linkExecutionFunction '"''>' linkTag '</a>'];
end

function ictDoc = requiresICTDoc(objectType)
switch char(objectType)
    case {'serialport', 'tcpclient'}
        installedProducts = ver;
        productNames = {installedProducts.Name};

        % Link to the ICT doc instead of MATLAB doc for the serialport and
        % tcpclient interfaces if and only if the user has ICT installed
        % and is licensed to use it.
        ictDoc = ismember('Instrument Control Toolbox', productNames) ...
            && builtin('license', 'test', 'Instr_Control_Toolbox');
    case 'bluetooth'
        ictDoc = false;
    otherwise
        ictDoc = true;
end
end