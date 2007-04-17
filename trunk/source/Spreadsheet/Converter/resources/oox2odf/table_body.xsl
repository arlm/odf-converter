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

  <!-- Insert sheet without text -->
  <xsl:template name="InsertEmptySheet">
    <xsl:param name="sheet"/>
    <xsl:param name="BigMergeCell"/>
    <xsl:param name="BigMergeRow"/>
    <xsl:param name="RowNumber"/>

    <xsl:choose>
      <!-- when sheet is empty  -->
      <xsl:when
        test="not(e:worksheet/e:sheetData/e:row/e:c/e:v) and $BigMergeCell = '' and $BigMergeRow = ''">
        <table:table-row table:style-name="{generate-id(key('SheetFormatPr', ''))}"
          table:number-rows-repeated="65536">
          <table:table-cell table:number-columns-repeated="256"/>
        </table:table-row>
      </xsl:when>
      <xsl:when test="$BigMergeRow != '' and e:worksheet/e:sheetData/e:row/e:c">
        <table:table-row table:style-name="ro1">
          <table:covered-table-cell table:number-columns-repeated="256"/>
        </table:table-row>
      </xsl:when>
      <xsl:otherwise>
        <!-- it is necessary when sheet has different default row height -->
        <xsl:if
          test="65536 - e:worksheet/e:sheetData/e:row[last()]/@r &gt; 0 or $BigMergeCell != ''">
          <xsl:choose>
            <xsl:when test="$BigMergeCell != ''">
              <xsl:call-template name="InsertColumnsBigMergeRow">
                <xsl:with-param name="Repeat">
                  <xsl:choose>
                    <xsl:when test="e:worksheet/e:sheetData/e:row[last()]/@r">
                      <xsl:value-of select="65536 - e:worksheet/e:sheetData/e:row[last()]/@r"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="65536"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="RowNumber">
                  <xsl:choose>
                    <xsl:when test="$RowNumber != ''">
                      <xsl:value-of select="$RowNumber"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>1</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="BigMergeCell">
                  <xsl:value-of select="$BigMergeCell"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <table:table-row table:style-name="{generate-id(key('SheetFormatPr', ''))}"
                table:number-rows-repeated="{65536 - e:worksheet/e:sheetData/e:row[last()]/@r}">
                <table:table-cell table:number-columns-repeated="256"/>
              </table:table-row>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertThisRow">
    <xsl:param name="BigMergeCell"/>
    <xsl:param name="BigMergeRow"/>
    <xsl:param name="lastCellColumnNumber"/>
    <xsl:param name="CheckIfBigMerge"/>
    <xsl:param name="this"/>

    <xsl:choose>

      <!-- Insert if this row is merged with another row -->
      <xsl:when test="contains($CheckIfBigMerge,'true')">
        <table:table-row table:style-name="ro1">
          <table:covered-table-cell table:number-columns-repeated="256"/>
        </table:table-row>
      </xsl:when>

      <xsl:otherwise>
        <table:table-row>
          <xsl:attribute name="table:style-name">
            <xsl:choose>
              <xsl:when test="@ht">
                <xsl:value-of select="generate-id(.)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="generate-id(key('SheetFormatPr', ''))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>

          <xsl:if test="@hidden=1">
            <xsl:attribute name="table:visibility">
              <xsl:text>collapse</xsl:text>
            </xsl:attribute>
          </xsl:if>


          <!-- Insert First Cell in Row  -->
          <xsl:if test="$CheckIfBigMerge = ''">
            <xsl:apply-templates select="e:c[1]">
              <xsl:with-param name="BigMergeCell">
                <xsl:value-of select="$BigMergeCell"/>
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:if>

          <xsl:variable name="CheckIfBigMergeAfter">
            <xsl:call-template name="CheckIfBigMergeAfter">
              <xsl:with-param name="colNum">
                <xsl:value-of select="$lastCellColumnNumber"/>
              </xsl:with-param>
              <xsl:with-param name="rowNum">1</xsl:with-param>
              <xsl:with-param name="BigMergeCell">
                <xsl:value-of select="$BigMergeCell"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:variable>

          <!-- complete row with empty cells if last cell number < 256 -->
          <xsl:choose>
            <xsl:when
              test="$lastCellColumnNumber &lt; 256 and $CheckIfBigMerge = '' and $CheckIfBigMergeAfter != 'true'">
              <table:table-cell table:number-columns-repeated="{256 - $lastCellColumnNumber}">
                <!-- if there is a default cell style for the row -->
                <xsl:if test="@s">
                  <xsl:attribute name="table:style-name">
                    <xsl:for-each select="document('xl/styles.xml')">
                      <xsl:value-of select="generate-id(key('Xf', '')[position() = $this/@s + 1])"/>
                    </xsl:for-each>
                  </xsl:attribute>
                </xsl:if>
              </table:table-cell>
            </xsl:when>
            <xsl:when
              test="$lastCellColumnNumber &lt; 256 and $CheckIfBigMerge != '' and not(e:c)">
              <table:table-cell table:number-columns-repeated="{256 - $lastCellColumnNumber}">
                <!-- if there is a default cell style for the row -->
                <xsl:if test="@s">
                  <xsl:attribute name="table:style-name">
                    <xsl:for-each select="document('xl/styles.xml')">
                      <xsl:value-of select="generate-id(key('Xf', '')[position() = $this/@s + 1])"/>
                    </xsl:for-each>
                  </xsl:attribute>
                </xsl:if>
                <xsl:if test="$CheckIfBigMerge != ''">
                  <xsl:attribute name="table:number-rows-spanned">
                    <xsl:choose>
                      <xsl:when test="number(substring-after($CheckIfBigMerge, ':')) &gt; 65536">
                        <xsl:value-of
                          select="65536 - number(substring-before($CheckIfBigMerge, ':')) + 1"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:choose>
                          <xsl:when
                            test="number(substring-after($CheckIfBigMerge, ':')) &gt; 256">
                            <xsl:value-of
                              select="256 - number(substring-before($CheckIfBigMerge, ':'))"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of
                              select="number(substring-after($CheckIfBigMerge, ':')) - number(substring-before($CheckIfBigMerge, ':')) + 1"
                            />
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:attribute>
                  <xsl:attribute name="table:number-columns-spanned">256</xsl:attribute>
                </xsl:if>
              </table:table-cell>
            </xsl:when>
            <xsl:when test="$lastCellColumnNumber &lt; 256 and $CheckIfBigMerge != ''">
              <xsl:apply-templates select="e:c[1]">
                <xsl:with-param name="BigMergeCell">
                  <xsl:value-of select="$BigMergeCell"/>
                </xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message terminate="no">translation.oox2odf.ColNumber</xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </table:table-row>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertEmptyCell">
    <xsl:param name="BeforeMerge"/>
    <xsl:param name="prevCellCol"/>
    <xsl:param name="BigMergeCell"/>
    <xsl:param name="this"/>
    <xsl:param name="colNum"/>
    <xsl:param name="rowNum"/>
    <xsl:param name="CheckIfMerge"/>

    <xsl:variable name="CheckIfBigMergeBefore">
      <xsl:call-template name="CheckIfBigMergeBefore">
        <xsl:with-param name="prevCellCol">
          <xsl:value-of select="$prevCellCol"/>
        </xsl:with-param>
        <xsl:with-param name="colNum">
          <xsl:value-of select="$colNum"/>
        </xsl:with-param>
        <xsl:with-param name="rowNum">
          <xsl:value-of select="$rowNum"/>
        </xsl:with-param>
        <xsl:with-param name="BigMergeCell">
          <xsl:value-of select="$BigMergeCell"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <!-- if there were empty cells in a row before this one then insert empty cells-->
    <xsl:choose>
      <!-- when this cell is the first one in a row but not in column A -->
      <xsl:when
        test="$prevCellCol = '' and $colNum>1 and $BeforeMerge != 'true' and $CheckIfBigMergeBefore != 'true'">
        <table:table-cell>
          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="$colNum - 1"/>
          </xsl:attribute>
          <!-- if there is a default cell style for the row -->
          <xsl:if test="parent::node()/@s">
            <xsl:variable name="position">
              <xsl:value-of select="$this/parent::node()/@s + 1"/>
            </xsl:variable>
            <xsl:attribute name="table:style-name">
              <xsl:for-each select="document('xl/styles.xml')">
                <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
              </xsl:for-each>
            </xsl:attribute>
          </xsl:if>
        </table:table-cell>
      </xsl:when>

      <!-- when this cell is not first one in a row and there were empty cells after previous non-empty cell -->
      <xsl:when test="$prevCellCol != '' ">

        <xsl:variable name="prevCellColNum">
          <xsl:choose>
            <!-- if previous column was specified by number -->
            <xsl:when test="$prevCellCol > -1">
              <xsl:value-of select="$prevCellCol"/>
            </xsl:when>
            <!-- if previous column was specified by prewious cell position (i.e. H4) -->
            <xsl:when test="$prevCellCol != ''">
              <xsl:call-template name="GetColNum">
                <xsl:with-param name="cell">
                  <xsl:value-of select="$prevCellCol"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <!-- if there wasn't previous cell-->
            <xsl:otherwise>-1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="$colNum>$prevCellColNum+1">
          <xsl:choose>
            <xsl:when test="$BigMergeCell = ''">
              <table:table-cell>
                <xsl:attribute name="table:number-columns-repeated">
                  <xsl:value-of select="$colNum - $prevCellColNum - 1"/>
                </xsl:attribute>
                <!-- if there is a default cell style for the row -->
                <xsl:if test="parent::node()/@s">
                  <xsl:variable name="position">
                    <xsl:value-of select="$this/parent::node()/@s + 1"/>
                  </xsl:variable>
                  <xsl:attribute name="table:style-name">
                    <xsl:for-each select="document('xl/styles.xml')">
                      <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
                    </xsl:for-each>
                  </xsl:attribute>
                </xsl:if>
              </table:table-cell>
            </xsl:when>
            <xsl:when test="$CheckIfBigMergeBefore = 'true'">
              <xsl:call-template name="InsertEmptyColumnsSheetNotEmpty">
                <xsl:with-param name="BigMergeCell">
                  <xsl:value-of select="$BigMergeCell"/>
                </xsl:with-param>
                <xsl:with-param name="prevCellCol">
                  <xsl:value-of select="$prevCellCol"/>
                </xsl:with-param>
                <xsl:with-param name="colNum">
                  <xsl:value-of select="$colNum"/>
                </xsl:with-param>
                <xsl:with-param name="rowNum">
                  <xsl:value-of select="$rowNum"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$colNum - $prevCellCol -1 &gt; 0">
              <table:table-cell>
                <xsl:attribute name="table:number-columns-repeated">
                  <xsl:value-of select="$colNum - $prevCellCol - 1"/>
                </xsl:attribute>
                <!-- if there is a default cell style for the row -->
                <xsl:if test="parent::node()/@s">
                  <xsl:variable name="position">
                    <xsl:value-of select="$this/parent::node()/@s + 1"/>
                  </xsl:variable>
                  <xsl:attribute name="table:style-name">
                    <xsl:for-each select="document('xl/styles.xml')">
                      <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
                    </xsl:for-each>
                  </xsl:attribute>
                </xsl:if>
              </table:table-cell>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$CheckIfBigMergeBefore = 'true'">
        <xsl:call-template name="InsertEmptyColumnsSheetNotEmpty">
          <xsl:with-param name="BigMergeCell">
            <xsl:value-of select="$BigMergeCell"/>
          </xsl:with-param>
          <xsl:with-param name="prevCellCol">
            <xsl:value-of select="$prevCellCol"/>
          </xsl:with-param>
          <xsl:with-param name="colNum">
            <xsl:value-of select="$colNum"/>
          </xsl:with-param>
          <xsl:with-param name="rowNum">
            <xsl:value-of select="$rowNum"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise> </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertThisCell">
    <xsl:param name="BeforeMerge"/>
    <xsl:param name="prevCellCol"/>
    <xsl:param name="BigMergeCell"/>
    <xsl:param name="this"/>
    <xsl:param name="colNum"/>
    <xsl:param name="rowNum"/>
    <xsl:param name="CheckIfMerge"/>
    
    <xsl:choose>
      
      <!-- Insert covered cell if this is Merge Cell -->
      <xsl:when test="contains($CheckIfMerge,'true')">
        <xsl:choose>
          <xsl:when test="number(substring-after($CheckIfMerge, ':')) &gt; 1">
            <table:covered-table-cell>
              <xsl:attribute name="table:number-columns-repeated">
                <xsl:choose>
                  <xsl:when
                    test="$colNum + number(substring-after($CheckIfMerge, ':')) &gt; 256">
                    <xsl:value-of select="256 - $colNum"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <!--xsl:value-of select="number(substring-after($CheckIfMerge, ':')) - 1"/-->
                    <xsl:value-of select="number(substring-after($CheckIfMerge, ':')) - 1"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </table:covered-table-cell>
          </xsl:when>
          <xsl:otherwise>
            <table:covered-table-cell/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      
      <xsl:otherwise>
        <!-- insert this one cell-->
        <table:table-cell>
          <xsl:variable name="position">
            <xsl:value-of select="$this/@s + 1"/>
          </xsl:variable>
          <!-- Insert "Merge Cell" if "Merge Cell" is starting in this cell -->
          <xsl:if test="$CheckIfMerge != 'false'">
            <xsl:attribute name="table:number-rows-spanned">
              <xsl:choose>
                <xsl:when test="number(substring-before($CheckIfMerge, ':')) &gt; 65536">65536</xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="substring-before($CheckIfMerge, ':')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="table:number-columns-spanned">
              <xsl:choose>
                <xsl:when test="$colNum + number(substring-after($CheckIfMerge, ':')) &gt; 256">
                  <xsl:value-of select="256 - $colNum + 1"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="substring-after($CheckIfMerge, ':')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@s">
            <xsl:attribute name="table:style-name">
              <xsl:for-each select="document('xl/styles.xml')">
                <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
              </xsl:for-each>
            </xsl:attribute>
            <xsl:variable name="horizontal">
              <xsl:for-each select="document('xl/styles.xml')">
                <xsl:value-of select="key('Xf', '')[position() = $position]/e:alignment/@horizontal"
                />
              </xsl:for-each>
            </xsl:variable>
            <xsl:if test="$horizontal = 'centerContinuous' and e:v">
              <xsl:variable name="continous">
                <xsl:call-template name="CountContinuous"/>
              </xsl:variable>
              <xsl:attribute name="table:number-columns-spanned">
                <xsl:value-of select="$continous"/>
              </xsl:attribute>
              <xsl:attribute name="table:number-rows-spanned">
                <xsl:text>1</xsl:text>
              </xsl:attribute>
            </xsl:if>
          </xsl:if>
          <xsl:if test="e:v">
            <xsl:choose>
              <xsl:when test="@t='s' ">
                <xsl:attribute name="office:value-type">
                  <xsl:text>string</xsl:text>
                </xsl:attribute>
                <xsl:variable name="id">
                  <xsl:value-of select="e:v"/>
                </xsl:variable>
                <text:p>
                  <!-- a postprocessor puts here strings from sharedstrings -->
                  <pxsi:v xmlns:pxsi="urn:cleverage:xmlns:post-processings:shared-strings">
                    <xsl:value-of select="e:v"/>
                  </pxsi:v>
                </text:p>
              </xsl:when>
              <xsl:when test="@t = 'e' ">
                <xsl:attribute name="office:value-type">
                  <xsl:text>string</xsl:text>
                </xsl:attribute>
                <text:p>
                  <xsl:value-of select="e:v"/>
                </text:p>
              </xsl:when>
              <xsl:when test="@t = 'str' ">
                <xsl:attribute name="office:value-type">
                  <xsl:choose>
                    <xsl:when test="number(e:v)">
                      <xsl:text>float</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>string</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <text:p>
                  <xsl:choose>
                    <xsl:when test="number(e:v)">
                      <xsl:call-template name="FormatNumber">
                        <xsl:with-param name="value">
                          <xsl:value-of select="e:v"/>
                        </xsl:with-param>
                        <xsl:with-param name="numStyle">
                          <xsl:for-each select="document('xl/styles.xml')">
                            <xsl:value-of
                              select="key('numFmtId',key('Xf','')[position()=$position]/@numFmtId)/@formatCode"
                            />
                          </xsl:for-each>
                        </xsl:with-param>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="e:v"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </text:p>
              </xsl:when>
              <xsl:when test="@t = 'n'">
                <xsl:attribute name="office:value-type">
                  <xsl:text>float</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="office:value">
                  <xsl:value-of select="e:v"/>
                </xsl:attribute>
                <text:p>
                  <xsl:call-template name="FormatNumber">
                    <xsl:with-param name="value">
                      <xsl:value-of select="e:v"/>
                    </xsl:with-param>
                    <xsl:with-param name="numStyle">
                      <xsl:for-each select="document('xl/styles.xml')">
                        <xsl:value-of
                          select="key('numFmtId',key('Xf','')[position()=$position]/@numFmtId)/@formatCode"
                        />
                      </xsl:for-each>
                    </xsl:with-param>
                  </xsl:call-template>
                </text:p>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="numStyle">
                  <xsl:for-each select="document('xl/styles.xml')">
                    <xsl:value-of
                      select="key('numFmtId',key('Xf','')[position()=$position]/@numFmtId)/@formatCode"
                    />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="numId">
                  <xsl:for-each select="document('xl/styles.xml')">
                    <xsl:value-of
                      select="key('Xf','')[position()=$position]/@numFmtId"
                    />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="office:value-type">
                  <xsl:choose>
                    <xsl:when test="contains($numStyle,'%') or ((not($numStyle) or $numStyle = '')  and ($numId = 9 or $numId = 10))">
                      <xsl:text>percentage</xsl:text>
                    </xsl:when>
                    <xsl:when test="contains($numStyle,'zł') or contains($numStyle,'[$')">
                      <xsl:text>currency</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>float</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <xsl:attribute name="office:value">
                  <xsl:value-of select="e:v"/>
                </xsl:attribute>
                <text:p>
                  <xsl:call-template name="FormatNumber">
                    <xsl:with-param name="value">
                      <xsl:value-of select="e:v"/>
                    </xsl:with-param>
                    <xsl:with-param name="numStyle">
                      <xsl:value-of select="$numStyle"/>
                    </xsl:with-param>
                    <xsl:with-param name="numId">
                      <xsl:value-of select="$numId"/>
                    </xsl:with-param>
                  </xsl:call-template>
                </text:p>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </table:table-cell>
        
        <!-- Insert covered cell if Merge Cell is starting-->
        <xsl:choose>
          <xsl:when
            test="$CheckIfMerge != 'false' and substring-after($CheckIfMerge, ':') &gt; 1">
            <table:covered-table-cell>
              <xsl:attribute name="table:number-columns-repeated">
                <xsl:choose>
                  <xsl:when test="number(substring-after($CheckIfMerge, ':')) &gt; 256">256</xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="number(substring-after($CheckIfMerge, ':')) - 1"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
            </table:covered-table-cell>
          </xsl:when>
          <!-- when cell had 'centerContinuous' horizontal alignment -->
          <xsl:when test="@s and e:v">
            <xsl:variable name="position">
              <xsl:value-of select="$this/@s + 1"/>
            </xsl:variable>
            <xsl:variable name="horizontal">
              <xsl:for-each select="document('xl/styles.xml')">
                <xsl:value-of select="key('Xf', '')[position() = $position]/e:alignment/@horizontal"
                />
              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="continuous">
              <xsl:call-template name="CountContinuous"/>
            </xsl:variable>
            <xsl:if test="$horizontal = 'centerContinuous' ">
              <table:covered-table-cell>
                <xsl:attribute name="table:number-columns-repeated">
                  <xsl:value-of select="$continuous - 1"/>
                </xsl:attribute>
                <xsl:attribute name="table:style-name">
                  <xsl:for-each select="document('xl/styles.xml')">
                    <xsl:value-of select="generate-id(key('Xf', '')[position() = 1])"/>
                  </xsl:for-each>
                </xsl:attribute>
              </table:covered-table-cell>
            </xsl:if>
          </xsl:when>
        </xsl:choose>
        
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <xsl:template name="InsertNextCell">
    <xsl:param name="BeforeMerge"/>
    <xsl:param name="prevCellCol"/>
    <xsl:param name="BigMergeCell"/>
    <xsl:param name="this"/>
    <xsl:param name="colNum"/>
    <xsl:param name="rowNum"/>
    <xsl:param name="CheckIfMerge"/>


    <xsl:variable name="CheckIfBigMergeBefore">
      <xsl:call-template name="CheckIfBigMergeBefore">
        <xsl:with-param name="prevCellCol">
          <xsl:value-of select="$prevCellCol"/>
        </xsl:with-param>
        <xsl:with-param name="colNum">
          <xsl:value-of select="$colNum"/>
        </xsl:with-param>
        <xsl:with-param name="rowNum">
          <xsl:value-of select="$rowNum"/>
        </xsl:with-param>
        <xsl:with-param name="BigMergeCell">
          <xsl:value-of select="$BigMergeCell"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="CheckIfBigMergeAfter">
      <xsl:call-template name="CheckIfBigMergeAfter">
        <xsl:with-param name="colNum">
          <xsl:value-of select="$colNum"/>
        </xsl:with-param>
        <xsl:with-param name="rowNum">
          <xsl:value-of select="$rowNum"/>
        </xsl:with-param>
        <xsl:with-param name="BigMergeCell">
          <xsl:value-of select="$BigMergeCell"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>


    <xsl:variable name="countContinuous">
      <xsl:choose>
        <xsl:when test="@s and e:v">
          <xsl:variable name="position">
            <xsl:value-of select="$this/@s + 1"/>
          </xsl:variable>
          <xsl:variable name="horizontal">
            <xsl:for-each select="document('xl/styles.xml')">
              <xsl:value-of select="key('Xf', '')[position() = $position]/e:alignment/@horizontal"/>
            </xsl:for-each>
          </xsl:variable>
          
          <xsl:choose>
            <xsl:when test="$horizontal = 'centerContinuous' ">
              <xsl:call-template name="CountContinuous"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>0</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>0</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>

      <!-- calc supports only 256 columns -->
      <xsl:when test="$colNum &gt; 255">
        <xsl:message terminate="no">translation.oox2odf.ColNumber</xsl:message>
      </xsl:when>

      <!-- Skips empty coll (in Merge Cell) -->

      <xsl:when test="$CheckIfMerge != 'false' and following-sibling::e:c">
        <xsl:choose>
          <!-- if in this cell big merge coll is starting -->
          <xsl:when test="$CheckIfBigMergeBefore = 'start' and following-sibling::e:c">
            <xsl:apply-templates select="following-sibling::e:c[1]">
              <xsl:with-param name="BeforeMerge">
                <xsl:text>true</xsl:text>
              </xsl:with-param>
              <xsl:with-param name="prevCellCol">
                <xsl:value-of select="$colNum + number(substring-after($CheckIfMerge, ':')) - 1"/>
              </xsl:with-param>
              <xsl:with-param name="BigMergeCell">
                <xsl:value-of select="$BigMergeCell"/>
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
          <!-- if this cell is inside row of merged cells ($CheckIfMerged is true:number_of_cols_spaned) -->
          <xsl:when
            test="contains($CheckIfMerge,'true') and substring-after($CheckIfMerge, ':') &gt; 1">
            <xsl:if test="following-sibling::e:c[number(substring-after($CheckIfMerge, ':')) - 1]">
              <xsl:apply-templates
                select="following-sibling::e:c[number(substring-after($CheckIfMerge, ':')) - 1]">
                <xsl:with-param name="BeforeMerge">
                  <xsl:text>true</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="prevCellCol">
                  <xsl:value-of select="$colNum + number(substring-after($CheckIfMerge, ':')) - 1"/>
                </xsl:with-param>
                <xsl:with-param name="BigMergeCell">
                  <xsl:value-of select="$BigMergeCell"/>
                </xsl:with-param>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <!-- if this cell starts row of merged cells ($CheckIfMerged has dimensions of merged cell) -->
          <xsl:otherwise>

            <xsl:if test="following-sibling::e:c[number(substring-after($CheckIfMerge, ':'))]">
              <xsl:apply-templates
                select="following-sibling::e:c[number(substring-after($CheckIfMerge, ':'))]">
                <xsl:with-param name="BeforeMerge">
                  <xsl:text>true</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="prevCellCol">
                  <xsl:value-of select="$colNum + number(substring-after($CheckIfMerge, ':')) - 1"/>
                </xsl:with-param>
                <xsl:with-param name="BigMergeCell">
                  <xsl:value-of select="$BigMergeCell"/>
                </xsl:with-param>
              </xsl:apply-templates>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Insert Empty Big Merge Coll after this cell -->
      <xsl:when test="not(following-sibling::e:c) and $CheckIfBigMergeAfter = 'true'">
        <xsl:call-template name="InsertEmptyColumnsSheetNotEmpty">
          <xsl:with-param name="BigMergeCell">
            <xsl:value-of select="$BigMergeCell"/>
          </xsl:with-param>
          <xsl:with-param name="prevCellCol">
            <xsl:value-of select="$colNum"/>
          </xsl:with-param>
          <xsl:with-param name="colNum">256</xsl:with-param>
          <xsl:with-param name="rowNum">
            <xsl:value-of select="$rowNum"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <!-- skip merged cells when horizontal alignment = 'centerContinuous' -->
      <xsl:when test="$countContinuous != 0">
        <xsl:if test="following-sibling::e:c[$countContinuous]">
          <xsl:apply-templates select="following-sibling::e:c[position() = $countContinuous]">
            <xsl:with-param name="BeforeMerge">
              <xsl:text>true</xsl:text>
            </xsl:with-param>
            <xsl:with-param name="prevCellCol">
              <xsl:value-of select="$colNum + $countContinuous - 1"/>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="following-sibling::e:c">
          <xsl:apply-templates select="following-sibling::e:c[1]">
            <xsl:with-param name="prevCellCol">
              <xsl:call-template name="GetColNum">
                <xsl:with-param name="cell">
                  <xsl:value-of select="@r"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:with-param>
            <xsl:with-param name="BigMergeCell">
              <xsl:value-of select="$BigMergeCell"/>
            </xsl:with-param>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--  convert multiple white spaces  -->
  <xsl:template name="InsertWhiteSpaces">
    <xsl:param name="string" select="."/>
    <xsl:param name="length" select="string-length(.)"/>
    <!-- string which doesn't contain whitespaces-->
    <xsl:choose>
      <xsl:when test="not(contains($string,' '))">
        <xsl:value-of select="$string"/>
      </xsl:when>
      <!-- convert white spaces  -->
      <xsl:otherwise>
        <xsl:variable name="before">
          <xsl:value-of select="substring-before($string,' ')"/>
        </xsl:variable>
        <xsl:variable name="after">
          <xsl:call-template name="CutStartSpaces">
            <xsl:with-param name="cuted">
              <xsl:value-of select="substring-after($string,' ')"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$before != '' ">
          <xsl:value-of select="concat($before,' ')"/>
        </xsl:if>
        <!--add remaining whitespaces as text:s if there are any-->
        <xsl:if test="string-length(concat($before,' ', $after)) &lt; $length ">
          <xsl:choose>
            <xsl:when test="($length - string-length(concat($before, $after))) = 1">
              <text:s/>
            </xsl:when>
            <xsl:otherwise>
              <text:s>
                <xsl:attribute name="text:c">
                  <xsl:choose>
                    <xsl:when test="$before = ''">
                      <xsl:value-of select="$length - string-length($after)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$length - string-length(concat($before,' ', $after))"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
              </text:s>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        <!--repeat it for substring which has whitespaces-->
        <xsl:if test="contains($string,' ') and $length &gt; 0">
          <xsl:call-template name="InsertWhiteSpaces">
            <xsl:with-param name="string">
              <xsl:value-of select="$after"/>
            </xsl:with-param>
            <xsl:with-param name="length">
              <xsl:value-of select="string-length($after)"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--  cut start spaces -->
  <xsl:template name="CutStartSpaces">
    <xsl:param name="cuted"/>
    <xsl:choose>
      <xsl:when test="starts-with($cuted,' ')">
        <xsl:call-template name="CutStartSpaces">
          <xsl:with-param name="cuted">
            <xsl:value-of select="substring-after($cuted,' ')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$cuted"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertColumns">
    <xsl:param name="sheet"/>

    <xsl:variable name="DefaultCellStyleName">
      <xsl:for-each select="document('xl/styles.xml')">
        <xsl:value-of select="generate-id(key('Xf', '')[1])"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:for-each select="document(concat('xl/',$sheet))/e:worksheet/e:cols">
      <xsl:apply-templates select="e:col[1]">
        <xsl:with-param name="number">1</xsl:with-param>
        <xsl:with-param name="sheet" select="$sheet"/>
        <xsl:with-param name="DefaultCellStyleName" select="$DefaultCellStyleName"/>
      </xsl:apply-templates>
    </xsl:for-each>

    <!-- apply default column style for last columns which style wasn't changed -->
    <xsl:for-each select="document(concat('xl/',$sheet))">
      <xsl:choose>
        <xsl:when test="not(key('Col', ''))">
          <table:table-column table:style-name="{generate-id(key('SheetFormatPr', ''))}"
            table:number-columns-repeated="256">
            <xsl:attribute name="table:default-cell-style-name">
              <xsl:value-of select="$DefaultCellStyleName"/>
            </xsl:attribute>
          </table:table-column>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="key('Col', '')[last()]/@max &lt; 256">
            <table:table-column table:style-name="{generate-id(key('SheetFormatPr', ''))}"
              table:number-columns-repeated="{256 - key('Col', '')[last()]/@max}">
              <xsl:attribute name="table:default-cell-style-name">
                <xsl:value-of select="$DefaultCellStyleName"/>
              </xsl:attribute>
            </table:table-column>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertColumnStyle">
    <xsl:param name="number"/>
    <xsl:param name="sheet"/>
    <xsl:param name="DefaultCellStyleName"/>
    <xsl:param name="this"/>

    <!-- if there were columns with default properties before this column then insert default columns-->
    <xsl:choose>
      <!-- when this column is the first non-default one but it's not the column A -->
      <xsl:when test="$number=1 and @min>1">

        <table:table-column>
          <xsl:attribute name="table:style-name">
            <xsl:for-each select="document(concat('xl/',$sheet))">
              <xsl:value-of select="generate-id(key('SheetFormatPr', ''))"/>
            </xsl:for-each>
          </xsl:attribute>

          <xsl:attribute name="table:default-cell-style-name">
            <xsl:value-of select="$DefaultCellStyleName"/>
          </xsl:attribute>

          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="@min - 1"/>
          </xsl:attribute>

          <!-- Possible are nesesary code -->
          <!--xsl:if test="@style">            
            <xsl:variable name="position">
              <xsl:value-of select="$this/@style + 1"/>
            </xsl:variable>
            
            <xsl:attribute name="table:default-cell-style-name">
              <xsl:for-each select="document('xl/styles.xml')">
                <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
              </xsl:for-each>
            </xsl:attribute>
            </xsl:if-->
          
        </table:table-column>

      </xsl:when>
      <!-- when this column is not first non-default one and there were default columns after previous non-default column (if there was a gap between this and previous column)-->
      <xsl:when test="preceding::e:col[1]/@max &lt; @min - 1">
        <table:table-column>

          <xsl:attribute name="table:style-name">
            <xsl:for-each select="document(concat('xl/',$sheet))">
              <xsl:value-of select="generate-id(key('SheetFormatPr', ''))"/>
            </xsl:for-each>
          </xsl:attribute>

          <xsl:attribute name="table:number-columns-repeated">
            <xsl:value-of select="@min - preceding::e:col[1]/@max - 1"/>
          </xsl:attribute>

          <xsl:attribute name="table:default-cell-style-name">
            <xsl:value-of select="$DefaultCellStyleName"/>
          </xsl:attribute>

        </table:table-column>
      </xsl:when>
    </xsl:choose>

    <!-- insert this column -->
    <table:table-column table:style-name="{generate-id(.)}">
      <xsl:if test="not(@min = @max)">
        <xsl:attribute name="table:number-columns-repeated">
          <xsl:value-of select="@max - @min + 1"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="table:default-cell-style-name">
        <xsl:value-of select="$DefaultCellStyleName"/>
      </xsl:attribute>
      <xsl:if test="@hidden=1">
        <xsl:attribute name="table:visibility">
          <xsl:text>collapse</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@style">
        <xsl:variable name="position">
          <xsl:value-of select="$this/@style + 1"/>
        </xsl:variable>
        <xsl:attribute name="table:default-cell-style-name">
          <xsl:for-each select="document('xl/styles.xml')">
            <xsl:value-of select="generate-id(key('Xf', '')[position() = $position])"/>
          </xsl:for-each>
        </xsl:attribute>
      </xsl:if>
    </table:table-column>

    <!-- insert next column -->
    <xsl:choose>

      <!-- calc supports only 256 columns -->
      <xsl:when test="$number &gt; 255">
        <xsl:message terminate="no">translation.oox2odf.ColNumber</xsl:message>
      </xsl:when>

      <xsl:otherwise>
        <xsl:apply-templates select="following-sibling::e:col[1]">
          <xsl:with-param name="number">
            <xsl:value-of select="@max + 1"/>
          </xsl:with-param>
          <xsl:with-param name="sheet" select="$sheet"/>
          <xsl:with-param name="DefaultCellStyleName" select="$DefaultCellStyleName"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!-- template which inserts number in a correct format -->
  <xsl:template name="FormatNumber">
    <xsl:param name="value"/>
    <xsl:param name="numStyle"/>
    <xsl:param name="numId"/>
    <xsl:variable name="formatCode">
      <xsl:choose>
        <xsl:when test="contains($numStyle,';')">
          <xsl:value-of select="substring-before($numStyle,';')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$numStyle"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="outputValue">
    <xsl:choose>
      <xsl:when test="contains($value,'.') and $numStyle and $numStyle!=''">
        <xsl:call-template name="FormatAfterComma">
          <xsl:with-param name="valueAfterComma">
            <xsl:value-of select="substring-after($value,'.')"/>
          </xsl:with-param>
          <xsl:with-param name="valueBeforeComma">
            <xsl:value-of select="substring-before($value,'.')"/>
          </xsl:with-param>
          <xsl:with-param name="format">
            <xsl:choose>
              <xsl:when test="contains($formatCode,'_')">
                <xsl:value-of select="substring-before($formatCode,'_')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$formatCode"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($value,'.') and $numId = 10">
        <xsl:call-template name="FormatAfterComma">
          <xsl:with-param name="valueAfterComma">
            <xsl:value-of select="substring-after($value,'.')"/>
          </xsl:with-param>
          <xsl:with-param name="valueBeforeComma">
            <xsl:value-of select="substring-before($value,'.')"/>
          </xsl:with-param>
          <xsl:with-param name="format">0.00%</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$numId = 9">
        <xsl:value-of select="format-number($value,'0%')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      
      <!-- add '%' if it's percentage format-->
      <xsl:when test="contains($formatCode,'%') and not(contains($outputValue,'%'))">
        <xsl:value-of select="concat($outputValue,'%')"/>
      </xsl:when>
      
      <!-- add currency symbol if there is one-->
      <xsl:when test="contains($formatCode,'[$') or contains($formatCode,'zł')">
        <xsl:variable name="currency">
          <xsl:choose>
            <xsl:when test="contains($formatCode,'zł')">zł</xsl:when>
            <xsl:when test="contains($formatCode,'Red')">
              <xsl:variable name="tempFormat">
                <xsl:value-of select="substring-after(substring-before(substring-after($formatCode,'Red]'),']'),'[$')"/>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="contains($tempFormat,'-')">
                  <xsl:value-of select="substring-before($tempFormat,'-')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$tempFormat"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="tempFormat2">
              <xsl:value-of select="substring-after(substring-before($formatCode,']'),'[$')"/>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="contains($tempFormat2,'-')">
                  <xsl:value-of select="substring-before($tempFormat2,'-')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$tempFormat2"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="contains(substring-before($formatCode,$currency),'0') or contains(substring-before($formatCode,$currency),'#')">
            <xsl:value-of select="concat($outputValue,$currency)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($currency,$outputValue)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
        
      <xsl:otherwise>
        <xsl:value-of select="$outputValue"/>
      </xsl:otherwise>
      
    </xsl:choose>
  </xsl:template>

  <!-- formatting number after comma -->
  <xsl:template name="FormatAfterComma">
    <xsl:param name="valueAfterComma"/>
    <xsl:param name="valueBeforeComma"/>
    <xsl:param name="format"/>
    <xsl:variable name="plainFormat">
      <xsl:choose>
        <xsl:when test="contains(substring-after($format,'.'),'\')">
          <xsl:value-of select="substring-before($format,'\')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$format"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="not(contains($format,'.'))">
        <xsl:value-of select="$valueBeforeComma"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of
          select="concat($valueBeforeComma,format-number(concat('.',$valueAfterComma),concat('.',substring-after($plainFormat,'.'))))"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="CountContinuous">
    <xsl:param name="count" select="0"/>
    
    <xsl:variable name="carryOn">
      <xsl:choose>
        <xsl:when test="following-sibling::e:c[1]/@s and not(following-sibling::e:c[1]/e:v)">
          <xsl:variable name="position">
            <xsl:value-of select="following-sibling::e:c[1]/@s + 1"/>
          </xsl:variable>
          <xsl:variable name="horizontal">
            <xsl:for-each select="document('xl/styles.xml')">
              <xsl:value-of select="key('Xf', '')[position() = $position]/e:alignment/@horizontal"/>
            </xsl:for-each>
          </xsl:variable>
          
          <xsl:choose>
            <xsl:when test="$horizontal = 'centerContinuous' ">
              <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>false</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>false</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>
      <xsl:when test="$carryOn = 'true'">
        <xsl:for-each select="following-sibling::e:c[1]">
          <xsl:call-template name="CountContinuous">
            <xsl:with-param name="count" select="$count + 1"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- number of following cells plus the starting one -->
        <xsl:value-of select="$count + 1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
