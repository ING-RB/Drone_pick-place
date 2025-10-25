# -*-cperl-*-   # to get colors in emacs
# Copyright 2017-2019 The MathWorks, Inc.
# File: matlab/simulink/internal/tools/genresources.pl
# Abstract:
#   script to validate <!CDATA[ ... ]]>  portion of the <entry> element of the XML catalog that contains
#   <actions> element.
#   It does the following:
#       1. for every input xml file it will find all occurences of the <actions.*?</actions> pattern
#       2. every match will be validated against actions grammar that defined in the actions.xsd file
#  
#  sbm perl $(MW_ANCHOR)/matlab/simulink/internal/tools/validate_action.pl IN

use strict;
use warnings;

use XML::LibXML;
use File::Slurp;

Main();

# http://stackoverflow.com/questions/777543/how-can-i-read-the-error-output-of-external-commands-in-perl
# http://perldoc.perl.org/perlvar.html  (meaning of  $@ , $! , $^E , and $?)

sub validateActions {
    my ($actionsSnippet, $file, $parser, $schema, $counter) = @_;

    eval {
        my $actions_doc = $parser->load_xml(
            string => $actionsSnippet,
            validation => 0,
        );
        $schema->validate($actions_doc);
    };
    if ($@) {
        die "Problem in actions #$counter in the file $file\n".$@;
    }
}

sub ProcessXML {
    my ($file) = @_;

    my $parser = XML::LibXML->new();
    $parser->line_numbers(1);
    $parser->pedantic_parser(1);
    my $schema_string = join("", <DATA>);
    my $schema = XML::LibXML::Schema->new(string => $schema_string);
    
    my $file_content = read_file($file);
    my $counter = 1;
    while ($file_content =~ m/(<actions.*?<\/actions>)/gs) {
        validateActions($1, $file, $parser, $schema, $counter);
        $counter = $counter + 1;
    }
}

sub Main {

    if (@ARGV != 1) {
        die "Usage $0: IN.XML\n";
    }
    my ($inFile) = @ARGV;
    eval {
        ProcessXML($inFile);
    };
    
    if ($@) {
        my $error_message = $@;
        print "$inFile\n";
        die $error_message;
    }
    
}

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified" version="1.0">
    <xsd:simpleType name="restrictedString">
        <xsd:restriction base="xsd:string">
            <xsd:minLength value="0"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="callbackString">
        <xsd:restriction base="xsd:string">
            <xsd:pattern value="((matlab:)?.*)"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="idString">
        <xsd:restriction base="xsd:string">
            <xsd:pattern value="([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z_][a-zA-Z0-9_]*):([a-zA-Z_][a-zA-Z0-9_]*)"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="numberField">
        <xsd:restriction base="xsd:integer">
            <xsd:minInclusive value="1"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="numberArray">
        <xsd:restriction base="xsd:string">
            <xsd:pattern value="\s*((\{\d+,number,integer\})|([1-9][0-9]*))\s*(,\s*( (\{\d+,number,integer\})|([1-9][0-9]*))\s*)*"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="actionIdString">
        <xsd:restriction base="xsd:string">
            <xsd:pattern value="[a-zA-Z][a-zA-Z0-9_]*"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:simpleType name="actionIdStringArray">
        <xsd:restriction base="xsd:string">
            <xsd:pattern value="\s*((\{\d+\})|([a-zA-Z][a-zA-Z0-9_]*))\s*(,\s*((\{\d+\})|([a-zA-Z][a-zA-Z0-9_]*))\s*)*"/>
        </xsd:restriction>
    </xsd:simpleType>
    <xsd:complexType name="introType">
        <xsd:simpleContent>
            <xsd:extension base="restrictedString"/>
        </xsd:simpleContent>
    </xsd:complexType>
    
    <xsd:complexType name="hotlinkType" mixed="true">
        <xsd:annotation>
            <xsd:documentation>
                Element that usually represents link to the Simulink object 
            </xsd:documentation>
        </xsd:annotation>
        <xsd:attribute name="href" use="required"/>
    </xsd:complexType>
    <xsd:complexType name="sldiagType"  mixed="true">
        <xsd:annotation>
            <xsd:documentation>
                Element that represents link to the various
                Simulink related UI. It will be transformed
                to the hotlinkType type element at the runtime. 
            </xsd:documentation>
        </xsd:annotation>
        <xsd:attribute name="objparam" use="required"/>
        <xsd:attribute name="objui" use="required">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="configset"/>
                <xsd:enumeration value="blockdlg"/>
                <xsd:enumeration value="callback"/>
                <xsd:enumeration value="doc"/>
                <xsd:enumeration value="inport"/>
                <xsd:enumeration value="outport"/>
                <xsd:enumeration value="lconnport"/>
                <xsd:enumeration value="rconnport"/>
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
        <xsd:attribute name="objname" use="optional"/>
    </xsd:complexType>
    
    <xsd:complexType name="commandType"  mixed="true">
        <xsd:sequence>
            <xsd:choice minOccurs="0" maxOccurs="unbounded">
                <xsd:element name="a" type="hotlinkType" minOccurs="0" maxOccurs="unbounded"/>
                <xsd:element name="sldiag" type="sldiagType" minOccurs="0" maxOccurs="unbounded"/>
            </xsd:choice>
        </xsd:sequence>
    </xsd:complexType>
<!--
    <xsd:complexType name="commandType"  mixed="true">
        <xsd:sequence>
            <xsd:any minOccurs="0" maxOccurs="unbounded" processContents="lax"/>
        </xsd:sequence>
    </xsd:complexType>
    <xsd:complexType name="commandType">
        <xsd:simpleContent>
            <xsd:extension base="callbackString"/>
        </xsd:simpleContent>
    </xsd:complexType>
-->
    <xsd:complexType name="enumType">
        <xsd:simpleContent>
            <xsd:extension base="restrictedString"/>
        </xsd:simpleContent>
    </xsd:complexType>
    <xsd:complexType name="promptType">
        <xsd:simpleContent>
            <xsd:extension base="restrictedString"/>
        </xsd:simpleContent>
    </xsd:complexType>
    <xsd:complexType name="user_msgType">
        <xsd:simpleContent>
            <xsd:extension base="restrictedString"/>
        </xsd:simpleContent>
    </xsd:complexType>
    <xsd:complexType name="cargType">
        <xsd:sequence>
            <xsd:element name="txt_prompt" type="promptType" minOccurs="1" maxOccurs="1"/>
            <xsd:element name="def_cmd" type="commandType" minOccurs="0" maxOccurs="1"/>
            <xsd:choice>
                <xsd:element name="enum_cmd" type="commandType" minOccurs="0" maxOccurs="1"/>
                <xsd:element name="enum" type="enumType" minOccurs="0" maxOccurs="unbounded"/>
            </xsd:choice>
        </xsd:sequence>
        <xsd:attribute name="name" type="xsd:string"/>
        <xsd:attribute name="type">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="text"/>
                <xsd:enumeration value="menu"/>
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
        <xsd:attribute name="translate" type="xsd:boolean" use="optional" default="true"/>
    </xsd:complexType>
    <xsd:complexType name="cargsType">
        <xsd:sequence>
            <xsd:element name="carg" type="cargType" minOccurs="1" maxOccurs="2"/>
        </xsd:sequence>
    </xsd:complexType>
    <xsd:complexType name="actionMsgArgType"  mixed="true">
        <xsd:sequence>
            <xsd:element name="a" type="hotlinkType" minOccurs="0" maxOccurs="1"/>
        </xsd:sequence>
    </xsd:complexType>
<!--    
    <xsd:complexType name="actionMsgArgType">
        <xsd:simpleContent>
            <xsd:extension base="restrictedString"/>
        </xsd:simpleContent>
    </xsd:complexType>
-->
    <xsd:complexType name="msgActionType">
        <xsd:sequence>
            <xsd:element name="arg" type="actionMsgArgType" minOccurs="0" maxOccurs="unbounded"/>
        </xsd:sequence>
        <xsd:attribute name="id" type="idString"/>
    </xsd:complexType>
    
    
    <xsd:complexType name="actionTxtType"  mixed="true">
        <xsd:sequence>
            <xsd:choice minOccurs="0" maxOccurs="unbounded">
                <xsd:element name="a" type="hotlinkType" minOccurs="0" maxOccurs="unbounded"/>
                <xsd:element name="sldiag" type="sldiagType" minOccurs="0" maxOccurs="unbounded"/>
            </xsd:choice>
        </xsd:sequence>
        <xsd:attribute name="translate" type="xsd:boolean" default="true"/>
    </xsd:complexType>
<!--
    <xsd:complexType name="actionTxtType"  mixed="true">
        <xsd:sequence>
            <xsd:any minOccurs="0" maxOccurs="unbounded" processContents="lax"/>
        </xsd:sequence>
        <xsd:attribute name="translate" type="xsd:boolean" default="true"/>
    </xsd:complexType>
-->

    <xsd:complexType name="paramType">
        <xsd:sequence>
        <!-- obj element might have hotlink (at runtime) -->
            <xsd:element name="obj" type="commandType" minOccurs="1" maxOccurs="1"/>
            <xsd:element name="name" type="restrictedString" minOccurs="1" maxOccurs="1"/>
            <xsd:element name="val" type="restrictedString" minOccurs="1" maxOccurs="1"/>
        </xsd:sequence>
    </xsd:complexType>
    
    <xsd:complexType name="paramsType">
        <xsd:sequence>
            <xsd:element name="prm" type="paramType" minOccurs="1" maxOccurs="unbounded"/>
        </xsd:sequence>
    </xsd:complexType>

    <xsd:complexType name="actionType" mixed="false"> <!-- mix text and elements cargs -->
        <xsd:sequence>
            <xsd:choice minOccurs="0" maxOccurs="1">
                <xsd:element name="cmd" type="commandType" minOccurs="0" maxOccurs="1"/>
                <xsd:element name="params" type="paramsType" minOccurs="0" maxOccurs="1"/>
            </xsd:choice>
            <xsd:element name="cargs" type="cargsType" minOccurs="0" maxOccurs="1"/>
            <xsd:choice minOccurs="0" maxOccurs="1">
                <xsd:element name="txt"   type="actionTxtType"/>
                <xsd:element name="msg"   type="msgActionType"/>
            </xsd:choice>
        </xsd:sequence>
        <xsd:attribute name="enabled" type="xsd:boolean" use="optional" default="true"/>
        <xsd:attribute name="id" type="actionIdString" use="optional"/>
        <xsd:attribute name="type" use="required">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="fixit" />
                <xsd:enumeration value="suggestion" />
                <xsd:enumeration value="suppression" />
                <xsd:enumeration value="help" />
                <xsd:enumeration value="doc" />
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
        <xsd:attribute name="btn" use="optional">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="none" />
                <xsd:enumeration value="fix" />
                <xsd:enumeration value="resolve" />
                <xsd:enumeration value="apply" />
                <xsd:enumeration value="open" />
                <xsd:enumeration value="suppress" />
                <xsd:enumeration value="disable" />
                <xsd:enumeration value="img" />
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
        <xsd:attribute name="retvalue" use="optional" default="true">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="false" />
                <xsd:enumeration value="no" />
                <xsd:enumeration value="true" />
                <xsd:enumeration value="yes" />
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
    </xsd:complexType>
    
    <xsd:complexType name="MsgActionIndirectType" mixed="false">
        <xsd:sequence>
            <xsd:element name="arg" type="actionMsgArgType" minOccurs="0" maxOccurs="unbounded"/>
        </xsd:sequence>
        <xsd:attribute name="enabled" type="xsd:boolean" use="optional" default="true"/>
        <xsd:attribute name="id" type="idString"/>
        <xsd:attribute name="ids" type="actionIdStringArray" use="optional"/>
   <!--     <xsd:attribute name="idx" type="numberArray" use="optional" default="1"/> -->
   <!--     <xsd:assert test="(@idx and not(@ids)) or (not(@idx) and @ids)"/>     -->      
    </xsd:complexType>

    <xsd:complexType name="actionsType">
        <xsd:sequence>
            <xsd:choice minOccurs="0" maxOccurs="unbounded">
                <xsd:element name="action" type="actionType" minOccurs="0" maxOccurs="1"/>
                <xsd:element name="action_catalog" type="MsgActionIndirectType" minOccurs="0" maxOccurs="1"/>
            </xsd:choice>
        </xsd:sequence>
        <xsd:attribute name="exclusiveFixIts" use="optional" default="yes">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="yes" />
                <xsd:enumeration value="no" />
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
        <xsd:attribute name="enabled" type="xsd:boolean" use="optional" default="true"/>
        <xsd:attribute name="order" use="optional">
          <xsd:simpleType>
           <xsd:restriction base="xsd:string">
                <xsd:enumeration value="block" />
             </xsd:restriction>
          </xsd:simpleType>
        </xsd:attribute>
    </xsd:complexType>
    <xsd:element name="actions" type="actionsType">
        <xsd:unique name="unique_id_constraint">
            <xsd:selector xpath="action"/>
            <xsd:field xpath="@id"/>
        </xsd:unique>
    </xsd:element>
</xsd:schema>
