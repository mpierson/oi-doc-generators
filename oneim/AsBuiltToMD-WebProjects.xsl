<?xml version='1.0' encoding="UTF-8"?>
<!--

  Transform One Identity web designer objects export to Markdown

  Author: M Pierson
  Date: May 2025
  Version: 0.90


 -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                              xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                              xmlns:ois="http://www.oneidentity.com/servers/XSL" 
                              exclude-result-prefixes="ois xs">
  <xsl:import href="OIS-IPv4Lib.xsl" />
  <xsl:import href="OIS-JSONLib.xsl" />
  <xsl:import href="OIS-StringLib.xsl" />
  <xsl:import href="OIS-Markdown.xsl" />
  <xsl:import href="OIS-PlantUML.xsl" />
      <xsl:output omit-xml-declaration="yes" indent="no" method="text" />

  <xsl:param name="additional-servers">
      <Servers/>
  </xsl:param>

  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="quote" select="'&quot;'" />

  <xsl:variable name="OI_GREEN"         select="'#afcc9e'" />
  <xsl:variable name="OI_BLACK"         select="'#162c36'" />
  <xsl:variable name="OI_BLUE"          select="'#04aada'" />
  <xsl:variable name="OI_GRAY"          select="'#40535d'" />
  <xsl:variable name="OI_BROWN"         select="'#c8b483'" />
  <xsl:variable name="OI_ORANGE"        select="'#f79431'" />
  <xsl:variable name="OI_RED"           select="'#f05640'" />
  <xsl:variable name="OI_PINK"          select="'#f4b3b2'" />
  <xsl:variable name="OI_LIGHT_BLUE"    select="'#9dcdda'" />

 <!-- IdentityTransform -->
 <xsl:template match="/ | @* | node()">
   <xsl:copy> <xsl:apply-templates select="@* | node()" /> </xsl:copy>
 </xsl:template>


   <!-- Function to format lines for a table cell -->
  <xsl:template name="format-table-lines">
    <xsl:param name="s" as="xs:string"/>
    <xsl:variable name="newline">\n</xsl:variable>
    <xsl:for-each select="tokenize($s, $newline)"><xsl:text>` </xsl:text><xsl:sequence select="."/><xsl:text> ` </xsl:text><br /></xsl:for-each>
  </xsl:template>

<xsl:template match="IdentityManager">

---
title: One Identity Manager Web Designer Configuration for <xsl:value-of select="@name" /> 
author: OneIM As Built Generator v0.90
abstract: |
    Configuration of WebDesigner objects for the <xsl:value-of select="@name" /> instance, generated <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')" />.
---




# Projects

<xsl:apply-templates select="WDProjects" />

# Modules

<xsl:apply-templates select="WDModules" />


<xsl:apply-templates select="WDComponents" />


# Layouts

<xsl:apply-templates select="WDLayouts" />


# Extensions

<xsl:apply-templates select="WDConfigs" />

</xsl:template>





<!-- ===== Projects ======================= -->

<xsl:template match="WDProjects">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of web projects.'" />
        <xsl:with-param name="id" select="'summary-web-designer-projects'" />
        <xsl:with-param name="header"   >| Name        | Startup Module | Session Module | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:-----|:-------------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="WDProject" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="WDProject" mode="section" />

</xsl:template>

<xsl:template match="WDProject" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="CustomCode/WebDesigner/Include/@StartupContextName"/></value>
        <value><xsl:value-of select="CustomCode/WebDesigner/Include/@SessionContextName"/></value>
        <value><xsl:value-of select="ois:last-modified-attr(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="WDProject" mode="section">

## <xsl:value-of select="@name" />

<xsl:apply-templates select="." mode="graphic" />

<xsl:value-of select="ois:markdown-definition('Comments', CustomCode/WebDesigner/Include/@Comments )" />

### Configuration

<xsl:apply-templates select="Configuration" mode="section" />


<xsl:if test="count(CustomCode/WebDesigner/Include/MenuStructure/MenuItem) &gt; 0">
### Menus

    <xsl:call-template name="ois:generate-plantuml-tree">
        <xsl:with-param name="summary">Menu Structure</xsl:with-param>
        <xsl:with-param name="id" select="concat('web-project-menus-', @name)" />
        <xsl:with-param name="header" select="@name" />
        <xsl:with-param name="values">                                                                                    
            <xsl:apply-templates select="CustomCode/WebDesigner/Include/MenuStructure" mode="tree" />
        </xsl:with-param>
    </xsl:call-template>



    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Details of menu structure.'" />
        <xsl:with-param name="id" select="concat('summary-web-designer-project-menus-', @name)" />
        <xsl:with-param name="header"   >| ID        | ContextID | Type | Title |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:----|:----|:-----------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="CustomCode/WebDesigner/Include/MenuStructure/*/MenuItem" mode="table" /> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="CustomCode/WebDesigner/Include/MenuStructure/*/MenuItem" mode="section" />

</xsl:if>

<xsl:if test="count(CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions/*) &gt; 0">
### Extensions
    <xsl:apply-templates select="CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions" mode="section" />
</xsl:if>


</xsl:template>

<xsl:template match="MenuStructure" mode="tree">
    <tree>
        <xsl:apply-templates select="MenuItem" mode="tree">
            <xsl:with-param name="parentID" select="@ScriptItemUID" />
            <xsl:with-param name="color" select="$OI_GREEN" />
        </xsl:apply-templates>
    </tree>
</xsl:template>
<xsl:template match="MenuItem" mode="tree">
    <xsl:param name="parentID" />
    <xsl:param name="color" />
    <branch>
        <xsl:attribute name="name" select="@ID" />
        <xsl:attribute name="path" select="concat($parentID, '\', @ID)" />
        <xsl:attribute name="color" select="$color" />

        <xsl:apply-templates select="MenuItem" mode="tree">
            <xsl:with-param name="parentID" select="concat($parentID, '\', @ID)" />
            <xsl:with-param name="color" select="$OI_BROWN" />
        </xsl:apply-templates>

    </branch>
</xsl:template>
<xsl:template match="MenuItem" mode="table">
    <row>
        <value><xsl:value-of select="@ID"/></value>
        <value><xsl:value-of select="@ContextID"/></value>
        <value><xsl:value-of select="@Type"/></value>
        <value><xsl:value-of select="concat('```', ois:truncate-string(ois:is-null-string(@Title, ''), 35, '...'), '```')"/></value>
    </row>
</xsl:template>

<xsl:template match="MenuItem" mode="section">

#### Menu: <xsl:value-of select="@ID" />

<xsl:value-of select="ois:markdown-definition-code('Title', @Title)" />
<xsl:value-of select="ois:markdown-definition-code('Tooltip', @Tooltip)" />
<xsl:choose>
    <xsl:when test="contains(@Condition, '&#xd;')">
        <xsl:call-template name="ois:generate-markdown-code-block">
            <xsl:with-param name="header">**Condition**</xsl:with-param>
            <xsl:with-param name="code" select="@Condition" />
            <xsl:with-param name="code-type">sql</xsl:with-param>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of select="ois:markdown-definition-code('Condition', @Condition)" />
    </xsl:otherwise>
</xsl:choose>
<xsl:value-of select="ois:markdown-definition('Module', @ContextID)" />


</xsl:template>

<xsl:template match="WDProject" mode="graphic">

```{.plantuml caption="Web Designer project overview"}

!include_many /home/mpierson/projects/quest/OneIM/posh-exporter/header.puml

top to bottom direction

Boundary(main, "Web Designer", $tags="OI_System") {

    Component(project, "<xsl:value-of select="@name"/>", "project", $tags="OneIM_WDProject")
    Component(startup, "<xsl:value-of select="CustomCode/WebDesigner/Include/@StartupContextName"/>", "startup module", $tags="OneIM_WDModule")
    Component(session, "<xsl:value-of select="CustomCode/WebDesigner/Include/@SessionContextName"/>", "session module", $tags="OneIM_WDModule")

    <xsl:if test="count(CustomCode/WebDesigner/Include/MenuStructure/MenuItem) &gt; 0">
        Component(menus, "Menus", "menus", $tags="OneIM_WDMenuStructure")
    </xsl:if>
    <xsl:apply-templates select="CustomCode/WebDesigner/Include/MenuStructure/MenuItem" mode="graphic-component">
        <xsl:with-param name="parent" select="'menus'"/>
    </xsl:apply-templates>
}

<!-- connections -->
Rel(project, startup, "uses", $tags="light")
Rel(project, session, "uses", $tags="light")
<xsl:if test="count(CustomCode/WebDesigner/Include/MenuStructure/MenuItem) &gt; 0">
    Rel(project, menus, "has", $tags="light")
</xsl:if>

<xsl:apply-templates select="CustomCode/WebDesigner/Include/MenuStructure/MenuItem" mode="graphic-connection">
    <xsl:with-param name="parent" select="'menus'"/>
</xsl:apply-templates>

```
![Web Designer project overview - <xsl:value-of select="@name"/>](single.png){#fig:overview-<xsl:value-of select="@name"/>}

</xsl:template>
<xsl:template match="MenuItem" mode="graphic-component">
    <xsl:param name="parent"/>
    Component(menu_<xsl:value-of select="@ID"/>, "<xsl:value-of select="@ID"/>", "menu", $tags="OneIM_WDMenu")
    <xsl:apply-templates select="MenuItem" mode="graphic-component">
        <xsl:with-param name="parent" select="concat('menu_',@ID)"/>
    </xsl:apply-templates>
    <xsl:if test="string-length(@ContextID) &gt; 0">
    Component(<xsl:value-of select="@ContextID"/>, "<xsl:value-of select="@ContextID"/>", "module", $tags="OneIM_WDModule")
    </xsl:if>
</xsl:template>
<xsl:template match="MenuItem" mode="graphic-connection">
    <xsl:param name="parent"/>
    Rel(<xsl:value-of select="$parent"/>,menu_<xsl:value-of select="@ID"/>, "", $tags="light") 
    <xsl:apply-templates select="MenuItem" mode="graphic-connection">
        <xsl:with-param name="parent" select="concat('menu_',@ID)"/>
    </xsl:apply-templates>
    <xsl:if test="string-length(@ContextID) &gt; 0">
        Rel(menu_<xsl:value-of select="@ID"/>, <xsl:value-of select="@ContextID"/>, "uses", $tags="light") 
    </xsl:if>
</xsl:template>


<xsl:template match="Configuration" mode="section">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="concat('Summary of configuration for ', ../@name, '.')" />
        <xsl:with-param name="id" select="concat('summary-web-designer-configuration', ../@id)" />
        <xsl:with-param name="header"   >| Key        | Value |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:-------------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="WebDesigner/ConfigurationRoot/WebProjectConfiguration/ConfigSection" mode="table"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="ConfigSection" mode="table">
    <xsl:apply-templates select="ConfigEntry" mode="table"/>
</xsl:template>
<xsl:template match="ConfigEntry" mode="table">
    <row>
        <value><xsl:value-of select="@Key"/></value>
        <value>
            <xsl:call-template name="ois:escape-for-markdown-table"><xsl:with-param name="s"><xsl:value-of select="@Value"/></xsl:with-param></xsl:call-template>
        </value>
    </row>
</xsl:template>




<!-- ===== Modules ======================= -->

<xsl:template match="WDModules">

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'Summary of custom or customized web designer modules.'" />
        <xsl:with-param name="id" select="'summary-web-designer-modules'" />
        <xsl:with-param name="header"   >| Name        | Description | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:-------------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="WDModule[ois:is-custom-object(.)]" mode="table"><xsl:sort select="@name" order="ascending"/></xsl:apply-templates> </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="WDModule[ois:is-custom-object(.)]" mode="section" ><xsl:sort select="@name" order="ascending"/></xsl:apply-templates>

</xsl:template>

<xsl:template match="WDModule" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="@description"/></value>
        <value><xsl:value-of select="ois:last-modified-attr(.)" /></value>
    </row>
</xsl:template>


<xsl:template match="WDModule" mode="section">

## <xsl:value-of select="@name" />

<xsl:apply-templates select="." mode="graphic" />

<xsl:value-of select="ois:markdown-definition('Description', @Description)" />

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Parameters accepted</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/Context/ContextConfiguration/ContextParameters/Parameter" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Forms in module</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/Context/Forms/Form" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Tables in module</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/Context/Tables/*" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Local controls in module</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/Context/Controls/Control" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Event handlers in module</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/Context/DataEventHandlers/DataEventHandler" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>


<xsl:if test="count(CustomCode/WebDesigner/Context/Functions/Function) &gt; 0">
### Functions
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Functions/Function" mode="section" />
</xsl:if>

<xsl:if test="count(Configuration/WebDesigner/ConfigurationRoot/WebProjectConfiguration/ConfigSection) &gt; 0">
### Configuration
    <xsl:apply-templates select="Configuration" mode="section" />
</xsl:if>

<xsl:if test="count(CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions/*) &gt; 0">
### Extensions
    <xsl:apply-templates select="CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions" mode="section" />
</xsl:if>


</xsl:template>


<xsl:template match="WDModule" mode="graphic">

```{.plantuml caption="Web Designer module overview"}

!include_many /home/mpierson/projects/quest/OneIM/posh-exporter/header.puml

top to bottom direction

Boundary(main, "Web Designer", $tags="OI_System") {

    <xsl:apply-templates select="CustomCode/WebDesigner/Context/ContextConfiguration/ContextParameters/Parameter" mode="graphic-component" />
    Component(base, "<xsl:value-of select="@name"/>", "module", $tags="OneIM_WDModule")
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Tables/*" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Forms/Form" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Functions/Function" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Controls/Control" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/DataEventHandlers/DataEventHandler" mode="graphic-component" />

}

<!-- connections -->
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/ContextConfiguration/ContextParameters/Parameter" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Tables/*" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Forms/Form" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Functions/Function" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/Controls/Control" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/Context/DataEventHandlers/DataEventHandler" mode="graphic-connection" />

```
![Module overview - <xsl:value-of select="@name"/>](single.png){#fig:overview-<xsl:value-of select="@name"/>}

</xsl:template>
<xsl:template match="Parameter" mode="graphic-component">
    Component(param_<xsl:value-of select="@Name"/>, "<xsl:value-of select="@Name"/>", "parameter", $tags="OneIM_WDModuleParameter")
</xsl:template>
<xsl:template match="Parameter" mode="graphic-connection">
    Rel_D(param_<xsl:value-of select="@Name"/>, base, "accepts", $tags="light") 
</xsl:template>

<xsl:template match="DataTableDbObject|DataTableSingleRow|DataTableSQL|DataTableView|DataTableFKView|DataTableCRView|DataTableGeneric|DataTableCustom|DataTableObjectView|VirtualTable" mode="graphic-component">
    <xsl:variable name="type-map">
        <map>
            <value key="">none</value>
            <value key="DataTableSingleRow">single row table</value>
            <value key="DataTableDbObject">DB table</value>
            <value key="DataTableSQL">SQL query</value>
            <value key="DataTableView">view</value>
            <value key="DataTableFKView">foreign key view</value>
            <value key="DataTableCRView">child table view</value>
            <value key="DataTableGeneric">collection</value>
            <value key="DataTableCustom">collection</value>
            <value key="DataTableObjectView">.Net collection</value>
            <value key="VirtualTable">virtual table</value>
        </map>
    </xsl:variable>
    <xsl:variable name="tag-map">
        <map>
            <value key="VirtualTable">OneIM_WDVirtualTable</value>
        </map>
    </xsl:variable>
    <xsl:variable name="table-type" select="name(.)" />
    <xsl:if test="(count(Column) + count(VirtualColumn)) &gt;0">
        SetPropertyHeader("Column", "Type")
        <xsl:apply-templates select="Column|VirtualColumn" mode="graphic-component"/>
    </xsl:if>
    <xsl:variable name="description" select="$type-map/map/value[@key=$table-type]" />
    <xsl:variable name="tag"         select="ois:is-null-string($tag-map/map/value[@key=$table-type],'OneIM_WDTable')" />
    Component(<xsl:value-of select="ois:get-vtype-id(.)"/>, "<xsl:value-of select="ois:is-null-string(@Table,@Name)"/>", "<xsl:value-of select="$description"/>", $tags="<xsl:value-of select="$tag"/>")
</xsl:template>
<xsl:template match="Column|VirtualColumn" mode="graphic-component">
    AddProperty("<xsl:value-of select="@Name"/>", "<xsl:value-of select="@DataType"/>")
</xsl:template>


<xsl:template match="DataTableDbObject|DataTableSingleRow|DataTableSQL|DataTableView|DataTableFKView|DataTableCRView|DataTableGeneric|DataTableCustom|DataTableObjectView" mode="graphic-connection">
    Rel(base,<xsl:value-of select="@ScriptItemUID"/>, "contains", $tags="light") 
</xsl:template>

<xsl:template match="Form" mode="graphic-component">
    Component(form_<xsl:value-of select="@ID"/>, "<xsl:value-of select="@ID"/>", "form", $tags="OneIM_WDForm")
</xsl:template>
<xsl:template match="Form" mode="graphic-connection">
    Rel(base,form_<xsl:value-of select="@ID"/>, "uses", $tags="light") 
</xsl:template>

<xsl:template match="Function" mode="graphic-component">
    Component(fn_<xsl:value-of select="@ScriptItemUID"/>, "<xsl:value-of select="ois:function-name(@Name)"/>", "function", $tags="OneIM_WDFunction")
</xsl:template>
<xsl:template match="Function" mode="graphic-connection">
    Rel(base,fn_<xsl:value-of select="@ScriptItemUID"/>, "calls", $tags="light") 
</xsl:template>

<xsl:template match="Control" mode="graphic-component">
    Component(ctl_<xsl:value-of select="ois:escape-markdown-id(@ID)"/>, "<xsl:value-of select="concat(LocalControlContext/@ContainerType, ': ', @ID)"/>", "control", $tags="OneIM_WDControl")
</xsl:template>
<xsl:template match="Control" mode="graphic-connection">
    Rel(base,ctl_<xsl:value-of select="ois:escape-markdown-id(@ID)"/>, "calls", $tags="light") 
</xsl:template>

<xsl:template match="DataEventHandler" mode="graphic-component">
    Component(deh_<xsl:value-of select="ois:escape-markdown-id(@ScriptItemUID)"/>, "<xsl:value-of select="concat(@DataTable, '-', @Operation)"/>", "event handler", $tags="OneIM_WDDataEventHandler")
    <xsl:apply-templates select="DataEventHandlerColumn" mode="graphic-component" />
</xsl:template>
<xsl:template match="DataEventHandlerColumn" mode="graphic-component">
    Component(dehc_<xsl:value-of select="ois:escape-markdown-id(@DataColumn)"/>, "<xsl:value-of select="@DataColumn"/>", "column", $tags="OneIM_WDDataEventColumn")
</xsl:template>
<xsl:template match="DataEventHandler" mode="graphic-connection">
    Rel(base,deh_<xsl:value-of select="ois:escape-markdown-id(@ScriptItemUID)"/>, "listen", $tags="light") 
    <xsl:apply-templates select="DataEventHandlerColumn" mode="graphic-connection">
        <xsl:with-param name="parent" select="ois:escape-markdown-id(@ScriptItemUID)" />
    </xsl:apply-templates>
</xsl:template>
<xsl:template match="DataEventHandlerColumn" mode="graphic-connection">
    <xsl:param name="parent" />
    Rel(<xsl:value-of select="concat('deh_', $parent)"/>,dehc_<xsl:value-of select="ois:escape-markdown-id(@DataColumn)"/>, "on", $tags="light") 
</xsl:template>


<xsl:template match="Parameter" mode="list">
    <xsl:variable name="param-modifiers">
        <items>
            <value key="Required"><xsl:value-of select="@IsMandatory" /></value>
        </items>
    </xsl:variable>
    <xsl:variable name="p-mod" select="ois:map-to-string($param-modifiers, ': ', ', ')"/>
    <value>
        <xsl:value-of select="concat(@Name, if (string-length($p-mod)&gt;0) then concat(' [', $p-mod, ']') else '' )" />
    </value>
</xsl:template>
<xsl:template match="DataTableDbObject|DataTableSingleRow|DataTableSQL|DataTableView|DataTableFKView|DataTableCRView|DataTableGeneric|DataTableCustom|DataTableObjectView" mode="list">
    <value>
        <xsl:variable name="table-name" select="@Table" />
        <xsl:variable name="table-modifiers">
            <items>
                <value key="Class"          ><xsl:value-of select="@Class" /></value>
                <value key="Foreign table"  ><xsl:value-of select="@ViewFKDataTable" /></value>
                <value key="Foreign key"    ><xsl:value-of select="@ViewFKDataColumn" /></value>
                <value key="Child key"      ><xsl:value-of select="@CRDataColumn" /></value>
                <value key="Primary key"    ><xsl:value-of select="@PrimaryKeyColumn" /></value>
                <value key="Display"        ><xsl:value-of select="@DisplayColumn" /></value>
                <value key="Type"           ><xsl:value-of select="@ElementType" /></value>
            </items>
        </xsl:variable>
        <xsl:variable name="table-modifier"><xsl:value-of select="ois:map-to-string($table-modifiers, ': ', ', ')" /></xsl:variable>
        <xsl:value-of select="concat(name(.), ': ', $table-name, if (string-length($table-modifier)&gt;0) then concat(' [', $table-modifier, ']') else '' )" />
        <xsl:apply-templates select="Column" mode="list"/>
    </value>
</xsl:template>
<xsl:template match="Control" mode="list">
    <value><xsl:value-of select="concat(LocalControlContext/@ContainerType, ': ', @ID)" /></value>
</xsl:template>
<xsl:template match="Form" mode="list">
    <xsl:variable name="form-modifiers">
        <items>
            <value key="Template"><xsl:value-of select="@PageFileName" /></value>
        </items>
    </xsl:variable>
    <xsl:variable name="form-mod" select="ois:map-to-string($form-modifiers, ': ', ', ')"/>
    <value>
        <xsl:value-of select="concat(@ID, if (string-length($form-mod)&gt;0) then concat(' [', $form-mod, ']') else '' )" />
    </value>
</xsl:template>
<xsl:template match="DataEventHandler" mode="list">
    <value>
        <xsl:value-of select="concat(@DataTable, ': ', ois:is-null-string(@Operation, '*'))" />
        <xsl:apply-templates select="DataEventHandlerColumn" mode="list" />
    </value>
</xsl:template>
<xsl:template match="DataEventHandlerColumn" mode="list">
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item(@DataColumn, 1))" />
</xsl:template>


<xsl:template match="Function" mode="section">
#### Function: <xsl:value-of select="ois:function-name(@Name)" />

    <xsl:value-of select="ois:markdown-definition('Signature', @Name)" />
    <xsl:value-of select="ois:markdown-definition('Data type', @DataType)" />

    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header">**Script content**</xsl:with-param>
        <xsl:with-param name="code" select="@Expression" />
        <xsl:with-param name="code-type">sql</xsl:with-param>
    </xsl:call-template>


</xsl:template>




<!-- ===== Components ======================= -->

<xsl:template match="WDComponents">

# Component Interfaces

    <xsl:call-template name="ois:generate-table">
        <xsl:with-param name="summary" select="'List of web designer component interfaces.'" />
        <xsl:with-param name="id" select="'summary-web-designer-component-interfaces'" />
        <xsl:with-param name="header"   >| Name        | Type | Last Modified |</xsl:with-param>
        <xsl:with-param name="separator">|:------------|:------------|:-------------------|</xsl:with-param>
        <xsl:with-param name="values">
            <rows> <xsl:apply-templates select="WDComponent[@subType='ComponentInterfaceObject']" mode="table"><xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/></xsl:apply-templates>
            </rows>
        </xsl:with-param>
    </xsl:call-template>

    <xsl:apply-templates select="WDComponent[@subType='ComponentInterfaceObject']" mode="section">
        <xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/>
    </xsl:apply-templates>


# Components

    <xsl:for-each-group select="WDComponent[ois:is-custom-object(.) and @subType!='ComponentInterfaceObject']" group-by="@subType">

        <xsl:value-of select="concat('&#xa;## ', current-grouping-key(), ' Components&#xa;')" />

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="concat('Summary of web designer ', current-grouping-key(), ' components.')" />
            <xsl:with-param name="id" select="concat('summary-web-designer-components-', current-grouping-key())" />
            <xsl:with-param name="header"   >| Name        | Interface | Last Modified |</xsl:with-param>
            <xsl:with-param name="separator">|:------------|:-------------|:-------------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> <xsl:apply-templates select="current-group()" mode="table"><xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/></xsl:apply-templates>
                </rows>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:apply-templates select="current-group()" mode="section">
            <xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/>
        </xsl:apply-templates>
    </xsl:for-each-group>

</xsl:template>

<xsl:template match="WDComponent" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <xsl:choose>
            <xsl:when test="@subType = 'ComponentInterfaceObject'">
                <value><xsl:value-of select="CustomCode/WebDesigner/GlobalControl/Context/ComponentInterfaceObject/@ContainerType"/></value>
            </xsl:when>
            <xsl:otherwise>
                <value><xsl:value-of select="CustomCode/WebDesigner/GlobalControl/ComponentInterface/@InterfaceName"/></value>
            </xsl:otherwise>
        </xsl:choose>
        <value><xsl:value-of select="ois:last-modified-attr(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="WDComponent" mode="section">

### <xsl:value-of select="@name" />

<xsl:apply-templates select="." mode="graphic" />

<xsl:choose>
    <xsl:when test="@subType = 'ComponentInterfaceObject'">
        <xsl:value-of select="ois:markdown-definition('Type', CustomCode/WebDesigner/GlobalControl/Context/ComponentInterfaceObject/@ContainerType)" />
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of select="ois:markdown-definition('Type', @subType)" />
    </xsl:otherwise>
</xsl:choose>
<xsl:value-of select="ois:markdown-definition('Description', @Description)" />
<xsl:value-of select="ois:markdown-definition('Interface', CustomCode/WebDesigner/GlobalControl/ComponentInterface/@InterfaceName)"/>
<xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/ComponentInterface" mode="section" />

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Local tables</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Tables/*" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Local controls</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Controls/Control" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="ois:generate-markdown-list">
    <xsl:with-param name="header">Local event handlers</xsl:with-param>
    <xsl:with-param name="values">
        <items> <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/DataEventHandlers/DataEventHandler" mode="list" /> </items>
    </xsl:with-param>
</xsl:call-template>


<xsl:if test="count(CustomCode/WebDesigner/GlobalControl/Context/Functions/Function) &gt; 0">
### Functions
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Functions/Function" mode="section" />
</xsl:if>

<xsl:if test="count(CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions/*) &gt; 0">
### Extensions
    <xsl:apply-templates select="CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions" mode="section" />
</xsl:if>


</xsl:template>

<xsl:template match="ComponentInterface" mode="section">

    <!-- for interfaces, list virtual elements -->
    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header">Interface</xsl:with-param>
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="VirtualTable|VirtualControl|VirtualFunction" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

    <!-- for components, list extensions -->
    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header">Extensions</xsl:with-param>
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="VirtualTableExtension" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>

</xsl:template>
<xsl:template match="VirtualTable" mode="list">
    <value>
        <xsl:value-of select="concat(ois:get-vtype-descr(.), ': ', ois:get-vtype-name(.))" />
        <xsl:apply-templates select="VirtualColumn" mode="list"/>
    </value>
</xsl:template>
<xsl:template match="VirtualControl" mode="list">
    <value>
        <xsl:value-of select="concat(ois:get-vtype-descr(.), ': ', ois:get-vtype-name(.))" />
    </value>
</xsl:template>
<xsl:template match="VirtualFunction" mode="list">
    <xsl:variable name="fn-modifiers">
        <items>
            <value key="Type"><xsl:value-of select="@DataType" /></value>
            <value key="Description"><xsl:value-of select="@Comment" /></value>
        </items>
    </xsl:variable>
    <xsl:variable name="fn-mod" select="ois:map-to-string($fn-modifiers, ': ', ', ')"/>
    <value>
        <xsl:value-of select="concat(ois:get-vtype-descr(.), ': ', @Signature, if (string-length($fn-mod)&gt;0) then concat(' [', $fn-mod, ']') else '' )" />
    </value>
</xsl:template>
<xsl:template match="VirtualTableExtension" mode="list">
    <value>
        <xsl:value-of select="concat('Table: ', @Name)" />
        <xsl:if test="string-length(@Class) &gt; 0">
            <xsl:value-of select="concat(' [Class=', @Class, ']')" />
        </xsl:if>
        <xsl:apply-templates select="VirtualColumnExtension" mode="list"/>
    </value>
</xsl:template>
<xsl:template match="Column|VirtualColumn|VirtualColumnExtension" mode="list">
    <xsl:variable name="list-text" select="concat('Column: _', @Name, '_ [', @DataType, ']')" />
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>



<xsl:template match="WDComponent" mode="graphic">

```{.plantuml caption="Web Designer component overview"}

!include_many /home/mpierson/projects/quest/OneIM/posh-exporter/header.puml

top to bottom direction

Boundary(main, "Web Designer", $tags="OI_System") {

    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/ComponentInterface" mode="graphic-component"/>

    Component(base, "<xsl:value-of select="@name"/>", "<xsl:value-of select="ois:get-component-type(@subType)"/>", $tags="OneIM_WDComponent")

    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Tables/*" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Functions/Function" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Controls/Control" mode="graphic-component" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/DataEventHandlers/DataEventHandler" mode="graphic-component" />

}

<!-- connections -->
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/ComponentInterface" mode="graphic-connection"/>
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Tables/*" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Functions/Function" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/Controls/Control" mode="graphic-connection" />
    <xsl:apply-templates select="CustomCode/WebDesigner/GlobalControl/Context/DataEventHandlers/DataEventHandler" mode="graphic-connection" />

```
![Component overview - <xsl:value-of select="@name"/>](single.png){#fig:overview-<xsl:value-of select="@name"/>}

</xsl:template>

<xsl:template match="ComponentInterface" mode="graphic-component">
    <xsl:if test="string-length(@InterfaceName) &gt; 0">
        Component(interface, "<xsl:value-of select="@InterfaceName"/>", "interface", $tags="OneIM_WDComponentInterface")
    </xsl:if>
    <xsl:apply-templates select="VirtualTableExtension" mode="graphic-component" />
    <xsl:apply-templates select="VirtualTable|VirtualControl|VirtualFunction" mode="graphic-component" />
</xsl:template>
<xsl:template match="VirtualControl|VirtualFunction|VirtualTableExtension" mode="graphic-component">
    Component(<xsl:value-of select="ois:get-vtype-id(.)"/>, "<xsl:value-of select="ois:get-vtype-name(.)"/>", "<xsl:value-of select="ois:get-vtype-descr(.)"/>", $tags="<xsl:value-of select="concat('OneIM_WD', name(.))"/>")
</xsl:template>

<xsl:template match="ComponentInterface" mode="graphic-connection">
    <xsl:apply-templates select="VirtualTableExtension" mode="graphic-connection" />
    <xsl:if test="string-length(@InterfaceName) &gt; 0">
        Rel_D(interface, base, "inherits", $tags="light") 
    </xsl:if>
    <xsl:apply-templates select="VirtualTable|VirtualControl|VirtualFunction" mode="graphic-connection" />
</xsl:template>
<xsl:template match="VirtualTable|VirtualControl|VirtualFunction" mode="graphic-connection">
    Rel_U(base, <xsl:value-of select="ois:get-vtype-id(.)"/>, "requires", $tags="light") 
</xsl:template>
<xsl:template match="VirtualTableExtension" mode="graphic-connection">
    Rel_U(<xsl:value-of select="ois:get-vtype-id(.)"/>, interface, "extends", $tags="light") 
</xsl:template>


  <!-- Function returns type of component -->
  <xsl:function name="ois:get-component-type" as="xs:string">
    <xsl:param name="subType" as="xs:string"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$subType = 'ComponentInterfaceObject'">component interface</xsl:when>
            <xsl:otherwise><xsl:value-of select="concat('component: ', $subType)" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>

  <!-- Function returns appropriate ID of interface item  -->
  <xsl:function name="ois:get-vtype-id" as="xs:string">
    <xsl:param name="node"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="name($node) = 'VirtualFunction'"><xsl:value-of select="ois:function-name($node/@Signature)" /></xsl:when>
            <xsl:when test="name($node) = 'VirtualControl'"><xsl:value-of select="$node/@ID" /></xsl:when>
            <xsl:when test="name($node) = 'VirtualTable'"><xsl:value-of select="$node/@Name" /></xsl:when>
            <xsl:when test="name($node) = 'VirtualTableExtension'"><xsl:value-of select="$node/@Name" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$node/@ScriptItemUID" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>

  <!-- Function returns appropriate name of interface item  -->
  <xsl:function name="ois:get-vtype-name" as="xs:string">
    <xsl:param name="node"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="name($node) = 'VirtualFunction'"><xsl:value-of select="ois:function-name($node/@Signature)" /></xsl:when>
            <xsl:when test="name($node) = 'VirtualControl'"><xsl:value-of select="$node/@ID" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="$node/@Name" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>

  <!-- Function returns appropriate description of interface item  -->
  <xsl:function name="ois:get-vtype-descr" as="xs:string">
    <xsl:param name="node"/>

    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="name($node) = 'VirtualControl'"><xsl:value-of select="concat(name($node), '-', $node/@ContainerType)" /></xsl:when>
            <xsl:otherwise><xsl:value-of select="name($node)" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function>




<!-- ===== Layouts ======================= -->

<xsl:template match="WDLayouts">

    <xsl:for-each-group select="WDLayout[ois:is-custom-object(.)]" group-by="@subType">

        <xsl:value-of select="concat('&#xa;## ', current-grouping-key(), ' Layouts&#xa;')" />

        <xsl:call-template name="ois:generate-table">
            <xsl:with-param name="summary" select="concat('List of web designer ', current-grouping-key(), ' layouts.')" />
            <xsl:with-param name="id" select="concat('summary-web-designer-layouts-', current-grouping-key())" />
            <xsl:with-param name="header"   >| Name        | Last Modified |</xsl:with-param>
            <xsl:with-param name="separator">|:------------|:-------------------|</xsl:with-param>
            <xsl:with-param name="values">
                <rows> <xsl:apply-templates select="current-group()" mode="table"><xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/></xsl:apply-templates>
                </rows>
            </xsl:with-param>
        </xsl:call-template>

        <xsl:apply-templates select="current-group()" mode="section">
            <xsl:sort select="@subType" order="ascending"/><xsl:sort select="@name" order="ascending"/>
        </xsl:apply-templates>
    </xsl:for-each-group>

</xsl:template>

<xsl:template match="WDLayout" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ois:last-modified-attr(.)" /></value>
    </row>
</xsl:template>

<xsl:template match="WDLayout" mode="section">

    <xsl:value-of select="concat('&#xa;### ', @name, '&#xa;')" />
    <xsl:apply-templates select="CustomCode/WebDesigner/LayoutObject" mode="section" />

    <xsl:if test="count(CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions/*) &gt; 0">
### Extensions
        <xsl:apply-templates select="CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions" mode="section" />
    </xsl:if>

</xsl:template>
<xsl:template match="LayoutObject" mode="section">
    <xsl:variable name="class"><xsl:value-of select="Property[@Name='CssClassName']/@Value" /></xsl:variable>
    <xsl:value-of select="ois:markdown-definition('Class name', $class)" />
    <xsl:apply-templates select="CssDocument" mode="section" />
</xsl:template>
<xsl:template match="CssDocument" mode="section sub-list">
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header" select="concat('**Stylesheet**: ', @CssName)"/>
        <xsl:with-param name="code"><xsl:value-of select="." /></xsl:with-param>
        <xsl:with-param name="code-type">css</xsl:with-param>
    </xsl:call-template>
</xsl:template>



<!-- ===== Configs ======================= -->

<xsl:template match="WDConfigs">

    <xsl:for-each-group select="WDConfig" group-by="Parent/@type">
        <xsl:if test="string-length(current-grouping-key()) &gt; 0">

            <xsl:value-of select="concat('&#xa;## ', ois:extension-parent-type(current-grouping-key()), ' Extensions&#xa;')" />

            <xsl:call-template name="ois:generate-table">
                <xsl:with-param name="summary" select="concat('Summary of ', ois:extension-parent-type(current-grouping-key()), ' extensions.')" />
                <xsl:with-param name="id" select="concat('summary-web-designer-extensions-', current-grouping-key())" />
                <xsl:with-param name="header"   >| Name        | Type | Extends | Last Modified |</xsl:with-param>
                <xsl:with-param name="separator">|:------------|:-----|:------------|:-------------------|</xsl:with-param>
                <xsl:with-param name="values">
                    <rows> <xsl:apply-templates select="current-group()" mode="table"><xsl:sort select="Parent/@type" order="ascending"/><xsl:sort select="Parent/@name" order="ascending"/><xsl:sort select="@name" order="ascending"/></xsl:apply-templates>
                    </rows>
                </xsl:with-param>
            </xsl:call-template>

            <xsl:apply-templates select="current-group()" mode="section"/>

        </xsl:if>
    </xsl:for-each-group>

</xsl:template>

<xsl:template match="WDConfig" mode="table">
    <row>
        <value><xsl:value-of select="@name"/></value>
        <value><xsl:value-of select="ois:extension-parent-type-plus(Parent/@type, Parent/@subType)"/></value>
        <value><xsl:value-of select="Parent/@name"/></value>
        <value><xsl:value-of select="ois:last-modified-attr(.)" /></value>
    </row>
</xsl:template>
<xsl:function name="ois:extension-parent-type" as="xs:string">
    <xsl:param name="type" as="xs:string?"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$type='AP'">Project</xsl:when>
            <xsl:when test="$type='CO'">Module</xsl:when>
            <xsl:when test="$type='LY'">Layout</xsl:when>
            <xsl:when test="$type='CC'">Component</xsl:when>
            <xsl:when test="$type='CF'">Extension</xsl:when>
            <xsl:when test="$type='PR'">API Project</xsl:when>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function> 
<xsl:function name="ois:extension-parent-type-plus" as="xs:string">
    <xsl:param name="type" as="xs:string?"/>
    <xsl:param name="subType" as="xs:string?"/>
    <xsl:variable name="result">
        <xsl:choose>
            <xsl:when test="$type='CC'"><xsl:value-of select="$subType"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="ois:extension-parent-type($type)" /></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$result" />
</xsl:function> 

<xsl:template match="WDConfig" mode="section">
    <xsl:value-of select="concat('&#xa;### ', @name, '&#xa;')" />
    <xsl:apply-templates select="Parent" mode="section" />
    <xsl:apply-templates select="CustomCode/WebDesigner/ConfigurationRoot/Extensions" mode="section" />
</xsl:template>
<xsl:template match="Parent" mode="section">
    <xsl:value-of select="ois:markdown-definition('Parent', concat(@name, ' [', ois:extension-parent-type-plus(@type, @subType), ']' ))" />
</xsl:template>
<xsl:template match="Extensions" mode="section">
    <xsl:call-template name="ois:generate-markdown-list">
        <xsl:with-param name="header">Extensions</xsl:with-param>
        <xsl:with-param name="values">
            <items> <xsl:apply-templates select="AddObject[*]|RemoveObject|ModifyProperty" mode="list" /> </items>
        </xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="RemoveObject" mode="list">
    <value> <xsl:value-of select="concat('Remove object: _', @ObjectID, '_')"/> </value>
</xsl:template>
<xsl:template match="ModifyProperty" mode="list">
    <value> 
        <xsl:value-of select="concat(concat('Modify property _', @ObjectID, ':', @PropertyName, '_'), 
                                     ois:is-empty-string(@Value,'',concat(', value = ', ois:markdown-inline-code(@Value, 40)) )
                                    )" />
    </value>
</xsl:template>

<xsl:template match="AddObject" mode="list">
    <xsl:variable name="ex-modifiers">
        <items>
            <value key="Base object"><xsl:value-of select="@ObjectID" /></value>
            <value key="Sort order"><xsl:value-of select="@SortOrder" /></value>
            <xsl:if test="@ExtensionPosition='After'">
                <value key="Insert after"><xsl:value-of select="@ReferenceObjectID"/></value>
            </xsl:if>
        </items>
    </xsl:variable>
    <xsl:variable name="ex-mod" select="ois:map-to-string($ex-modifiers, ': ', ', ')"/>
    <value> 
        <xsl:value-of select="concat('Add object: ', @ObjectType, if (string-length($ex-mod)&gt;0) then concat(' [', $ex-mod,']') else '')" /> 
        <xsl:apply-templates select="*" mode="sub-list" />
    </value>
</xsl:template>
<xsl:template match="ConfigParam" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Parameter _', @Key, '_'), 
                                     ois:is-empty-string(@Type,': ', concat(' [', @Type, ']: ')), 
                                     ois:is-empty-string(@Description,'', concat('`', ois:truncate-string(@Description, 50, '...'), '`')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ConfigEntry" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Config entry: _', @Key, '_'), 
                                     ois:is-empty-string(@Type,' = ', concat(' [', @Type, '] = ')), 
                                     ois:is-empty-string(@Value,'[empty]',concat('`', ois:truncate-string(@Value, 50, '...'), '`')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ConfigEntryObject" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Config entry object: ', 
                                     ois:is-empty-string(.,'',concat('`', ois:truncate-string(., 80, '...'), '`')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="Container" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Container: _', ois:is-null-string(@ItemUID,@ScriptItemUID), '_'), 
                                     ois:is-empty-string(@Condition,'',concat(', condition= `', ois:truncate-string(@Condition, 80, '...'), '`')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="SwitchContainer" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Switch _', @ScriptItemUID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="CodeLiteral|TypeMember" mode="sub-list">
    <xsl:call-template name="ois:generate-markdown-code-block">
        <xsl:with-param name="header">Code literal:</xsl:with-param>
        <xsl:with-param name="code" select="." />
        <xsl:with-param name="code-type">cs</xsl:with-param>
    </xsl:call-template>
</xsl:template>
<xsl:template match="DataTableDbObject|DataTableSingleRow|DataTableFKView|DataTableCRView" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Table: _', @Table, '_'), 
                                     ois:is-empty-string(@Class,'',concat(' [',@Class, ']')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
    <xsl:apply-templates select="Column" mode="sub-list" />
</xsl:template>
<xsl:template match="Column|VirtualColumn|VirtualColumnExtension" mode="sub-list">
    <xsl:variable name="list-text" select="concat('Column: _', @Name, '_ [', @DataType, ']')" />
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 2))" />
</xsl:template>
<xsl:template match="SingleColumn" mode="sub-list">
    <xsl:variable name="list-text" select="concat('Column: _', @DataColumn, '_')"/>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="Control" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Control: _', @ID, '_'), 
                                     ois:is-empty-string(LocalControlContext/@ContainerType,'',
                                                concat(' [',LocalControlContext/@ContainerType, ']')) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ControlReferenceControlList" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Control reference to _', @ID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ControlReferenceContainer" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Container reference to _', @ID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ControlReferenceGridColumnGroup" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Grid column group reference to _', @ID, '_'), 
                                     ois:is-empty-string(@DataTable,'',concat(', table=', @DataTable)) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ControlReferenceElementGroup" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Element group reference to _', @ID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="FillTable" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Fill table _', @DataTable, '_'), 
                                     ois:is-empty-string(@DataColumn,'',concat(', column=_', @DataColumn, '_')),
                                     ois:is-empty-string(@Expression,'',concat(', expression= ', ois:markdown-inline-code(@Expression, 40)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="LoadTable" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Load table _', @DataTable, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ActionSequence" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Action sequence _', ois:is-null-string(@ItemUID, @ScriptItemUID), '_'), 
                                     ois:is-empty-string(@Condition,'',concat(', condition= ', ois:markdown-inline-code(@Condition, 80) )) 
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="Insert" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Insert row in table _', @DataTable, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
    <xsl:apply-templates select="InsertValue" mode="sub-list" />
</xsl:template>
<xsl:template match="InsertValue" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('_', @DataColumn, '_'), 
                                     ois:is-empty-string(@Value,'',concat(' = ', ois:markdown-inline-code(@Value, 80)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 2))" />
</xsl:template>
<xsl:template match="Update" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Update table _', concat(@DataTable, '.', @DataColumn), '_',
                                     ois:is-empty-string(@Value,'',concat(' = ', ois:markdown-inline-code(@Value, 80)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="Delete" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Delete from table _', @DataTable, '_')"/>
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="ColumnMemberRelation" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('_', @Name, '_ -> ', @RelationTableName, '.', @ColumnNameLeft)"/>
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="Function" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="ois:markdown-inline-code(@Name, 80)" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="FunctionValue" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="ois:markdown-inline-code(@Expression, 80)" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>
<xsl:template match="VirtualFunctionMapping" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Virtual function ', ois:markdown-inline-code(@ID, 40)), 
                                     ois:is-empty-string(@Value,'',concat(', value = ', ois:markdown-inline-code(@Value, 40)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>


<xsl:template match="AssemblyReference" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Assembly reference: _', ois:truncate-string(@Assembly, 80, '...'), '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="TabPage" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Tab: _', ois:is-null-string(@ItemUID,@ScriptItemUID), '_'), 
                                     ois:is-empty-string(@Condition,'',concat(', condition= ', ois:markdown-inline-code(@Condition, 80)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="MenuItem" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Menu _', ois:is-null-string(@ContextID,@ScriptItemUID), '_'), 
                                     ois:is-empty-string(@Title,'',concat(', title = ', ois:markdown-inline-code(@Title, 40)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="MenuElement" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Menu element :', ois:markdown-inline-code(@Text, 80) )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="ColumnLimitedValue" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Value: _', @Name, '_'), 
                                     ois:is-empty-string(@Comment,concat(' ', ois:markdown-inline-code(@Display, 40)), @Comment )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="Parameter" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Parameter _', @Name, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="ObjectInclude" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Include _', @ObjectIncludeID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="SubProject" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Sub project _', @ID, '_')" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="Label" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat('Label: ', ois:markdown-inline-code(@Text, 80))" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>

<xsl:template match="Button" mode="sub-list">
    <xsl:variable name="list-text">
        <xsl:value-of select="concat(concat('Button _', ois:is-null-string(@ContextID,@ScriptItemUID), '_'), 
                                     ois:is-empty-string(@Layout,'',concat(', layout = _', @Layout, '_')),
                                     ois:is-empty-string(@Text,'',concat(', text = ', ois:markdown-inline-code(@Text, 40)) )
                                    )" />
    </xsl:variable>
    <xsl:value-of select="concat('&#xa;', ois:markdown-list-item($list-text, 1))" />
</xsl:template>




<!-- ===== generic functions ======================= -->

<xsl:function name="ois:is-custom-object" as="xs:boolean">
    <xsl:param name="node" />
    <xsl:sequence select="starts-with($node/@name, 'CCC') or starts-with($node/@name, 'HHS') or count($node/CustomConfiguration/WebDesigner/ConfigurationRoot/Extensions/*) &gt; 0" />
</xsl:function> 

 <!-- extract function name, sans params -->
  <xsl:function name="ois:function-name" as="xs:string">
    <xsl:param name="f" as="xs:string"/>
    <xsl:variable name="result">
        <xsl:value-of select="substring-before($f, '(')" />
    </xsl:variable>
    <xsl:value-of select="$result" />
  </xsl:function> 


  <!-- Function to extract last modified string -->
  <xsl:function name="ois:last-modified" as="xs:string">
    <xsl:param name="o"/>

    <xsl:variable name="result">
        <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/Property[@Name='XUserUpdated']), 15, '...')" /> - <xsl:value-of select="$o/Property[@Name='XDateUpdated']" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function> 
  <xsl:function name="ois:last-modified-attr" as="xs:string">
    <xsl:param name="o"/>

    <xsl:variable name="result">
        <xsl:value-of select="ois:truncate-string(ois:escape-for-markdown($o/@XUserUpdated), 15, '...')" /> - <xsl:value-of select="$o/@XDateUpdated" />
    </xsl:variable>
    <xsl:value-of select="$result" />

  </xsl:function> 


  <xsl:function name="ois:get-origin-description" as="xs:string">
      <xsl:param name="origin" as="xs:integer"/>
      <xsl:variable name="result">
          <xsl:call-template name="ois:select-by-index">
              <xsl:with-param name="i" select="$origin" />
              <xsl:with-param name="values">
                      <v>direct</v>
                      <v>inherited</v>
                      <v>direct + inherited</v>
                      <v>dynamic</v>
              </xsl:with-param>
          </xsl:call-template>
      </xsl:variable>
      <xsl:value-of select="$result" />
  </xsl:function>


  <!-- de-reference pointer -->
  <xsl:template name="get-object-name">
      <xsl:param name="id" />
      <xsl:value-of select="//IdentityManager/TargetSystems/TargetSystem[@id = $id]/@name"/>
      <xsl:value-of select="//IdentityManager/SyncProjects/SyncProject[@id = $id]/@name"/>
  </xsl:template>

</xsl:stylesheet>
