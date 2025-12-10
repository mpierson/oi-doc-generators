<?xml version='1.0' encoding="UTF-8"?>
<!--

  Project related templates.

  Author: M Pierson
  Date: Dec 2025
  Version: 0.90

  Ref: https://c4model.com/diagrams/deployment

 -->
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL"
                              exclude-result-prefixes="ois xs">
  <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

    <xsl:template match="deploy_def">
        <xsl:call-template name="ois:generate-plantuml-C4">
            <xsl:with-param name="summary" select="concat('Deploy diagram of _', ../@name, '_ environment')" />
            <xsl:with-param name="id" select="concat('environment-deploy-', ois:escape-markdown-id(../@name))" />
            <xsl:with-param name="content">
                <xsl:apply-templates select="area" mode="components" />
                <xsl:apply-templates select="area" mode="relations" />
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="area" mode="components">
        <xsl:variable name="content">
            <xsl:apply-templates select="area" mode="components" />
            <xsl:apply-templates select="infra|dnode" mode="components" />
        </xsl:variable>
        <xsl:value-of select="ois:c4-boundary(
                ois:get-component-id(.), @name, 'OI_DeployArea',  $content
            )" />
    </xsl:template>
    <xsl:template match="infra" mode="components">
        <xsl:value-of select="ois:c4-node(
                ois:get-component-id(.), @name, @description, ois:get-tag(.), ''
            )" />
    </xsl:template>
    <xsl:template match="dnode" mode="components">
        <xsl:variable name="content">
            <xsl:apply-templates select="dnode|infra|container" mode="components" />
        </xsl:variable>
        <xsl:value-of select="ois:c4-node(
                ois:get-component-id(.), @name, @description, ois:get-tag(.), $content
            )" />
    </xsl:template>
    <xsl:template match="container" mode="components">
        <xsl:value-of select="ois:c4-container(
                ois:get-component-id(.), @name, @type, @description, ois:get-tag(.)
            )" />
    </xsl:template>



    <xsl:template match="area" mode="relations">
        <xsl:apply-templates select="uses" />
        <xsl:apply-templates select="area|infra|dnode" mode="relations" />
    </xsl:template>
    <xsl:template match="infra" mode="relations">
        <xsl:apply-templates select="uses" />
    </xsl:template>
    <xsl:template match="dnode" mode="relations">
        <xsl:apply-templates select="uses" />
        <xsl:apply-templates select="dnode|infra|container" mode="relations" />
    </xsl:template>
    <xsl:template match="container" mode="relations">
        <xsl:apply-templates select="uses" />
    </xsl:template>


    <xsl:template match="uses">
        <xsl:variable name="id-left" select="ois:get-component-id(..)" />

        <xsl:variable name="target-name" select="@name" />
        <xsl:variable name="target-type" select="@type" />
        <xsl:variable name="target" select="ancestor::deploy_def/descendant::container[name()=$target-type and @name=$target-name]" />
        <xsl:variable name="id-right" select="ois:get-component-id($target)" />

        <xsl:if test="$target">
            <xsl:value-of select="ois:c4-rel($id-left, $id-right, @description, 'tag here')" />
        </xsl:if>
    </xsl:template>


    <!-- ===================================== -->

    <xsl:function name="ois:get-component-id" as="xs:string">
        <xsl:param name="o" />
        <xsl:variable name="type" select="local-name($o)" />
        <!-- recursive call for parent's ID -->
        <xsl:variable name="parent-id" select="
                if ( $o/.. and (local-name($o/..) ne 'deploy_def') ) then ois:get-component-id($o/..)
                else ''
        " />
        <xsl:value-of select="
                if ( string-length($parent-id) gt 0 ) 
                then ois:clean-for-plantuml-name(concat($parent-id, '_', $type, '_', $o/@name))
                else ois:clean-for-plantuml-name(concat($type, '_', $o/@name))
        " />
    </xsl:function>

    <xsl:function name="ois:get-tag" as="xs:string">
        <xsl:param name="o" />
        <xsl:variable name="node-name" as="xs:string" select="$o/local-name()" />
        <xsl:variable name="type" as="xs:string?" select="$o/@type" />

        <xsl:value-of select="
                if ( string-length($o/@tag) gt 0 ) then $o/@tag
                else if ( $node-name eq 'dnode' ) then       'Deploy_Area'
                else if ( $type eq 'load balancer' ) then    'Deploy_Infrastructure'
                else if ( $type eq 'OneIM database' ) then   'OneIM_Deploy_DB'
                else if ( $type eq 'OneIM job server' ) then 'OneIM_Deploy_JS'
                else if ( $type eq 'OneIM web server' ) then 'OneIM_Deploy_WS'
                else if ( $type eq 'OneIM app server' ) then 'OneIM_Deploy_AS'
                else if ( $type eq 'OneIM tools' ) then      'OneIM_Deploy_Tools'
                else if ( $type eq 'SPP' ) then              'SG_Deploy_SPP'
                else if ( $type eq 'SPS' ) then              'SG_Deploy_SPS'
                else if ( $type eq 'starling connect instance' ) then'StarlingConnect_Connector'
                else if ( $type eq 'API' ) then              'Deploy_API'
                else ''
        " />
    </xsl:function>
</xsl:stylesheet>
