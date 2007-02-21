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
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:e="http://schemas.openxmlformats.org/spreadsheetml/2006/main" exclude-result-prefixes="e r">

  <xsl:import href="relationships.xsl"/>
  <xsl:import href="measures.xsl"/>
  <xsl:import href="styles.xsl"/>

  <xsl:template name="content">
    <office:document-content>
      <office:scripts/>
      <office:font-face-decls>
        <xsl:call-template name="InsertFonts"/>
      </office:font-face-decls>
      <office:automatic-styles>
        <xsl:call-template name="InsertColumnStyles"/>
        <xsl:call-template name="InsertRowStyles"/>
        <xsl:call-template name="InsertCellStyles"/>
        <xsl:call-template name="InsertStyleTableProperties"/>
      </office:automatic-styles>
      <xsl:call-template name="InsertSheets"/>
    </office:document-content>
  </xsl:template>

  <xsl:template name="InsertSheets">
    <office:body>
      <office:spreadsheet>
        <xsl:for-each select="document('xl/workbook.xml')/e:workbook/e:sheets/e:sheet">
          <table:table>

            <!-- Insert Table (Sheet) Name -->

            <xsl:attribute name="table:name">
              <xsl:value-of select="@name"/>
            </xsl:attribute>

            <!-- Insert Table Style Name (style:table-properties) -->

            <xsl:attribute name="table:style-name">
              <xsl:value-of select="generate-id()"/>
            </xsl:attribute>

            <xsl:call-template name="InsertSheetContent">
              <xsl:with-param name="sheet">
                <xsl:call-template name="GetTarget">
                  <xsl:with-param name="id">
                    <xsl:value-of select="@r:id"/>
                  </xsl:with-param>
                  <xsl:with-param name="document">xl/workbook.xml</xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:call-template>
          </table:table>
        </xsl:for-each>
      </office:spreadsheet>
    </office:body>
  </xsl:template>

  <xsl:template name="InsertSheetContent">
    <xsl:param name="sheet"/>

    <xsl:call-template name="InsertColumns">
      <xsl:with-param name="sheet" select="$sheet"/>
    </xsl:call-template>

    <xsl:apply-templates select="document(concat('xl/',$sheet))/e:worksheet"/>

    <xsl:choose>
      <!-- when sheet is empty -->
      <xsl:when test="not(document(concat('xl/',$sheet))/e:worksheet/e:sheetData/e:row/e:c/e:v)">
        <table:table-row
          table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
          table:number-rows-repeated="65535">
          <table:table-cell/>
        </table:table-row>
      </xsl:when>
      <xsl:otherwise>
        <table:table-row
          table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
          table:number-rows-repeated="{65535 - document(concat('xl/',$sheet))/e:worksheet/e:sheetData/e:row[last()]/@r}">
          <table:table-cell/>
        </table:table-row>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="e:row">

    <xsl:variable name="lastCellColumnNumber">
      <xsl:choose>
        <xsl:when test="e:c[last()]/@r">
          <xsl:call-template name="GetColNum">
            <xsl:with-param name="cell">
              <xsl:value-of select="e:c[last()]/@r"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- insert blank rows before this one -->
    <xsl:choose>
      <!-- if first rows are empty-->
      <xsl:when test="position()=1">
        <xsl:if test="@r>1">
          <table:table-row table:style-name="{generate-id(ancestor::e:worksheet/e:sheetFormatPr)}"
            table:number-rows-repeated="{@r - 1}">
            <table:table-cell table:number-columns-repeated="256"/>
          </table:table-row>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <!-- if there's a gap between rows -->
        <xsl:if test="preceding::e:row[1]/@r &lt;  @r - 1">
          <table:table-row table:style-name="{generate-id(ancestor::e:worksheet/e:sheetFormatPr)}">
            <xsl:attribute name="table:number-rows-repeated">
              <xsl:value-of select="@r -1 - preceding::e:row[1]/@r"/>
            </xsl:attribute>
            <table:table-cell table:number-columns-repeated="256"/>
          </table:table-row>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

    <!-- insert this one row -->
    <table:table-row>
      <xsl:attribute name="table:style-name">
        <xsl:choose>
          <xsl:when test="@ht">
            <xsl:value-of select="generate-id(.)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="generate-id(ancestor::e:worksheet/e:sheetFormatPr)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="@hidden=1">
        <xsl:attribute name="table:visibility">
          <xsl:text>collapse</xsl:text>
        </xsl:attribute>
      </xsl:if>

      <xsl:apply-templates/>

      <xsl:if test="$lastCellColumnNumber &lt; 256">
        <table:table-cell table:number-columns-repeated="{256 - $lastCellColumnNumber}"/>
      </xsl:if>
    </table:table-row>
  </xsl:template>

  <xsl:template match="e:c">

    <xsl:variable name="this" select="."/>

    <xsl:variable name="colNum">
      <xsl:call-template name="GetColNum">
        <xsl:with-param name="cell">
          <xsl:value-of select="@r"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="prevCellColNum">
      <xsl:choose>
        <xsl:when
          test="preceding::e:c[1] and generate-id(preceding::e:c[1]/parent::node())=generate-id(parent::node())">
          <xsl:call-template name="GetColNum">
            <xsl:with-param name="cell">
              <xsl:value-of select="preceding::e:c[1]/@r"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>-1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- insert blank cells before this one-->
    <xsl:choose>
      <xsl:when test="position()=1 and $colNum>1">
        <table:table-cell>
          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="$colNum - 1"/>
          </xsl:attribute>
        </table:table-cell>
      </xsl:when>
      <xsl:when test="position()>1 and $colNum>$prevCellColNum+1">
        <table:table-cell>
          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="$colNum - $prevCellColNum - 1"/>
          </xsl:attribute>
        </table:table-cell>
      </xsl:when>
    </xsl:choose>

    <!-- insert this one cell-->
    <table:table-cell>
      <xsl:choose>
        <xsl:when test="@t='s'">
          <xsl:attribute name="office:value-type">
            <xsl:text>string</xsl:text>
          </xsl:attribute>
          <xsl:if test="@s">
            <xsl:attribute name="table:style-name">
              <xsl:value-of
                select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[position() = $this/@s + 1])"
              />
            </xsl:attribute>
          </xsl:if>
          <xsl:variable name="id">
            <xsl:value-of select="e:v"/>
          </xsl:variable>
          <text:p>
            <xsl:value-of select="document('xl/sharedStrings.xml')/e:sst/e:si[position()=$id+1]/e:t"
            />
          </text:p>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="office:value-type">
            <xsl:text>float</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="office:value">
            <xsl:value-of select="e:v"/>
          </xsl:attribute>
          <text:p>
            <xsl:value-of select="e:v"/>
          </text:p>
        </xsl:otherwise>
      </xsl:choose>
    </table:table-cell>
  </xsl:template>
  
  <!-- calculates power function -->
  <xsl:template name="Power">
    <xsl:param name="base"/>
    <xsl:param name="exponent"/>
    <xsl:param name="value1" select="$base"/>

    <xsl:choose>
      <xsl:when test="$exponent = 0">
        <xsl:text>1</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$exponent &gt; 1">
            <xsl:call-template name="Power">
              <xsl:with-param name="base">
                <xsl:value-of select="$base"/>
              </xsl:with-param>
              <xsl:with-param name="exponent">
                <xsl:value-of select="$exponent -1"/>
              </xsl:with-param>
              <xsl:with-param name="value1">
                <xsl:value-of select="$value1 * $base"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$value1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertColumns">
    <xsl:param name="sheet"/>

    <xsl:for-each select="document(concat('xl/',$sheet))/e:worksheet/e:cols/e:col">
      <!-- insert blank columns before this one-->
      <xsl:choose>
        <xsl:when test="position()=1 and @min>1">
          <table:table-column
            table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
            table:number-columns-repeated="{@min - 1}">
            <xsl:attribute name="table:default-cell-style-name">
              <xsl:value-of
                select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[1])"/>
            </xsl:attribute>
          </table:table-column>
        </xsl:when>
        <xsl:when test="preceding::e:col[1]/@max &lt; @min - 1">
          <table:table-column
            table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
            table:number-columns-repeated="{@min - preceding::e:col[1]/@max - 1}">
            <xsl:attribute name="table:default-cell-style-name">
              <xsl:value-of
                select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[1])"/>
            </xsl:attribute>
          </table:table-column>
        </xsl:when>
      </xsl:choose>

      <!-- insert this one column -->
      <table:table-column table:style-name="{generate-id(.)}">
        <xsl:if test="not(@min = @max)">
          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="@max - @min + 1"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="table:default-cell-style-name">
          <xsl:value-of
            select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[1])"/>
        </xsl:attribute>
        <xsl:if test="@hidden=1">
          <xsl:attribute name="table:visibility">
            <xsl:text>collapse</xsl:text>
          </xsl:attribute>
        </xsl:if>
      </table:table-column>
    </xsl:for-each>

    <!-- apply default column style for last columns which style wasn't changed -->
    <xsl:choose>
      <xsl:when test="not(document(concat('xl/',$sheet))/e:worksheet/e:cols/e:col)">
        <table:table-column
          table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
          table:number-columns-repeated="256">
          <xsl:attribute name="table:default-cell-style-name">
            <xsl:value-of
              select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[1])"/>
          </xsl:attribute>
        </table:table-column>
      </xsl:when>
      <xsl:otherwise>
        <table:table-column
          table:style-name="{generate-id(document(concat('xl/',$sheet))/e:worksheet/e:sheetFormatPr)}"
          table:number-columns-repeated="{256 - document(concat('xl/',$sheet))/e:worksheet/e:cols/e:col[last()]/@max}">
          <xsl:attribute name="table:default-cell-style-name">
            <xsl:value-of
              select="generate-id(document('xl/styles.xml')/e:styleSheet/e:cellXfs/e:xf[1])"/>
          </xsl:attribute>
        </table:table-column>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ConvertFromCharacters">
    <xsl:param name="value"/>

    <!-- strange but true: the best result is when you WON'T convert average digit width from pt to px-->
    <xsl:variable name="defaultFontSize">
      <xsl:choose>
        <xsl:when test="document('xl/styles.xml')/e:styleSheet/e:fonts/e:font">
          <xsl:value-of select="document('xl/styles.xml')/e:styleSheet/e:fonts/e:font[1]/e:sz/@val"
          />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>11</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- for proportional fonts average digit width is 2/3 of font size-->
    <xsl:variable name="avgDigitWidth">
      <xsl:value-of select="$defaultFontSize * 0.66666"/>
    </xsl:variable>
    <xsl:call-template name="ConvertToCentimeters">
      <xsl:with-param name="length">
        <xsl:value-of select="concat(($avgDigitWidth * $value) - 5,'px')"/>
      </xsl:with-param>
  </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
