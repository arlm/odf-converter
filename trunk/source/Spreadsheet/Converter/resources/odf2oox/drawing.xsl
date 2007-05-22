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
  xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0">

  <xsl:import href="cell.xsl"/>
  <xsl:import href="common.xsl"/>

  <xsl:template name="InsertDrawing">
    <xdr:wsDr>
      <!-- for charts, file pointed by draw:frame/draw:object/@xlink:href must contain office:chart -->
      <xsl:for-each
        select="descendant::draw:frame/draw:object[document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart]">
        <xdr:twoCellAnchor>
          <xdr:from>
            <xdr:col>
              <xsl:call-template name="InsertStartColumn"/>
            </xdr:col>
            <xdr:colOff>714375</xdr:colOff>
            <xdr:row>
              <xsl:call-template name="InsertStartRow"/>
            </xdr:row>
            <xdr:rowOff>104775</xdr:rowOff>
          </xdr:from>
          <xdr:to>
            <xdr:col>
              <xsl:call-template name="InsertEndColumn"/>
            </xdr:col>
            <xdr:colOff>447675</xdr:colOff>
            <xdr:row>
              <xsl:call-template name="InsertEndRow"/>
            </xdr:row>
            <xdr:rowOff>104775</xdr:rowOff>
          </xdr:to>
          <xdr:graphicFrame macro="">
            <xdr:nvGraphicFramePr>
              <xdr:cNvPr id="{position()}" name="{concat('Chart ',position())}"/>
              <xdr:cNvGraphicFramePr>
                <a:graphicFrameLocks/>
              </xdr:cNvGraphicFramePr>
            </xdr:nvGraphicFramePr>
            <xdr:xfrm>
              <a:off x="0" y="0"/>
              <a:ext cx="0" cy="0"/>
            </xdr:xfrm>
            <a:graphic>
              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/chart">
                <c:chart xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                  r:id="{generate-id(.)}"/>
              </a:graphicData>
            </a:graphic>
          </xdr:graphicFrame>
          <xdr:clientData/>
        </xdr:twoCellAnchor>
      </xsl:for-each>
    </xdr:wsDr>
  </xsl:template>

  <xsl:template name="InsertStartColumn">
    <xsl:choose>
      <!-- when anchor is to cell -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:table-cell']">
        <xsl:for-each select="parent::node()/parent::node()">
          <xsl:variable name="position">
            <xsl:value-of select="count(preceding-sibling::table:table-cell) + 1"/>
          </xsl:variable>
          <xsl:variable name="number">
            <xsl:for-each select="parent::node()/table:table-cell[1]">
              <xsl:call-template name="GetColNumber">
                <xsl:with-param name="position" select="$position"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <xsl:value-of select="$number - 1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- when anchor is to page -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:shapes']">
        <xsl:text>1</xsl:text>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertStartRow">
    <xsl:choose>
      <!-- when anchor is to cell -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:table-cell']">
        <!-- get parent table:table-row id -->
        <xsl:variable name="rowId">
          <xsl:value-of select="generate-id(ancestor::table:table-row)"/>
        </xsl:variable>
        <!-- go to first table:table-row-->
        <xsl:for-each select="ancestor::table:table/descendant::table:table-row[1]">
          <xsl:variable name="number">
            <xsl:call-template name="GetRowNumber">
              <xsl:with-param name="rowId" select="$rowId"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$number - 1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- when anchor is to page -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:shapes']">
        <xsl:text>31</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertEndColumn">
    <xsl:choose>
      <!-- when anchor is to cell -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:table-cell']">
        <xsl:for-each select="parent::node()">
          <xsl:variable name="number">
            <xsl:call-template name="GetColNum">
              <xsl:with-param name="cell" select="substring-after(@table:end-cell-address,'.')"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$number - 1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- when anchor is to page -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:shapes']">
        <xsl:text>5</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="InsertEndRow">
    <xsl:choose>
      <!-- when anchor is to cell -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:table-cell']">
        <xsl:for-each select="parent::node()">
          <xsl:variable name="number">
            <xsl:call-template name="GetRowNum">
              <xsl:with-param name="cell" select="substring-after(@table:end-cell-address,'.')"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$number - 1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- when anchor is to page -->
      <xsl:when test="parent::node()/parent::node()[name() = 'table:shapes']">
        <xsl:text>46</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
