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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
  xmlns:pzip="urn:cleverage:xmlns:post-processings:zip"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" exclude-result-prefixes="table">

  <!-- insert column properties into sheet -->
  <xsl:template match="table:table-column" mode="sheet">
    <xsl:param name="colNumber"/>
    <xsl:param name="defaultFontSize"/>

    <!-- tableId required for CheckIfColumnStyle template -->
    <xsl:variable name="tableId">
      <xsl:value-of select="generate-id(ancestor::table:table)"/>
    </xsl:variable>

    <col min="{$colNumber}">
      <xsl:attribute name="max">
        <xsl:choose>
          <xsl:when test="@table:number-columns-repeated">
            <xsl:value-of select="$colNumber+@table:number-columns-repeated - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$colNumber"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <!-- insert column width -->
      <xsl:if
        test="key('style',@table:style-name)/style:table-column-properties/@style:column-width">
        <xsl:attribute name="width">
          <xsl:call-template name="ConvertToCharacters">
            <xsl:with-param name="width">
              <xsl:value-of
                select="key('style',@table:style-name)/style:table-column-properties/@style:column-width"
              />
            </xsl:with-param>
            <xsl:with-param name="defaultFontSize" select="$defaultFontSize"/>
          </xsl:call-template>
        </xsl:attribute>
        <xsl:attribute name="customWidth">1</xsl:attribute>
      </xsl:if>

      <xsl:if test="@table:visibility = 'collapse'">
        <xsl:attribute name="hidden">1</xsl:attribute>
      </xsl:if>

      <xsl:if test="@table:default-cell-style-name != 'Default' ">
        <!-- column style is when in all posible rows there is a cell in this column -->
        <xsl:variable name="checkColumnStyle">
          <xsl:for-each select="parent::node()/table:table-row[1]">
            <xsl:call-template name="CheckIfColumnStyle">
              <xsl:with-param name="number" select="$colNumber"/>
              <xsl:with-param name="table" select="$tableId"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:variable>

        <xsl:if test="$checkColumnStyle = 'true' ">
          <xsl:for-each select="key('style',@table:default-cell-style-name)">
            <xsl:attribute name="style">
              <xsl:number count="style:style[@style:family='table-cell']" level="any"/>
            </xsl:attribute>
          </xsl:for-each>
        </xsl:if>
      </xsl:if>
    </col>

    <!-- insert next column -->
    <xsl:if test="following-sibling::table:table-column">
      <xsl:apply-templates select="following-sibling::table:table-column[1]" mode="sheet">
        <xsl:with-param name="colNumber">
          <xsl:choose>
            <xsl:when test="@table:number-columns-repeated">
              <xsl:value-of select="$colNumber+@table:number-columns-repeated"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$colNumber+1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="defaultFontSize" select="$defaultFontSize"/>
      </xsl:apply-templates>
    </xsl:if>

  </xsl:template>

  <!-- Create Variable with "Default Style Name" -->
  <xsl:template name="CreateDefaultTag">
    <xsl:param name="colNumber"/>
    <xsl:param name="TagNumber"/>

    <xsl:param name="Tag"/>
    <xsl:param name="repeat"/>

    <xsl:choose>
      <xsl:when test="@table:number-columns-repeated &gt; $repeat">
        <xsl:call-template name="CreateDefaultTag">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$colNumber + 1"/>
          </xsl:with-param>
          <xsl:with-param name="TagNumber">
            <xsl:value-of select="$TagNumber"/>
          </xsl:with-param>
          <xsl:with-param name="Tag">
            <xsl:value-of
              select="concat(concat(concat($colNumber, @table:default-cell-style-name),';'), $Tag)"
            />
          </xsl:with-param>
          <xsl:with-param name="repeat">
            <xsl:value-of select="$repeat + 1"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat(concat(concat($colNumber, @table:default-cell-style-name),';'), $Tag)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="CreateStyleTags">
    <xsl:param name="repeat"/>
    <xsl:param name="colNumber"/>
    <xsl:param name="TagNumber"/>
    
    <xsl:param name="Tag"/>
    <xsl:param name="count" select="1"/>
    
    <xsl:choose>
      <xsl:when test="$repeat &gt; $count">
        <xsl:call-template name="CreateStyleTags">
          <xsl:with-param name="repeat" select="$repeat"/>
          <xsl:with-param name="colNumber" select="$colNumber + 1"/>
          <xsl:with-param name="TagNumber" select="$TagNumber"/>
          <xsl:with-param name="Tag">
            <xsl:value-of
              select="concat(concat(concat ('K', (concat($colNumber, ':')), @table:default-cell-style-name),';'), $Tag)"
            />
          </xsl:with-param>
          <xsl:with-param name="count" select="$count + 1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat(concat(concat ('K', (concat($colNumber, ':')), @table:default-cell-style-name),';'), $Tag)"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="table:table-column" mode="tag">
    <xsl:param name="colNumber"/>
    <xsl:param name="Tag"/>

    <xsl:variable name="TagNumber">
      <xsl:value-of select="concat('Tag', position())"/>
    </xsl:variable>

    <xsl:variable name="NextColl">
      <xsl:choose>
        <xsl:when test="@table:number-columns-repeated">
          <xsl:value-of select="$colNumber+@table:number-columns-repeated"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$colNumber+1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- style char for this table:table-column tag -->
    <xsl:variable name="TagChar">
      <xsl:choose>
        <!-- when this tag describes group of columns with changed default-cell-style-name -->
        <xsl:when test="@table:number-columns-repeated and @table:default-cell-style-name != 'Default' ">
          <xsl:call-template name="CreateStyleTags">
            <xsl:with-param name="colNumber">
              <xsl:value-of select="$colNumber"/>
            </xsl:with-param>
            <xsl:with-param name="TagNumber">
              <xsl:value-of select="$TagNumber"/>
            </xsl:with-param>
            <xsl:with-param name="Tag">
              <xsl:value-of select="$Tag"/>
            </xsl:with-param>
            <xsl:with-param name="repeat">
              <xsl:value-of select="@table:number-columns-repeated"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <!-- when this tag describes column(s) with default default-cell-style-name -->
        <xsl:when
          test="@table:default-cell-style-name = 'Default' ">
          <xsl:call-template name="CreateDefaultTag">
            <xsl:with-param name="colNumber">
              <xsl:value-of select="$colNumber"/>
            </xsl:with-param>
            <xsl:with-param name="TagNumber">
              <xsl:value-of select="$TagNumber"/>
            </xsl:with-param>
            <xsl:with-param name="Tag">
              <xsl:value-of select="$Tag"/>
            </xsl:with-param>
            <xsl:with-param name="repeat">1</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <!-- when this tag describes single column with changed default-cell-style-name -->
        <xsl:otherwise>
          <xsl:value-of
            select="concat(concat(concat ('K', (concat($colNumber, ':')), @table:default-cell-style-name),';'), $Tag)"
          />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!--check next column -->
    <xsl:choose>
      <xsl:when test="following-sibling::table:table-column">
        <xsl:apply-templates select="following-sibling::table:table-column[1]" mode="tag">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$NextColl"/>
          </xsl:with-param>
          <xsl:with-param name="Tag">
            <xsl:value-of select="$TagChar"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$TagChar"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- insert row into sheet -->
  <xsl:template match="table:table-row" mode="sheet">
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="defaultRowHeight"/>
    <xsl:param name="TableColumnTagNum"/>
    <xsl:variable name="height">
      <xsl:call-template name="ConvertMeasure">
        <xsl:with-param name="length">
          <xsl:value-of
            select="key('style',@table:style-name)/style:table-row-properties/@style:row-height"/>
        </xsl:with-param>
        <xsl:with-param name="unit">point</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if
      test="table:table-cell or @table:visibility='collapse' or  @table:visibility='filter' or $height != $defaultRowHeight or table:covered-table-cell">
      
      <row r="{$rowNumber}">

        <!-- insert row height -->
        <xsl:if test="$height">
          <xsl:attribute name="ht">
            <xsl:value-of select="$height"/>
          </xsl:attribute>
          <xsl:if
            test="not(key('style',@table:style-name)/style:table-row-properties/@style:use-optimal-row-height = 'true' ) or table:covered-table-cell">
            <xsl:attribute name="customHeight">1</xsl:attribute>
          </xsl:if>
        </xsl:if>

        <xsl:if test="@table:visibility = 'collapse' or @table:visibility = 'filter'">
          <xsl:attribute name="hidden">1</xsl:attribute>
        </xsl:if>

        <!-- insert first cell -->
        <xsl:apply-templates select="node()[1]" mode="sheet">
          <xsl:with-param name="colNumber">0</xsl:with-param>
          <xsl:with-param name="rowNumber" select="$rowNumber"/>
          <xsl:with-param name="cellNumber" select="$cellNumber"/>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </row>

      <!-- insert repeated rows -->
      <xsl:if test="@table:number-rows-repeated">
        <xsl:call-template name="InsertRepeatedRows">
          <xsl:with-param name="numberRowsRepeated">
            <xsl:value-of select="@table:number-rows-repeated"/>
          </xsl:with-param>
          <xsl:with-param name="numberOfAllRowsRepeated">
            <xsl:value-of select="@table:number-rows-repeated"/>
          </xsl:with-param>
          <xsl:with-param name="rowNumber">
            <xsl:value-of select="$rowNumber + 1"/>
          </xsl:with-param>
          <xsl:with-param name="cellNumber">
            <xsl:value-of select="$cellNumber"/>
          </xsl:with-param>
          <xsl:with-param name="height">
            <xsl:value-of select="$height"/>
          </xsl:with-param>
          <xsl:with-param name="defaultRowHeight">
            <xsl:value-of select="$defaultRowHeight"/>
          </xsl:with-param>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:if>

    </xsl:if>

    <!-- insert next row -->
    <xsl:if test="following-sibling::table:table-row">
      <xsl:apply-templates select="following-sibling::table:table-row[1]" mode="sheet">
        <xsl:with-param name="rowNumber">
          <xsl:choose>
            <xsl:when test="@table:number-rows-repeated">
              <xsl:value-of select="$rowNumber+@table:number-rows-repeated"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$rowNumber+1"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="cellNumber">
          <!-- last or is for cells with error -->
          <xsl:value-of
            select="$cellNumber + count(child::table:table-cell[text:p and (@office:value-type='string' or not((number(text:p) or text:p = 0 or contains(text:p,','))))])"
          />
        </xsl:with-param>
        <xsl:with-param name="defaultRowHeight" select="$defaultRowHeight"/>
        <xsl:with-param name="TableColumnTagNum">
          <xsl:value-of select="$TableColumnTagNum"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:if>

  </xsl:template>

  <!-- template which inserts repeated rows -->
  <xsl:template name="InsertRepeatedRows">
    <xsl:param name="numberRowsRepeated"/>
    <xsl:param name="numberOfAllRowsRepeated"/>
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="height"/>
    <xsl:param name="defaultRowHeight"/>
    <xsl:param name="TableColumnTagNum"/>
    
    <xsl:choose>
      <xsl:when test="$numberRowsRepeated &gt; 1">
        
          <row>
            <xsl:attribute name="r">
              <xsl:value-of select="$rowNumber"/>
            </xsl:attribute>

            <!-- insert row height -->
            <xsl:if test="$height">
              <xsl:attribute name="ht">
                <xsl:value-of select="$height"/>
              </xsl:attribute>
              <xsl:attribute name="customHeight">1</xsl:attribute>
            </xsl:if>

            <xsl:if test="@table:visibility = 'collapse' or @table:visibility = 'filter'">
              <xsl:attribute name="hidden">1</xsl:attribute>
            </xsl:if>
            
            <!-- insert first cell -->
            <xsl:apply-templates select="node()[1]" mode="sheet">
              <xsl:with-param name="colNumber">0</xsl:with-param>
              <xsl:with-param name="rowNumber" select="$rowNumber"/>
              <xsl:with-param name="cellNumber" select="$cellNumber"/>
              <xsl:with-param name="TableColumnTagNum">
                <xsl:value-of select="$TableColumnTagNum"/>
              </xsl:with-param>
            </xsl:apply-templates>
          </row>
        
        <!-- insert repeated rows -->        
        <xsl:if test="@table:number-rows-repeated">
          <xsl:call-template name="InsertRepeatedRows">
            <xsl:with-param name="numberRowsRepeated">
              <xsl:value-of select="$numberRowsRepeated - 1"/>
            </xsl:with-param>
            <xsl:with-param name="numberOfAllRowsRepeated">
              <xsl:value-of select="@table:number-rows-repeated"/>
            </xsl:with-param>
            <xsl:with-param name="rowNumber">
              <xsl:value-of select="$rowNumber + 1"/>
            </xsl:with-param>
            <xsl:with-param name="cellNumber">
              <xsl:value-of select="$cellNumber"/>
            </xsl:with-param>
            <xsl:with-param name="height">
              <xsl:value-of select="$height"/>
            </xsl:with-param>
            <xsl:with-param name="defaultRowHeight">
              <xsl:value-of select="$defaultRowHeight"/>
            </xsl:with-param>
            <xsl:with-param name="TableColumnTagNum">
              <xsl:value-of select="$TableColumnTagNum"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>

      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- insert cell into row -->
  <xsl:template match="table:table-cell|table:covered-table-cell" mode="sheet">
    <xsl:param name="colNumber"/>
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="TableColumnTagNum"/>

    <xsl:call-template name="InsertConvertCell">
      <xsl:with-param name="colNumber">
        <xsl:value-of select="$colNumber"/>
      </xsl:with-param>
      <xsl:with-param name="rowNumber">
        <xsl:value-of select="$rowNumber"/>
      </xsl:with-param>
      <xsl:with-param name="cellNumber">
        <xsl:value-of select="$cellNumber"/>
      </xsl:with-param>
      <xsl:with-param name="ColumnRepeated">1</xsl:with-param>
      <xsl:with-param name="TableColumnTagNum">
        <xsl:value-of select="$TableColumnTagNum"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- insert cell -->
  <xsl:template name="InsertNextCell">
    <xsl:param name="colNumber"/>
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="TableColumnTagNum"/>

    <xsl:choose>
      <!-- Checks if  next index is table:table-cell-->
      <xsl:when test="following-sibling::node()[1][name()='table:table-cell']">
        <xsl:apply-templates select="following-sibling::table:table-cell[1]" mode="sheet">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$colNumber+1"/>
          </xsl:with-param>
          <xsl:with-param name="rowNumber" select="$rowNumber"/>
          <!-- if this node was table:table-cell with string than increase cellNumber-->
          <xsl:with-param name="cellNumber">
            <xsl:choose>
              <xsl:when
                test="name()='table:table-cell' and child::text:p and (@office:value-type='string' or not((number(text:p) or text:p = 0 or contains(text:p,','))))">
                <xsl:value-of select="$cellNumber + 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$cellNumber"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <!--  Checks if next index is table:covered-table-cell-->
      <xsl:when test="following-sibling::node()[1][name()='table:covered-table-cell']">
        <xsl:apply-templates select="following-sibling::table:covered-table-cell[1]" mode="sheet">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$colNumber+1"/>
          </xsl:with-param>
          <xsl:with-param name="rowNumber" select="$rowNumber"/>
          <!-- if this node was table:table-cell with string than increase cellNumber-->
          <xsl:with-param name="cellNumber">
            <xsl:choose>
              <xsl:when
                test="name()='table:table-cell' and child::text:p and (@office:value-type='string' or not((number(text:p) or text:p = 0 or contains(text:p,','))))">
                <xsl:value-of select="$cellNumber + 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$cellNumber"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="ColumnRepeated">1</xsl:with-param>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>

  </xsl:template>


  <!-- Insert Cell for "@table:number-columns-repeated"-->
  <xsl:template name="InsertConvertCell">
    <xsl:param name="colNumber"/>
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="ColumnRepeated"/>
    <xsl:param name="TableColumnTagNum"/>

    <!-- do not show covered cells content -->
    <xsl:if test="name(.) = 'table:table-cell' ">
      <xsl:call-template name="InsertCell">
        <xsl:with-param name="colNumber">
          <xsl:value-of select="$colNumber"/>
        </xsl:with-param>
        <xsl:with-param name="rowNumber">
          <xsl:value-of select="$rowNumber"/>
        </xsl:with-param>
        <xsl:with-param name="cellNumber">
          <xsl:value-of select="$cellNumber"/>
        </xsl:with-param>
        <xsl:with-param name="TableColumnTagNum">
          <xsl:value-of select="$TableColumnTagNum"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- Insert cells if "@table:number-columns-repeated"  > 1 -->
    <xsl:choose>
      <xsl:when
        test="@table:number-columns-repeated and number(@table:number-columns-repeated) &gt; $ColumnRepeated">

        <xsl:call-template name="InsertConvertCell">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$colNumber+1"/>
          </xsl:with-param>
          <xsl:with-param name="rowNumber" select="$rowNumber"/>
          <xsl:with-param name="cellNumber">
            <xsl:value-of select="$cellNumber"/>
          </xsl:with-param>
          <xsl:with-param name="ColumnRepeated">
            <xsl:value-of select="$ColumnRepeated + 1"/>
          </xsl:with-param>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:when>
      <xsl:otherwise>

        <!-- insert next cell -->
        <xsl:call-template name="InsertNextCell">
          <xsl:with-param name="colNumber">
            <xsl:value-of select="$colNumber"/>
          </xsl:with-param>
          <xsl:with-param name="rowNumber">
            <xsl:value-of select="$rowNumber"/>
          </xsl:with-param>
          <xsl:with-param name="cellNumber">
            <xsl:value-of select="$cellNumber"/>
          </xsl:with-param>
          <xsl:with-param name="TableColumnTagNum">
            <xsl:value-of select="$TableColumnTagNum"/>
          </xsl:with-param>
        </xsl:call-template>

      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertCell">
    <xsl:param name="colNumber"/>
    <xsl:param name="rowNumber"/>
    <xsl:param name="cellNumber"/>
    <xsl:param name="TableColumnTagNum"/>

    <xsl:variable name="columnCellStyle">
      <xsl:call-template name="GetColumnCellStyle">
        <xsl:with-param name="colNum">
          <xsl:value-of select="$colNumber + 1"/>
        </xsl:with-param>
        <xsl:with-param name="TableColumnTagNum">
          <xsl:value-of select="$TableColumnTagNum"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    
    <xsl:if test="child::text:p or $columnCellStyle != '' or @table:style-name != ''">
      <c>
        <xsl:attribute name="r">
          <xsl:variable name="colChar">
            <xsl:call-template name="NumbersToChars">
              <xsl:with-param name="num" select="$colNumber"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="concat($colChar,$rowNumber)"/>
        </xsl:attribute>
        
        <!-- insert cell style number -->
        <xsl:choose>
          <!-- if it is a multiline cell -->
          <xsl:when test="text:p[2]">
            <xsl:variable name="cellFormats">
              <xsl:value-of
                select="count(document('content.xml')/office:document-content/office:automatic-styles/style:style[@style:family='table-cell']) + 1"
              />
            </xsl:variable>
            <xsl:variable name="multilineNumber">
              <xsl:for-each select="text:p[2]">
                <xsl:number count="table:table-cell[text:p[2]]" level="any"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:attribute name="s">
              <xsl:value-of select="$cellFormats - 1 + $multilineNumber"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <!-- when style is specified in cell -->
              <xsl:when test="@table:style-name">
                <xsl:for-each select="key('style',@table:style-name)">
                  <xsl:attribute name="s">
                    <xsl:number count="style:style[@style:family='table-cell']" level="any"/>
                  </xsl:attribute>
                </xsl:for-each>
              </xsl:when>
              <!-- when style is specified in column -->
              <xsl:otherwise>
                <xsl:if test="$columnCellStyle != '' ">
                  <xsl:for-each select="key('style',$columnCellStyle)">
                    <xsl:attribute name="s">
                      <xsl:number count="style:style[@style:family='table-cell']" level="any"/>
                    </xsl:attribute>
                  </xsl:for-each>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        

        <!-- convert cell type -->
        <xsl:if test="child::text:p">
          <xsl:choose>
            <xsl:when
              test="@office:value-type!='string' and @office:value-type != 'percentage' and @office:value-type != 'date' and @office:value-type != 'time' and @office:value-type!='boolean' and (number(text:p) or text:p = 0 or contains(text:p,','))">
              <xsl:variable name="Type">
                <xsl:call-template name="ConvertTypes">
                  <xsl:with-param name="type">
                    <xsl:value-of select="@office:value-type"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:variable>
              <xsl:attribute name="t">
                <xsl:value-of select="$Type"/>
              </xsl:attribute>
              <v>
                <xsl:choose>
                  <xsl:when test="$Type = 'n'">
                    <xsl:choose>
                      <xsl:when test="@office:value != ''">
                        <xsl:value-of select="@office:value"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="translate(text:p,',','.')"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="text:p"/>
                  </xsl:otherwise>
                </xsl:choose>
              </v>
            </xsl:when>
            <!-- TO DO  percentage-->
            <xsl:when test="@office:value-type = 'percentage'">
              <xsl:attribute name="t">n</xsl:attribute>
              <v>
                <xsl:choose>
                  <xsl:when test="@office:value">
                    <xsl:value-of select="@office:value"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="translate(substring-before(text:p, '%'), ',', '.')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </v>
            </xsl:when>
            <!-- TO DO  date and time-->
            <xsl:when test="@office:value-type = 'date' or @office:value-type = 'time'"/>
            <!-- last or when number cell has error -->
            <xsl:when
              test="@office:value-type = 'string' or @office:value-type = 'boolean' or not((number(text:p) or text:p = 0 or contains(text:p,',')))">
              <xsl:attribute name="t">s</xsl:attribute>
              <v>
                <xsl:value-of select="number($cellNumber)"/>
              </v>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </c>
    </xsl:if>
  </xsl:template>

  <xsl:template name="GetColumnCellStyle">
    <xsl:param name="colNum"/>
    <xsl:param name="table-column_tagNum" select="1"/>
    <xsl:param name="column" select="1"/>
    <xsl:param name="TableColumnTagNum"/>
    <xsl:value-of
      select="substring-before(substring-after($TableColumnTagNum, concat(concat('K', $colNum), ':')), ';')"
    />
  </xsl:template>

  <xsl:template name="GetColNumber">
    <xsl:param name="position"/>
    <xsl:param name="count" select="1"/>
    <xsl:param name="value" select="1"/>

    <xsl:choose>
      <xsl:when test="$count &lt; $position">
        <xsl:variable name="columns">
          <xsl:choose>
            <xsl:when test="@table:number-columns-repeated">
              <xsl:value-of select="@table:number-columns-repeated"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>1</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:for-each select="following-sibling::table:table-cell[1]">
          <xsl:call-template name="GetColNumber">
            <xsl:with-param name="position">
              <xsl:value-of select="$position"/>
            </xsl:with-param>
            <xsl:with-param name="count">
              <xsl:value-of select="$count + 1"/>
            </xsl:with-param>
            <xsl:with-param name="value">
              <xsl:value-of select="$value + $columns"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="CheckIfColumnStyle">
    <xsl:param name="number"/>
    <xsl:param name="table"/>
    <xsl:param name="count" select="0"/>
    <xsl:param name="value"/>

    <xsl:variable name="newValue">
      <xsl:for-each select="table:table-cell[1]">
        <xsl:call-template name="CheckIfCellNonEmpty">
          <xsl:with-param name="number">
            <xsl:value-of select="$number"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$newValue != 'end' ">

        <xsl:variable name="rows">
          <xsl:choose>
            <xsl:when test="@table:number-rows-repeated">
              <xsl:value-of select="@table:number-rows-repeated"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>1</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="table2">
          <xsl:for-each select="following::table:table-row[1]">
            <xsl:value-of select="generate-id(ancestor::table:table)"/>
          </xsl:for-each>
        </xsl:variable>

        <!-- go to the next row in the same table-->
        <xsl:choose>
          <xsl:when test="$table = $table2">
            <xsl:for-each select="following::table:table-row[1]">
              <xsl:call-template name="CheckIfColumnStyle">
                <xsl:with-param name="number" select="$number"/>
                <xsl:with-param name="table" select="$table"/>
                <xsl:with-param name="count" select="$count + $rows"/>
                <xsl:with-param name="value" select="$newValue"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <!-- when last possible row was reached -->
              <xsl:when test="$count + $rows = 65536">
                <xsl:text>true</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>false</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- when cell in column $number didn't occur in the row-->
      <xsl:otherwise>
        <xsl:text>false</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- "true" when cell is non-empty, "false" when empty, "end" when after the end of a row -->
  <xsl:template name="CheckIfCellNonEmpty">
    <xsl:param name="number"/>
    <xsl:param name="count" select="1"/>
    <xsl:param name="value"/>

    <xsl:choose>
      <xsl:when test="$count &lt; $number">
        <xsl:variable name="columns">
          <xsl:choose>
            <xsl:when test="@table:number-columns-repeated">
              <xsl:value-of select="@table:number-columns-repeated"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>1</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="newValue">
          <xsl:choose>
            <xsl:when test="text:p">
              <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>false</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="following-sibling::table:table-cell[1]">
            <xsl:for-each select="following-sibling::table:table-cell[1]">
              <xsl:call-template name="CheckIfCellNonEmpty">
                <xsl:with-param name="number">
                  <xsl:value-of select="$number"/>
                </xsl:with-param>
                <xsl:with-param name="count">
                  <xsl:value-of select="$count + $columns"/>
                </xsl:with-param>
                <xsl:with-param name="value">
                  <xsl:value-of select="$newValue"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <!-- when cell is in last table:table-cell tag and it has columns-repeated attribute -->
          <xsl:when test="$columns &gt; 1 and $count + $columns &gt;= $number">
            <xsl:value-of select="$newValue"/>
          </xsl:when>
          <!-- when cell is after the end of the row -->
          <xsl:otherwise>
            <xsl:text>end</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$count = $number">
            <xsl:variable name="newValue">
              <xsl:choose>
                <xsl:when test="text:p">
                  <xsl:text>true</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>false</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="$newValue"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$value"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
