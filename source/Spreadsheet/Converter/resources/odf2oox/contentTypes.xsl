<?xml version="1.0" encoding="UTF-8"?>
<!--
  * Copyright (c) 2006, Clever Age
  * All rights reserved.
  * 
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  *     * Redistributions of source code must retain the above copyright
  *       notice, this list of conditions and the following disclaimer.
  *     * Redistributions in binary form must reproduce the above copyright
  *       notice, this list of conditions and the following disclaimer in the
  *       documentation and/or other materials provided with the distribution.
  *     * Neither the name of Clever Age nor the names of its contributors 
  *       may be used to endorse or promote products derived from this software
  *       without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
  * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
  * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  exclude-result-prefixes="#default w r office style table">

  <!-- content types -->
  <xsl:template name="ContentTypes">
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <xsl:call-template name="InsertConnectionContentTypes"/>
      <Override PartName="/xl/theme/theme1.xml"
        ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
      <Default Extension="jpeg" ContentType="image/jpeg"/>
      <Default Extension="jpg" ContentType="image/jpeg"/>
      <Default Extension="gif" ContentType="image/gif"/>
      <Default Extension="png" ContentType="image/png"/>
      <Default Extension="wmf" ContentType="image/x-emf"/>
      <Default Extension="emf" ContentType="image/x-emf"/>
      <Default Extension="tif" ContentType="image/tiff"/>
      <Default Extension="tiff" ContentType="image/tiff"/>
      <Default Extension="bin" ContentType="application/vnd.openxmlformats-officedocument.oleObject"/>
      <Default Extension="rels"
        ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/>
      <Override PartName="/xl/workbook.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/sharedStrings.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
      <Override PartName="/docProps/core.xml"
        ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
      <Override PartName="/docProps/app.xml"
        ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
      <Override PartName="/docProps/custom.xml"
        ContentType="application/vnd.openxmlformats-officedocument.custom-properties+xml"/>
      <Override PartName="/xl/styles.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
      <Default Extension="vml"
        ContentType="application/vnd.openxmlformats-officedocument.vmlDrawing"/>
      <Override PartName="/xl/connections.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml"/>
      <xsl:call-template name="InsertCommentContentTypes"/>
      <xsl:call-template name="InsertDrawingContentTypes"/>
      <xsl:call-template name="InsertSheetContentTypes"/>
      <xsl:call-template name="InsertExternalLinkTypes"/>
      <xsl:call-template name="InsertChangeTrackingTypes"/>

    </Types>
  </xsl:template>
  <!-- OLE object types -->
  <xsl:template name="InsertExternalLinkTypes">
    <xsl:for-each
      select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:table/table:shapes/draw:frame">
      <Override PartName="{concat(concat('/xl/externalLinks/externalLink', position()),'.xml')}"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Sheet content types -->
  <xsl:template name="InsertSheetContentTypes">
    <xsl:for-each
      select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:table">
      <Override PartName="{concat(concat('/xl/worksheets/sheet', position()),'.xml')}"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertCommentContentTypes">
    <xsl:for-each
      select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:table">
      <xsl:if test="descendant::office:annotation">
        <Override PartName="{concat(concat('/xl/comments', position()),'.xml')}"
          ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml"/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertDrawingContentTypes">
    <xsl:for-each
      select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:table">

      <xsl:variable name="chart">
        <xsl:for-each select="descendant::draw:frame/draw:object">
          <xsl:choose>
            <xsl:when test="not(document(concat(translate(@xlink:href,'./',''),'/settings.xml')))">
          <xsl:for-each select="document(concat(translate(@xlink:href,'./',''),'/content.xml'))">
            <xsl:choose>
              <xsl:when test="office:document-content/office:body/office:chart">
                <xsl:text>true</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>false</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>false</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
            
      <xsl:variable name="picture">
        <xsl:choose>
          <xsl:when
            test="descendant::draw:frame/draw:image[not(starts-with(@xlink:href,'./ObjectReplacements')) and not(name(parent::node()/parent::node()) = 'draw:g' )]">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <xsl:variable name="textBox">
        <xsl:choose>
          <xsl:when test="descendant::draw:frame/draw:text-box">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      

      <!-- TO DO for pictures-->      
      <xsl:if test="contains($chart,'true') or $picture = 'true' or $textBox = 'true' ">
        <Override PartName="{concat('/xl/drawings/drawing',position(),'.xml')}"
          ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>        
        
        <xsl:call-template name="InsertChartContentTypes">
          <xsl:with-param name="sheetNum" select="position()"></xsl:with-param>
          <xsl:with-param name="chart">
            <xsl:value-of select="$chart"/>
          </xsl:with-param>
        </xsl:call-template>         
        
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
    <xsl:template name="InsertChartContentTypes">
      <xsl:param name="sheetNum"/>
      <xsl:param name="chart"/>

      <xsl:if test="contains($chart, 'true')">
      <xsl:for-each
        select="descendant::draw:frame/draw:object[document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart]">
        <Override PartName="{concat('/xl/charts/chart',$sheetNum,'_',position(),'.xml')}"
          ContentType="application/vnd.openxmlformats-officedocument.drawingml.chart+xml"/>        
      </xsl:for-each>
      </xsl:if>
    </xsl:template>
  
  <xsl:template name="InsertConnectionContentTypes">
    <xsl:for-each
      select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:table/table:table-row/table:table-cell/table:cell-range-source">
      <xsl:variable name="queryTableTarget">
        <xsl:value-of select="concat('/xl/queryTables/queryTable', position(), '.xml')"/>
      </xsl:variable>
      <Override PartName="{$queryTableTarget}"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml"/>    
    </xsl:for-each>   
  </xsl:template>
  
  
  <!-- Change Tracking -->
  
  <xsl:template name="InsertChangeTrackingTypes">
    
    <xsl:for-each select="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:tracked-changes">
      
      <Override PartName="/xl/revisions/revisionHeaders.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml"/>
      <xsl:apply-templates select="node()[1][name()='table:cell-content-change' or name()='table:deletion' or name()='table:movement' or name()='table:insertion']" mode="Content_Types"/>
    </xsl:for-each>
    
    <xsl:if test="document('content.xml')/office:document-content/office:body/office:spreadsheet/table:tracked-changes">
      <Override PartName="/xl/revisions/userNames.xml"
        ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml"/>
    </xsl:if>
    
  </xsl:template>
  
  <xsl:template match="table:cell-content-change|table:deletion|table:movement|table:insertion" mode="Content_Types">
    
    <Override PartName="{concat('/xl/revisions/revisionLog', generate-id(), '.xml')}"
      ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml"/>
    
    <xsl:if test="following-sibling::node()[1][name()='table:cell-content-change' or name()='table:deletion' or name()='table:movement' or name()='table:insertion']">
      <xsl:apply-templates select="following-sibling::node()[1][name()='table:cell-content-change' or name()='table:deletion' or name()='table:movement' or name()='table:insertion']" mode="Content_Types"/>
    </xsl:if>
    
  </xsl:template>
  
  
</xsl:stylesheet>