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
  xmlns:pzip="urn:cleverage:xmlns:post-processings:zip"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:e="http://schemas.openxmlformats.org/spreadsheetml/2006/main">

  <!-- @Filename: chart.xsl -->
  <!-- @Description: This stylesheet is used for charts conversion -->
  <!-- @Created: 2007-05-24 -->

  <xsl:import href="relationships.xsl"/>

  <xsl:key name="dataSeries" match="c:ser" use="''"/>
  <xsl:key name="numPoints" match="c:numCache/c:ptCount" use="''"/>
  <xsl:key name="categories" match="c:cat" use="''"/>
  <xsl:key name="plotArea" match="c:plotArea" use="''"/>
  <xsl:key name="grouping" match="c:grouping" use="''"/>
  <xsl:key name="spPr" match="c:spPr" use="''"/>
  <xsl:key name="error" match="c:errBars" use="''"/>

  <xsl:template name="CreateObjectCharts">
    <!-- @Description: Searches for all charts within workbook and starts conversion. -->
    <!-- @Context: None -->

    <!-- get all sheet Id's -->
    <xsl:for-each select="document('xl/workbook.xml')/e:workbook/e:sheets/e:sheet">

      <xsl:variable name="sheet">
        <!-- path to sheet file from xl/ catalog (i.e. $sheet = worksheets/sheet1.xml) -->
        <xsl:call-template name="GetTarget">
          <xsl:with-param name="id">
            <xsl:value-of select="@r:id"/>
          </xsl:with-param>
          <xsl:with-param name="document">xl/workbook.xml</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>

      <!-- go to sheet file and search for drawing -->
      <xsl:for-each select="document(concat('xl/',$sheet))/e:worksheet/e:drawing">

        <xsl:variable name="drawing">
          <!-- path to drawing file from xl/ catalog (i.e. $drawing = ../drawings/drawing2.xml) -->
          <xsl:call-template name="GetTarget">
            <xsl:with-param name="id">
              <xsl:value-of select="@r:id"/>
            </xsl:with-param>
            <xsl:with-param name="document">
              <xsl:value-of select="concat('xl/',$sheet)"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>

        <!-- go to sheet drawing file and search for charts -->
        <xsl:for-each
          select="document(concat('xl/',substring-after($drawing,'/')))/xdr:wsDr/xdr:twoCellAnchor/xdr:graphicFrame/a:graphic/a:graphicData/c:chart">

          <xsl:variable name="chart">
            <!-- path to chart file from xl/ catalog (i.e. $chart = ../charts/chart1.xml) -->
            <xsl:call-template name="GetTarget">
              <xsl:with-param name="id">
                <xsl:value-of select="@r:id"/>
              </xsl:with-param>
              <xsl:with-param name="document">
                <xsl:value-of select="concat('xl/',substring-after($drawing,'/'))"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:variable>

          <xsl:variable name="chartId">
            <!-- unique chart identifier -->
            <xsl:value-of select="generate-id(.)"/>
          </xsl:variable>

          <!-- finally go to a chart file -->
          <xsl:for-each select="document(concat('xl/',substring-after($chart,'/')))">

            <xsl:call-template name="InsertChart">
              <xsl:with-param name="chartId" select="$chartId"/>
              <xsl:with-param name="inputChart">
                <xsl:value-of select="concat('xl/',substring-after($chart,'/'))"/>
              </xsl:with-param>
            </xsl:call-template>

          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="CreateSheetCharts">

    <xsl:for-each
      select="document('xl/_rels/workbook.xml.rels')//node()[name() = 'Relationship' and starts-with(@Target,'chartsheets/')]">

      <xsl:variable name="sheet">
        <xsl:value-of select="@Target"/>
      </xsl:variable>

      <!-- go to sheet file and search for drawing -->
      <xsl:for-each select="document(concat('xl/',$sheet))/e:chartsheet/e:drawing">

        <xsl:variable name="drawing">
          <!-- path to drawing file from xl/ catalog (i.e. $drawing = ../drawings/drawing2.xml) -->
          <xsl:call-template name="GetTarget">
            <xsl:with-param name="id">
              <xsl:value-of select="@r:id"/>
            </xsl:with-param>
            <xsl:with-param name="document">
              <xsl:value-of select="concat('xl/',$sheet)"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>

        <!-- go to sheet drawing file and search for charts -->
        <xsl:for-each
          select="document(concat('xl/',substring-after($drawing,'/')))/xdr:wsDr/xdr:absoluteAnchor/xdr:graphicFrame/a:graphic/a:graphicData/c:chart">

          <xsl:variable name="chart">
            <!-- path to chart file from xl/ catalog (i.e. $chart = ../charts/chart1.xml) -->
            <xsl:call-template name="GetTarget">
              <xsl:with-param name="id">
                <xsl:value-of select="@r:id"/>
              </xsl:with-param>
              <xsl:with-param name="document">
                <xsl:value-of select="concat('xl/',substring-after($drawing,'/'))"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:variable>

          <xsl:variable name="chartId">
            <!-- unique chart identifier -->
            <xsl:value-of select="generate-id(.)"/>
          </xsl:variable>

          <!-- finally go to a chart file -->
          <xsl:for-each select="document(concat('xl/',substring-after($chart,'/')))">

            <xsl:call-template name="InsertChart">
              <xsl:with-param name="chartId" select="$chartId"/>
              <xsl:with-param name="inputChart">
                <xsl:value-of select="concat('xl/',substring-after($chart,'/'))"/>
              </xsl:with-param>
            </xsl:call-template>

          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="InsertChart">
    <!-- @Description: Creates output chart files -->
    <!-- @Context: Input chart file root -->

    <xsl:param name="chartId"/>
    <!-- (string) unique chart identifier -->
    <xsl:param name="inputChart"/>
    <!-- (string) input chart file directory -->

    <xsl:call-template name="InsertChartContent">
      <xsl:with-param name="chartId" select="$chartId"/>
    </xsl:call-template>

    <xsl:call-template name="InsertChartStyles">
      <xsl:with-param name="chartId" select="$chartId"/>
      <xsl:with-param name="inputChart" select="$inputChart"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="InsertChartContent">
    <!-- @Description: Creates output chart content file -->
    <!-- @Context: Input chart file root -->

    <xsl:param name="chartId"/>
    <!-- (string) unique chart identifier -->

    <pzip:entry pzip:target="{concat('Object ',$chartId,'/content.xml')}">
      <office:document-content xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0">
        <office:automatic-styles>
          <number:number-style style:name="N0">
            <number:number number:min-integer-digits="1"/>
          </number:number-style>
          <xsl:call-template name="InsertChartProperties"/>
          <xsl:call-template name="InsertChartTitleProperties"/>
          <xsl:call-template name="InsertLegendProperties"/>
          <xsl:call-template name="InsertPlotAreaProperties"/>

          <xsl:choose>
            <!-- scatter chart has two value axes -->
            <xsl:when test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart">
              <xsl:for-each
                select="key('plotArea','')/c:valAx[c:axPos/@val = 'b' or c:axPos/@val = 't'][1]">
                <xsl:call-template name="InsertAxisXProperties">
                  <xsl:with-param name="type">
                    <xsl:text>valAx</xsl:text>
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="InsertAxisXTitleProperties"/>
                <xsl:call-template name="InsertMajorGridXProperties"/>
              </xsl:for-each>
              <xsl:for-each
                select="key('plotArea','')/c:valAx[c:axPos/@val = 'l' or c:axPos/@val = 'r'][1]">
                <xsl:call-template name="InsertAxisYProperties"/>
                <xsl:call-template name="InsertAxisYTitleProperties"/>
                <xsl:call-template name="InsertMajorGridYProperties"/>
              </xsl:for-each>
            </xsl:when>

            <xsl:otherwise>
              <xsl:for-each select="key('plotArea','')/c:catAx[1]">
                <xsl:call-template name="InsertAxisXProperties">
                  <xsl:with-param name="type">
                    <xsl:text>catAx</xsl:text>
                  </xsl:with-param>
                </xsl:call-template>
                <xsl:call-template name="InsertAxisXTitleProperties"/>
                <xsl:call-template name="InsertMajorGridXProperties"/>
              </xsl:for-each>
              <xsl:for-each select="key('plotArea','')/c:valAx[1]">
                <xsl:call-template name="InsertAxisYProperties"/>
                <xsl:call-template name="InsertAxisYTitleProperties"/>
                <xsl:call-template name="InsertMajorGridYProperties"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:call-template name="InsertSeriesProperties"/>
          <xsl:call-template name="InsertErrorProperties"/>
          <xsl:call-template name="InsertWallProperties"/>
          <xsl:call-template name="InsertFloorProperties"/>
        </office:automatic-styles>
        <office:body>
          <office:chart>
            <xsl:call-template name="InsertChartType"/>
          </office:chart>
        </office:body>
      </office:document-content>

    </pzip:entry>
  </xsl:template>

  <xsl:template name="InsertChartStyles">
    <!-- @Description: Creates output chart styles file -->
    <!-- @Context: Input chart file root -->

    <xsl:param name="chartId"/>
    <!-- unique chart identifier -->
    <xsl:param name="inputChart"/>
    <!-- input chart file directory -->

    <pzip:entry pzip:target="{concat('Object ',$chartId,'/styles.xml')}">
      <office:document-styles>
        <office:styles>
          <xsl:call-template name="InsertDrawFillImage">
            <xsl:with-param name="chartId" select="$chartId"/>
            <xsl:with-param name="inputChart" select="$inputChart"/>
          </xsl:call-template>
        </office:styles>
      </office:document-styles>
    </pzip:entry>
  </xsl:template>

  <xsl:template name="InsertDataSeries">
    <!-- @Description: Outputs chart data series  -->
    <!-- @Context: inside input chart file -->

    <xsl:for-each select="key('dataSeries','')">
      <!-- TO DO chart:style-name -->
      <chart:series chart:style-name="{concat('series',position())}">
        <xsl:if
          test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart and position() = 1">
          <chart:domain/>
        </xsl:if>

        <!-- error indicator -->
        <xsl:for-each select="c:errBars">
          <xsl:if test="c:errValType/@val != 'stdErr' and c:errValType/@val != 'stdDev' ">
            <chart:error-indicator chart:style-name="{concat('error',generate-id(.))}"/>
          </xsl:if>
        </xsl:for-each>

        <chart:data-point>
          <xsl:attribute name="chart:repeated">
            <xsl:value-of select="key('numPoints','')/@val"/>
          </xsl:attribute>
        </chart:data-point>
      </chart:series>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertChartTable">
    <!-- @Description: Outputs chart data table containing visualized values  -->
    <!-- @Context: inside input chart file -->

    <xsl:variable name="reverseSeries">
      <xsl:for-each select="c:chartSpace/c:chart/c:plotArea">
        <xsl:choose>
          <xsl:when
            test="(c:barChart/c:barDir/@val = 'bar' and c:barChart/c:grouping/@val = 'clustered' )  or c:areaChart/c:grouping/@val = 'standard' ">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="reverseCategories">
      <xsl:for-each select="c:chartSpace/c:chart/c:plotArea">
        <xsl:choose>
          <xsl:when test="c:barChart/c:barDir/@val = 'bar' or c:pieChart or c:pie3DChart">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <table:table table:name="local-table">
      <table:table-header-columns>
        <table:table-column/>
      </table:table-header-columns>
      <table:table-columns>
        <table:table-column table:number-columns-repeated="3"/>
      </table:table-columns>

      <table:table-header-rows>
        <xsl:choose>

          <xsl:when test="$reverseSeries = 'true' ">
            <table:table-row>
              <table:table-cell>
                <text:p/>
              </table:table-cell>
              <xsl:for-each select="key('dataSeries','')[1]/parent::node()/c:ser[last()]">
                <xsl:call-template name="InsertHeaderRowsReverse"/>
              </xsl:for-each>
            </table:table-row>
          </xsl:when>

          <xsl:otherwise>
            <xsl:call-template name="InsertHeaderRows"/>
          </xsl:otherwise>
        </xsl:choose>
      </table:table-header-rows>

      <table:table-rows>
        <xsl:call-template name="InsertDataRows">
          <xsl:with-param name="points" select="key('numPoints','')/@val"/>
          <xsl:with-param name="categories" select="key('categories','')/descendant::c:ptCount/@val"/>
          <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
          <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
        </xsl:call-template>
      </table:table-rows>

    </table:table>
  </xsl:template>

  <xsl:template name="InsertHeaderRows">
    <!-- @Description: Outputs series names -->
    <!-- @Context: inside input chart file -->

    <table:table-row>
      <table:table-cell>
        <text:p/>
      </table:table-cell>

      <!-- insert cell responding to axis x values -->
      <xsl:if test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart">
        <table:table-cell>
          <text:p/>
        </table:table-cell>
      </xsl:if>

      <xsl:for-each select="key('dataSeries','')">
        <table:table-cell office:value-type="string">
          <text:p>
            <xsl:choose>
              <xsl:when test="c:tx/descendant::c:v">
                <xsl:value-of select="c:tx/descendant::c:v"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('Series',position())"/>
              </xsl:otherwise>
            </xsl:choose>
          </text:p>
        </table:table-cell>
      </xsl:for-each>
    </table:table-row>
  </xsl:template>

  <xsl:template name="InsertHeaderRowsReverse">
    <!-- @Description: Outputs series names -->
    <!-- @Context: last series node -->

    <xsl:param name="count" select="1"/>

    <table:table-cell office:value-type="string">
      <text:p>
        <xsl:choose>
          <xsl:when test="c:tx/descendant::c:v">
            <xsl:value-of select="c:tx/descendant::c:v"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('Series',key('numPoints','')/@val + 1 - $count)"/>
          </xsl:otherwise>
        </xsl:choose>
      </text:p>
    </table:table-cell>

    <xsl:if test="preceding-sibling::c:ser">
      <xsl:for-each select="preceding-sibling::c:ser[1]">
        <xsl:call-template name="InsertHeaderRowsReverse">
          <xsl:with-param name="count" select="$count + 1"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template name="InsertDataRows">
    <!-- @Description: Outputs chart data values -->
    <!-- @Context: inside input chart file -->

    <xsl:param name="points"/>
    <!-- (number) maximum number of data points in series -->
    <xsl:param name="categories"/>
    <!-- (number) number of categories -->
    <xsl:param name="count" select="0"/>
    <!-- (number) loop counter -->
    <xsl:param name="reverseCategories"/>
    <xsl:param name="reverseSeries"/>

    <xsl:variable name="categoryNumber">
      <xsl:choose>
        <xsl:when test="$reverseCategories = 'true' ">
          <xsl:value-of select="$points - $count - 1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$count"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$count &lt; $points">
        <table:table-row>
          <!--          <xsl:attribute name="zzzzz">
            <xsl:value-of select="concat('count: ',$count,'#points: ',$points,'#catNumber: ',$categoryNumber)"/>
          </xsl:attribute>-->
          <!-- category name -->
          <table:table-cell office:value-type="string">
            <text:p>
              <xsl:choose>
                <xsl:when test="not($categories)">
                  <xsl:value-of select="$categoryNumber + 1"/>
                </xsl:when>
                <xsl:when test="$count &lt; $categories">
                  <xsl:value-of
                    select="key('categories','')/descendant::c:pt[@idx= $categoryNumber]"/>
                </xsl:when>
              </xsl:choose>
            </text:p>
          </table:table-cell>

          <!-- insert cell responding to axis x value -->
          <xsl:if test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart">
            <xsl:for-each select="key('dataSeries','')[position() = 1]">
              <xsl:choose>
                <xsl:when test="c:xVal">
                  <table:table-cell office:value-type="float"
                    office:value="{c:xVal/c:numRef/c:numCache/c:pt[@idx = $categoryNumber]/c:v}">
                    <text:p>
                      <xsl:value-of
                        select="c:xVal/c:numRef/c:numCache/c:pt[@idx = $categoryNumber]/c:v"/>
                    </text:p>
                  </table:table-cell>
                </xsl:when>
                <xsl:otherwise>
                  <table:table-cell office:value-type="float" office:value="{$categoryNumber + 1}">
                    <text:p>
                      <xsl:value-of select="$categoryNumber + 1"/>
                    </text:p>
                  </table:table-cell>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:if>

          <!-- category values -->
          <xsl:choose>
            <xsl:when test="$reverseSeries = 'true' ">
              <xsl:call-template name="InsertValuesReverse">
                <xsl:with-param name="point" select="$categoryNumber"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertValues">
                <xsl:with-param name="point" select="$categoryNumber"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </table:table-row>

        <xsl:call-template name="InsertDataRows">
          <xsl:with-param name="points" select="$points"/>
          <xsl:with-param name="categories" select="$categories"/>
          <xsl:with-param name="count" select="$count + 1"/>
          <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
          <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertValues">
    <!-- @Description: Outputs chart data values for selected series -->
    <!-- @Context: inside input chart file -->

    <xsl:param name="point"/>
    <!-- (number) series number -->

    <xsl:for-each select="key('dataSeries','')">
      <xsl:choose>
        <xsl:when test="c:val/c:numRef/c:numCache/c:pt[@idx = $point]">
          <table:table-cell office:value-type="float"
            office:value="{c:val/c:numRef/c:numCache/c:pt[@idx = $point]/c:v}">
            <text:p>
              <xsl:value-of select="c:val/c:numRef/c:numCache/c:pt[@idx = $point]/c:v"/>
            </text:p>
          </table:table-cell>
        </xsl:when>
        <!-- values to scatter chart -->
        <xsl:when test="c:yVal/c:numRef/c:numCache/c:pt[@idx = $point]">
          <table:table-cell office:value-type="float"
            office:value="{c:yVal/c:numRef/c:numCache/c:pt[@idx = $point]/c:v}">
            <text:p>
              <xsl:value-of select="c:yVal/c:numRef/c:numCache/c:pt[@idx = $point]/c:v"/>
            </text:p>
          </table:table-cell>
        </xsl:when>
        <xsl:otherwise>
          <table:table-cell office:value-type="float" office:value="1.#NAN">
            <text:p>1.#NAN</text:p>
          </table:table-cell>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertValuesReverse">
    <!-- @Description: Outputs chart data values for selected series -->
    <!-- @Context: inside input chart file -->

    <xsl:param name="point"/>
    <!-- (number) series number -->
    <xsl:param name="count" select="0"/>

    <xsl:for-each select="key('dataSeries','')[last() - $count]">
      <xsl:choose>
        <xsl:when test="c:val/c:numRef/c:numCache/c:pt[@idx = $point]">
          <table:table-cell office:value-type="float"
            office:value="{c:val/c:numRef/c:numCache/c:pt[@idx = $point]/c:v}">
            <text:p>
              <xsl:value-of select="c:val/c:numRef/c:numCache/c:pt[@idx = $point]/c:v"/>
            </text:p>
          </table:table-cell>
        </xsl:when>
        <xsl:otherwise>
          <table:table-cell office:value-type="float" office:value="1.#NAN">
            <text:p>1.#NAN</text:p>
          </table:table-cell>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>

    <xsl:if test="key('dataSeries','')[last() - $count - 1]">
      <xsl:call-template name="InsertValuesReverse">
        <xsl:with-param name="point" select="$point"/>
        <xsl:with-param name="count" select="$count + 1"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="InsertTitle">
    <!-- @Description: Outputs chart title -->
    <!-- @Context: input chart file root -->

    <xsl:choose>
      <!-- title is set by user -->
      <xsl:when test="c:chartSpace/c:chart/c:title/c:tx">
        <chart:title svg:x="3.834cm" svg:y="0.184cm" chart:style-name="chart_title">
          <text:p>
            <xsl:for-each select="c:chartSpace/c:chart/c:title/c:tx/c:rich/a:p">
              <!-- [ENTER] -->
              <xsl:if test="preceding-sibling::node()[1][name() = 'a:p']">
                <xsl:value-of select="'&#xD;&#xA;'"/>
              </xsl:if>

              <xsl:for-each select="a:r">
                <xsl:value-of select="a:t"/>
              </xsl:for-each>
            </xsl:for-each>
          </text:p>
        </chart:title>
      </xsl:when>

      <!-- one series chart default title is first series name -->
      <xsl:when
        test="c:chartSpace/c:chart/c:title and count(key('dataSeries','')) = 1 and key('dataSeries','')/c:tx/descendant::c:v[1]">
        <xsl:for-each select="key('dataSeries','')/c:tx/descendant::c:v[1]">
          <chart:title svg:x="3.834cm" svg:y="0.184cm" chart:style-name="chart_title">
            <text:p>
              <xsl:value-of select="text()"/>
            </text:p>
          </chart:title>
        </xsl:for-each>
      </xsl:when>

      <xsl:when test="c:chartSpace/c:chart/c:title">
        <chart:title svg:x="3cm" svg:y="0.14cm" chart:style-name="chart_title">
          <text:p>
            <xsl:text>Chart Title</xsl:text>
          </text:p>
        </chart:title>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertLegend">
    <!-- @Description: Outputs chart legend -->
    <!-- @Context: input chart file root -->

    <xsl:for-each select="c:chartSpace/c:chart/c:legend">
      <chart:legend chart:legend-position="end" svg:x="11.251cm" svg:y="4.188cm"
        chart:style-name="legend">
        <!-- legend position -->
        <xsl:if test="c:legendPos/@val != '' ">
          <xsl:attribute name="chart:legend-position">
            <xsl:choose>
              <xsl:when test="c:legendPos/@val = 't' ">
                <xsl:text>top</xsl:text>
              </xsl:when>
              <xsl:when test="c:legendPos/@val = 'b' ">
                <xsl:text>bottom</xsl:text>
              </xsl:when>
              <xsl:when test="c:legendPos/@val = 'l' ">
                <xsl:text>start</xsl:text>
              </xsl:when>
              <xsl:when test="c:legendPos/@val = 'r' ">
                <xsl:text>end</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </xsl:if>
      </chart:legend>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertXAxis">
    <!-- @Description: Outputs chart X Axis -->
    <!-- @Context: inside input chart file -->
    <xsl:param name="type"/>

    <chart:axis chart:dimension="x" chart:name="primary-x" chart:style-name="axis-x">

      <xsl:choose>
        <!-- title is set by user -->
        <xsl:when test="c:title/c:tx">
          <chart:title chart:style-name="axis-x_title">
            <text:p>
              <xsl:for-each select="c:title/c:tx/c:rich/a:p">
                <!-- [ENTER] -->
                <xsl:if test="preceding-sibling::node()[1][name() = 'a:p']">
                  <xsl:value-of select="'&#xD;&#xA;'"/>
                </xsl:if>

                <xsl:for-each select="a:r">
                  <xsl:value-of select="a:t"/>
                </xsl:for-each>
              </xsl:for-each>

            </text:p>
          </chart:title>
        </xsl:when>

        <!-- default Axis-X title -->
        <xsl:when test="c:title">
          <chart:title chart:style-name="axis-x_title">
            <text:p>
              <xsl:text>Axis Title</xsl:text>
            </text:p>
          </chart:title>
        </xsl:when>
      </xsl:choose>

      <xsl:if test="c:majorGridlines/c:spPr and $type = 'valAx' ">
        <chart:grid chart:style-name="majorGridX" chart:class="major"/>
      </xsl:if>

      <chart:categories>
        <xsl:attribute name="table:cell-range-address">
          <xsl:value-of select="concat('local-table.A2:.A',1 + key('numPoints','')/@val)"/>
        </xsl:attribute>
      </chart:categories>
    </chart:axis>

  </xsl:template>

  <xsl:template name="InsertYAxis">
    <!-- @Description: Outputs chart X Axis -->
    <!-- @Context: inside input chart file -->

    <chart:axis chart:dimension="y" chart:name="primary-y" chart:style-name="axis-y">

      <xsl:choose>
        <!-- title is set by user -->
        <xsl:when test="c:title/c:tx">
          <chart:title chart:style-name="axis-y_title">
            <text:p>
              <xsl:for-each select="c:title/c:tx/c:rich/a:p">
                <!-- [ENTER] -->
                <xsl:if test="preceding-sibling::node()[1][name() = 'a:p']">
                  <xsl:value-of select="'&#xD;&#xA;'"/>
                </xsl:if>

                <xsl:for-each select="a:r">
                  <xsl:value-of select="a:t"/>
                </xsl:for-each>
              </xsl:for-each>

            </text:p>
          </chart:title>
        </xsl:when>

        <xsl:when test="c:title">
          <chart:title chart:style-name="axis-y_title">
            <text:p>
              <xsl:text>Axis Title</xsl:text>
            </text:p>
          </chart:title>
        </xsl:when>
      </xsl:choose>

      <xsl:if test="c:majorGridlines">
        <chart:grid chart:style-name="majorGridY" chart:class="major"/>
      </xsl:if>

    </chart:axis>

  </xsl:template>

  <xsl:template name="InsertChartType">
    <!-- @Description: Inserts desired type of chart -->
    <!-- @Context: input chart file root -->

    <chart:chart svg:width="13.066cm" svg:height="9.279cm" chart:class="chart:bar"
      chart:style-name="chart">

      <xsl:attribute name="chart:class">
        <xsl:choose>
          <xsl:when test="key('plotArea','')/c:barChart or key('plotArea','')/c:bar3DChart">
            <xsl:text>chart:bar</xsl:text>
          </xsl:when>

          <xsl:when test="key('plotArea','')/c:lineChart or key('plotArea','')/c:line3DChart">
            <xsl:text>chart:line</xsl:text>
          </xsl:when>

          <xsl:when test="key('plotArea','')/c:areaChart or key('plotArea','')/c:area3DChart">
            <xsl:text>chart:area</xsl:text>
          </xsl:when>

          <!--  or key('plotArea','')/c:ofPieChart or key('plotArea','')/c:doughnutChart -->
          <xsl:when test="key('plotArea','')/c:pieChart or key('plotArea','')/c:pie3DChart">
            <xsl:text>chart:circle</xsl:text>
          </xsl:when>

          <xsl:when test="key('plotArea','')/c:radarChart">
            <xsl:text>chart:radar</xsl:text>
          </xsl:when>

          <xsl:when test="key('plotArea','')/c:doughnutChart">
            <xsl:text>chart:ring</xsl:text>
          </xsl:when>

          <!-- making problems at this time -->
          <xsl:when test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart">
            <xsl:text>chart:scatter</xsl:text>
          </xsl:when>
          <!--
            
            <xsl:when test="key('plotArea','')/c:stockChart">
            <xsl:text>chart:stock<xsl:text>
            </xsl:when>
            
            SURFACE ???
-->
          <xsl:otherwise>
            <xsl:text>chart:bar</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>

      <xsl:call-template name="InsertTitle"/>
      <xsl:call-template name="InsertLegend"/>

      <chart:plot-area chart:style-name="plot_area" table:cell-range-address="Sheet1.$D$3:.$F$3"
        chart:table-number-list="0" svg:x="0.26cm" svg:y="2.087cm" svg:width="10.472cm"
        svg:height="7.008cm">

        <!-- Axes -->
        <xsl:choose>
          <!-- scatter chart has two value axes -->
          <xsl:when test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart">
            <xsl:for-each
              select="key('plotArea','')/c:valAx[c:axPos/@val = 'b' or c:axPos/@val = 't'][1]">
              <xsl:call-template name="InsertXAxis"/>
            </xsl:for-each>
            <xsl:for-each
              select="key('plotArea','')/c:valAx[c:axPos/@val = 'l' or c:axPos/@val = 'r'][1]">
              <xsl:call-template name="InsertYAxis"/>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="key('plotArea','')/c:catAx[1]">
              <xsl:call-template name="InsertXAxis"/>
            </xsl:for-each>
            <xsl:for-each select="key('plotArea','')/c:valAx[1]">
              <xsl:call-template name="InsertYAxis"/>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>


        <xsl:call-template name="InsertDataSeries"/>

        <chart:wall chart:style-name="wall"/>
        <chart:floor chart:style-name="floor"/>
      </chart:plot-area>

      <xsl:call-template name="InsertChartTable"/>

    </chart:chart>
  </xsl:template>

  <xsl:template name="InsertChartProperties">
    <style:style style:name="chart" style:family="chart">
      <style:graphic-properties draw:fill-color="#ffffff" draw:stroke="solid"
        svg:stroke-color="#898989">
        <xsl:for-each select="c:chartSpace/c:spPr">

          <!-- Insert fill -->
          <xsl:choose>
            <xsl:when test="a:blipFill">
              <xsl:call-template name="InsertBitmapFill"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertFill"/>
            </xsl:otherwise>
          </xsl:choose>

          <!-- Insert Borders style, color -->
          <xsl:call-template name="InsertLineColor"/>
          <xsl:call-template name="InsertLineStyle"/>
        </xsl:for-each>
      </style:graphic-properties>
    </style:style>
  </xsl:template>

  <xsl:template name="InsertChartTitleProperties">
    <xsl:for-each select="c:chartSpace/c:chart/c:title">
      <style:style style:name="chart_title" style:family="chart">
        <style:chart-properties style:direction="ltr"/>
        <style:graphic-properties draw:stroke="none" draw:fill="none">
          <xsl:for-each select="c:spPr">
            <!-- Insert fill -->
            <xsl:choose>
              <xsl:when test="a:blipFill">
                <xsl:call-template name="InsertBitmapFill"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="InsertFill"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
        <style:text-properties fo:font-family="Arial" style:font-family-generic="swiss"
          style:font-pitch="variable" fo:font-size="13pt"
          style:font-family-asian="&apos;MS Gothic&apos;"
          style:font-family-generic-asian="system" style:font-pitch-asian="variable"
          style:font-size-asian="13pt" style:font-family-complex="Tahoma"
          style:font-family-generic-complex="system" style:font-pitch-complex="variable"
          style:font-size-complex="13pt">

          <xsl:choose>
            <!-- custom title -->
            <xsl:when test="c:tx">
              <xsl:for-each select="c:tx/c:rich/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:when>
            <!-- default title -->
            <xsl:otherwise>
              <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>

        </style:text-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertAxisXTitleProperties">
    <xsl:for-each select="c:title">
      <style:style style:name="axis-x_title" style:family="chart">
        <style:chart-properties style:direction="ltr"/>
        <style:graphic-properties draw:stroke="none" draw:fill="none">
          <xsl:for-each select="c:spPr">
            <!-- Insert fill -->
            <xsl:choose>
              <xsl:when test="a:blipFill">
                <xsl:call-template name="InsertBitmapFill"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="InsertFill"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
        <style:text-properties fo:font-family="Arial" style:font-family-generic="swiss"
          style:font-pitch="variable" fo:font-size="13pt"
          style:font-family-asian="&apos;MS Gothic&apos;"
          style:font-family-generic-asian="system" style:font-pitch-asian="variable"
          style:font-size-asian="13pt" style:font-family-complex="Tahoma"
          style:font-family-generic-complex="system" style:font-pitch-complex="variable"
          style:font-size-complex="13pt">

          <xsl:choose>
            <!-- custom title -->
            <xsl:when test="c:tx">
              <xsl:for-each select="c:tx/c:rich/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:when>
            <!-- default title -->
            <xsl:otherwise>
              <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>

        </style:text-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertAxisYTitleProperties">
    <xsl:for-each select="c:title">
      <style:style style:name="axis-y_title" style:family="chart">
        <style:chart-properties style:direction="ltr">
          <xsl:choose>
            <!-- custom title -->
            <xsl:when test="c:tx">
              <xsl:for-each select="c:tx/c:rich/a:bodyPr">
                <xsl:call-template name="TextRotation"/>
              </xsl:for-each>
            </xsl:when>
            <!-- default title -->
            <xsl:otherwise>
              <xsl:for-each select="c:txPr/a:bodyPr">
                <xsl:call-template name="TextRotation"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </style:chart-properties>
        <style:graphic-properties draw:stroke="none" draw:fill="none">
          <xsl:for-each select="c:spPr">
            <!-- Insert fill -->
            <xsl:choose>
              <xsl:when test="a:blipFill">
                <xsl:call-template name="InsertBitmapFill"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="InsertFill"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
        <style:text-properties fo:font-family="Arial" style:font-family-generic="swiss"
          style:font-pitch="variable" fo:font-size="13pt"
          style:font-family-asian="&apos;MS Gothic&apos;"
          style:font-family-generic-asian="system" style:font-pitch-asian="variable"
          style:font-size-asian="13pt" style:font-family-complex="Tahoma"
          style:font-family-generic-complex="system" style:font-pitch-complex="variable"
          style:font-size-complex="13pt">

          <xsl:choose>
            <!-- custom title -->
            <xsl:when test="c:tx">
              <xsl:for-each select="c:tx/c:rich/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:when>
            <!-- default title -->
            <xsl:otherwise>
              <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>

        </style:text-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertMajorGridXProperties">
    <xsl:for-each select="c:majorGridlines/c:spPr">
      <style:style style:name="majorGridX" style:family="chart">
        <style:graphic-properties svg:stroke-width="0.1cm" svg:stroke-color="#000000"
          draw:marker-start-width="0.35cm" draw:marker-end-width="0.35cm">
          <xsl:call-template name="InsertLineColor"/>
          <xsl:call-template name="InsertLineStyle"/>
        </style:graphic-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertMajorGridYProperties">
    <xsl:for-each select="c:majorGridlines">
      <style:style style:name="majorGridY" style:family="chart">
        <style:graphic-properties svg:stroke-width="0cm" svg:stroke-color="#000000"
          draw:marker-start-width="0.35cm" draw:marker-end-width="0.35cm">
          <xsl:for-each select="c:spPr">
            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertLegendProperties">
    <xsl:for-each select="c:chartSpace/c:chart/c:legend">
      <style:style style:name="legend" style:family="chart">
        <style:graphic-properties draw:fill="none" draw:stroke="none">
          <xsl:for-each select="c:spPr">
            <!-- Insert fill -->
            <xsl:choose>
              <xsl:when test="a:blipFill">
                <xsl:call-template name="InsertBitmapFill"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="InsertFill"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
        <style:text-properties fo:font-family="Calibri" style:font-family-generic="swiss"
          style:font-pitch="variable" fo:font-size="10pt"
          style:font-family-asian="&apos;MS Gothic&apos;"
          style:font-family-generic-asian="system" style:font-pitch-asian="variable"
          style:font-size-asian="10pt" style:font-family-complex="Tahoma"
          style:font-family-generic-complex="system" style:font-pitch-complex="variable"
          style:font-size-complex="10pt">
          <xsl:choose>
            <!-- custom title -->
            <xsl:when test="c:tx">
              <xsl:for-each select="c:tx/c:rich/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:when>
            <!-- default title -->
            <xsl:otherwise>
              <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </style:text-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertPlotAreaProperties">
    <xsl:for-each select="c:chartSpace/c:chart/c:plotArea">
      <style:style style:name="plot_area" style:family="chart">
        <style:chart-properties chart:japanese-candle-stick="false" chart:stock-with-volume="false"
          chart:three-dimensional="false" chart:deep="false" chart:lines="false"
          chart:interpolation="none" chart:symbol-type="none" chart:vertical="false"
          chart:lines-used="0" chart:connect-bars="false" chart:series-source="columns"
          chart:mean-value="false" chart:error-margin="0" chart:error-lower-limit="0"
          chart:error-upper-limit="0" chart:error-category="none" chart:error-percentage="0"
          chart:regression-type="none" chart:data-label-number="none" chart:data-label-text="false"
          chart:data-label-symbol="false">
          <!-- data grouping-->
          <xsl:choose>
            <xsl:when test="key('grouping','')[1]/@val = 'stacked' ">
              <xsl:attribute name="chart:stacked">
                <xsl:text>true</xsl:text>
              </xsl:attribute>
            </xsl:when>
            <xsl:when test="key('grouping','')[1]/@val = 'percentStacked' ">
              <xsl:attribute name="chart:percentage">
                <xsl:text>true</xsl:text>
              </xsl:attribute>
            </xsl:when>
            <xsl:when test="key('grouping','')[1]/@val = 'standard' ">
              <xsl:attribute name="chart:deep">
                <xsl:text>true</xsl:text>
              </xsl:attribute>
            </xsl:when>
          </xsl:choose>

          <!-- 3D chart -->
          <xsl:choose>
            <xsl:when test="c:bar3DChart or c:line3DChart or c:area3DChart or c:pie3DChart">
              <xsl:attribute name="chart:three-dimensional">
                <xsl:text>true</xsl:text>
              </xsl:attribute>

              <!-- 3D shape -->
              <xsl:if test="c:bar3DChart">
                <xsl:choose>
                  <xsl:when test="descendant:: c:shape/@val != '' ">
                    <xsl:for-each select="descendant::c:shape[1]">
                      <xsl:if test="@val != 'box' ">
                        <xsl:attribute name="chart:solid-type">
                          <xsl:value-of select="@val"/>
                        </xsl:attribute>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:when>
                </xsl:choose>
              </xsl:if>

            </xsl:when>
          </xsl:choose>

          <!-- bar charts -->
          <xsl:if test="c:barChart/c:barDir/@val = 'bar' ">
            <xsl:attribute name="chart:vertical">
              <xsl:text>true</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- 3D bar charts  -->
          <xsl:if test="c:bar3DChart/c:barDir/@val = 'bar' ">
            <xsl:attribute name="chart:vertical">
              <xsl:text>true</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- interpolation line charts -->
          <xsl:if
            test="(c:lineChart/c:ser/c:smooth/@val = 1 and c:lineChart/c:grouping/@val = 'standard') or
            c:scatterChart/c:ser/c:smooth/@val = 1">
            <xsl:attribute name="chart:interpolation">
              <xsl:text>cubic-spline</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- lines between points in a scatter chart -->
          <xsl:if test="c:scatterChart or c:bubbleChart">
            <xsl:attribute name="chart:lines">
              <xsl:choose>
                <!-- if at least one series has line -->
                <xsl:when
                  test="c:scatterChart/c:ser/c:spPr/a:ln[not(a:noFill)] or
                  c:scatterChart/c:ser[not(c:spPr/a:ln)]">
                  <xsl:text>true</xsl:text>
                </xsl:when>
                <xsl:when
                  test="c:bubbleChart/c:ser/c:spPr/a:ln[not(a:noFill)] or
                  c:bubbleChart/c:ser[not(c:spPr/a:ln)]">
                  <xsl:text>true</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>false</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
          </xsl:if>

          <!-- line, radar or scatter charts with symbols -->
          <xsl:if
            test="c:lineChart/c:ser[not(c:marker/c:symbol/@val = 'none')] or 
            (c:radarChart/c:radarStyle/@val = 'marker' and c:radarChart/c:ser[not(c:marker/c:symbol/@val = 'none')])
            or c:scatterChart/c:ser[not(c:marker/c:symbol/@val = 'none')] or c:bubbleChart/c:ser[not(c:marker/c:symbol/@val = 'none')]">
            <xsl:attribute name="chart:symbol-type">
              <xsl:text>automatic</xsl:text>
            </xsl:attribute>
          </xsl:if>
        </style:chart-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertAxisXProperties">
    <style:style style:name="axis-x" style:family="chart" style:data-style-name="N0">
      <style:chart-properties chart:display-label="true" chart:tick-marks-major-inner="false"
        chart:tick-marks-major-outer="true" chart:tick-marks-minor-inner="false"
        chart:tick-marks-minor-outer="false" chart:logarithmic="false" chart:text-overlap="false"
        text:line-break="true" chart:label-arrangement="side-by-side" chart:visible="true"
        style:direction="ltr">

        <xsl:call-template name="SetAxisChartProperties"/>

      </style:chart-properties>
      <style:graphic-properties draw:stroke="solid" svg:stroke-width="0cm"
        svg:stroke-color="#000000">
        <xsl:for-each select="c:spPr">
          <xsl:call-template name="InsertLineColor"/>
          <xsl:call-template name="InsertLineStyle"/>
        </xsl:for-each>
      </style:graphic-properties>
      <style:text-properties fo:font-family="Arial" style:font-family-generic="swiss"
        style:font-pitch="variable" fo:font-size="7pt"
        style:font-family-asian="&apos;MS Gothic&apos;"
        style:font-family-generic-asian="system" style:font-pitch-asian="variable"
        style:font-size-asian="7pt" style:font-family-complex="Tahoma"
        style:font-family-generic-complex="system" style:font-pitch-complex="variable"
        style:font-size-complex="7pt">
        <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
          <xsl:call-template name="TextBoxRunProperties"/>
        </xsl:for-each>
      </style:text-properties>
    </style:style>
  </xsl:template>

  <xsl:template name="InsertAxisYProperties">
    <style:style style:name="axis-y" style:family="chart" style:data-style-name="N0">
      <style:chart-properties chart:display-label="true" chart:tick-marks-major-inner="false"
        chart:tick-marks-major-outer="true" chart:logarithmic="false" chart:text-overlap="false"
        text:line-break="true" chart:label-arrangement="side-by-side" chart:visible="true"
        style:direction="ltr" chart:origin="0">

        <xsl:call-template name="SetAxisChartProperties"/>

      </style:chart-properties>
      <style:graphic-properties draw:stroke="solid" svg:stroke-width="0cm"
        svg:stroke-color="#000000">
        <xsl:for-each select="c:spPr">
          <xsl:call-template name="InsertLineColor"/>
          <xsl:call-template name="InsertLineStyle"/>
        </xsl:for-each>
      </style:graphic-properties>
      <style:text-properties fo:font-family="Arial" style:font-family-generic="swiss"
        style:font-pitch="variable" fo:font-size="7pt"
        style:font-family-asian="&apos;MS Gothic&apos;"
        style:font-family-generic-asian="system" style:font-pitch-asian="variable"
        style:font-size-asian="7pt" style:font-family-complex="Tahoma"
        style:font-family-generic-complex="system" style:font-pitch-complex="variable"
        style:font-size-complex="7pt">
        <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
          <xsl:call-template name="TextBoxRunProperties"/>
        </xsl:for-each>
      </style:text-properties>
    </style:style>
  </xsl:template>

  <xsl:template name="InsertSeriesProperties">

    <xsl:variable name="reverse">
      <xsl:for-each select="c:chartSpace/c:chart/c:plotArea">
        <xsl:choose>
          <xsl:when
            test="(c:barChart/c:barDir/@val = 'bar' and c:barChart/c:grouping/@val = 'clustered' ) or c:areaChart/c:grouping/@val = 'standard' ">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:for-each select="key('dataSeries','')">

      <xsl:variable name="seriesNumber">
        <xsl:choose>
          <xsl:when test="$reverse = 'true' ">
            <xsl:value-of select="count(key('dataSeries','')) - position() + 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="position()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <style:style style:name="{concat('series',$seriesNumber)}" style:family="chart">

        <style:chart-properties>
          <!-- symbols -->
          <xsl:if test="c:marker/c:symbol/@val = 'none' ">
            <xsl:attribute name="chart:symbol-type">
              <xsl:text>none</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- radar chart symbols -->
          <xsl:if
            test="key('plotArea','')/c:radarChart/c:radarStyle/@val = 'marker' and not(c:marker/c:symbol/@val = 'none')">
            <xsl:attribute name="chart:symbol-type">
              <xsl:text>automatic</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- label -->
          <xsl:for-each select="c:dLbls">
            <xsl:if test="not(c:dLbls/c:delete/@val = 1)">
              <!-- value -->
              <xsl:if test="c:showVal/@val = 1 ">
                <xsl:attribute name="chart:data-label-number">
                  <xsl:text>value</xsl:text>
                </xsl:attribute>
              </xsl:if>
              <!-- name -->
              <xsl:if test="c:showCatName/@val = 1 ">
                <xsl:attribute name="chart:data-label-text">
                  <xsl:text>true</xsl:text>
                </xsl:attribute>
              </xsl:if>
              <!-- legend icon -->
              <xsl:if test="c:showLegendKey/@val = 1 ">
                <xsl:attribute name="chart:data-label-symbol">
                  <xsl:text>true</xsl:text>
                </xsl:attribute>
              </xsl:if>
            </xsl:if>
          </xsl:for-each>

          <!-- error marker -->
          <xsl:for-each
            select="c:errBars[c:errValType/@val != 'stdErr' and c:errValType/@val != 'stdDev' ]">

            <!-- error type -->
            <xsl:choose>
              <xsl:when test="c:errValType/@val = 'percentage' ">
                <xsl:attribute name="chart:error-category">
                  <xsl:text>percentage</xsl:text>
                </xsl:attribute>
              </xsl:when>
              <xsl:when test="c:errValType/@val = 'fixedVal' or c:errValType/@val = 'cust' ">
                <xsl:attribute name="chart:error-category">
                  <xsl:text>constant</xsl:text>
                </xsl:attribute>
              </xsl:when>
            </xsl:choose>

            <!-- error range -->
            <xsl:if test="c:errValType/@val = 'percentage' ">
              <xsl:attribute name="chart:error-percentage">
                <xsl:value-of select="c:val/@val"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="c:errValType/@val = 'fixedVal' ">
              <xsl:for-each select="c:val">
                <xsl:attribute name="chart:error-lower-limit">
                  <xsl:value-of select="@val"/>
                </xsl:attribute>
                <xsl:attribute name="chart:error-upper-limit">
                  <xsl:value-of select="@val"/>
                </xsl:attribute>
              </xsl:for-each>
            </xsl:if>
            <xsl:if test="c:errValType/@val = 'cust' ">
              <xsl:attribute name="chart:error-lower-limit">
                <xsl:value-of select="c:minus/c:numLit/c:pt[1]/c:v"/>
              </xsl:attribute>
              <xsl:attribute name="chart:error-upper-limit">
                <xsl:value-of select="c:plus/c:numLit/c:pt[1]/c:v"/>
              </xsl:attribute>
            </xsl:if>

            <!-- indicators -->
            <xsl:if test="c:errBarType/@val = 'plus' or c:errBarType/@val = 'both' ">
              <xsl:attribute name="chart:error-upper-indicator">
                <xsl:text>true</xsl:text>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="c:errBarType/@val = 'minus' or c:errBarType/@val = 'both' ">
              <xsl:attribute name="chart:error-lower-indicator">
                <xsl:text>true</xsl:text>
              </xsl:attribute>
            </xsl:if>

          </xsl:for-each>

        </style:chart-properties>

        <style:graphic-properties>

          <!-- default stroke for scatter and bubble chart -->
          <xsl:if
            test="key('plotArea','')/c:scatterChart or key('plotArea','')/c:bubbleChart or key('plotArea','')/c:barChart or key('plotArea','')/c:bar3DChart">
            <xsl:attribute name="draw:stroke">
              <xsl:text>none</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <!-- default line width for line chart -->
          <xsl:if test="key('plotArea','')/c:lineChart">
            <xsl:attribute name="svg:stroke-width">
              <xsl:text>0.079cm</xsl:text>
            </xsl:attribute>
          </xsl:if>

          <xsl:for-each select="c:spPr">

            <!-- Insert fill -->
            <xsl:choose>
              <xsl:when test="a:blipFill">
                <xsl:call-template name="InsertBitmapFill"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="InsertFill"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>

        </style:graphic-properties>
        <style:text-properties fo:font-family="Calibri" style:font-family-generic="swiss"
          style:font-pitch="variable" fo:font-size="10pt"
          style:font-family-asian="&apos;MS Gothic&apos;"
          style:font-family-generic-asian="system" style:font-pitch-asian="variable"
          style:font-size-asian="6pt" style:font-family-complex="Tahoma"
          style:font-family-generic-complex="system" style:font-pitch-complex="variable"
          style:font-size-complex="6pt">
          <xsl:for-each select="c:dLbls">
            <xsl:if test="not(c:dLbls/c:delete/@val = 1)">
              <xsl:for-each select="c:txPr/a:p[1]/a:pPr/a:defRPr">
                <xsl:call-template name="TextBoxRunProperties"/>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
        </style:text-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertErrorProperties">
    <xsl:for-each
      select="key('error','')[c:errValType/@val != 'stdErr' and c:errValType/@val != 'stdDev' ]">
      <style:style style:name="{concat('error',generate-id(.))}" style:family="chart">
        <style:graphic-properties draw:stroke="solid" svg:stroke-width="0cm"
          svg:stroke-color="#000000" draw:marker-start="" draw:marker-start-width="0.2cm"
          draw:marker-start-center="false" draw:marker-end="" draw:marker-end-width="0.2cm"
          draw:marker-end-center="false" svg:stroke-opacity="100%">
          <xsl:for-each select="c:spPr">
            <xsl:call-template name="InsertLineColor"/>
            <xsl:call-template name="InsertLineStyle"/>
          </xsl:for-each>
        </style:graphic-properties>
      </style:style>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertWallProperties">
    <!-- c:chartSpace/c:chart/c:backWall -->
    <style:style style:name="wall" style:family="chart">
      <style:graphic-properties draw:stroke="none" draw:fill="solid" draw:fill-color="#ffffff">
        <!-- Insert Borders Wall style, color, fill, transparency -->
        <xsl:for-each select="c:chartSpace/c:chart/c:plotArea/c:spPr">

          <!-- Insert fill -->
          <xsl:choose>
            <xsl:when test="a:blipFill">
              <xsl:call-template name="InsertBitmapFill"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertFill"/>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:call-template name="InsertLineColor"/>
          <xsl:call-template name="InsertLineStyle"/>
        </xsl:for-each>
      </style:graphic-properties>
    </style:style>
  </xsl:template>

  <xsl:template name="InsertFloorProperties">
    <!-- c:chartSpace/c:chart/c:floor -->
    <style:style style:name="floor" style:family="chart">
      <style:graphic-properties draw:stroke="solid" svg:stroke-width="0.03cm"
        draw:marker-start-width="0.25cm" draw:marker-end-width="0.25cm" draw:fill="none"
        draw:fill-color="#999999"/>
    </style:style>
  </xsl:template>

  <xsl:template name="InsertDrawFillImage">
    <xsl:param name="chartId"/>
    <xsl:param name="inputChart"/>

    <xsl:for-each select="key('spPr','')/a:blipFill">


      <xsl:variable name="pzipsource">
        <xsl:call-template name="GetTarget">
          <xsl:with-param name="document">
            <xsl:value-of select="$inputChart"/>
          </xsl:with-param>
          <xsl:with-param name="id">
            <xsl:value-of select="a:blip/@r:embed"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="pziptarget">
        <xsl:value-of
          select="concat('Object ',$chartId,'/Pictures/',substring-after(substring-after($pzipsource, '/'), '/'))"
        />
      </xsl:variable>

      <pzip:copy pzip:source="{concat('xl/',substring-after($pzipsource, '/'))}"
        pzip:target="{$pziptarget}"/>

      <draw:fill-image xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad">

        <xsl:attribute name="draw:name">
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>

        <xsl:attribute name="xlink:href">
          <xsl:value-of
            select="concat('Pictures/',substring-after(substring-after($pzipsource, '/'), '/'))"/>
        </xsl:attribute>
      </draw:fill-image>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="TextRotation">

    <!-- text rotation -->
    <xsl:if test="@rot">
      <xsl:attribute name="style:rotation-angle">
        <xsl:choose>
          <xsl:when test="@rot = 0">
            <xsl:text>0</xsl:text>
          </xsl:when>
          <xsl:when test="@rot &lt; 0">
            <xsl:value-of select="substring-after(@rot,'-') div 60000"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="360 - @rot div 60000"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </xsl:if>

    <!-- vertiacally stacked-->
    <xsl:if test="@vert != '' and @vert != 'horz' ">
      <xsl:attribute name="style:direction">
        <xsl:text>ttb</xsl:text>
      </xsl:attribute>
    </xsl:if>

  </xsl:template>

  <xsl:template name="SetAxisChartProperties">

    <!-- valAx id (for axis at) -->
    <xsl:variable name="id">
      <xsl:value-of select="generate-id()"/>
    </xsl:variable>

    <!-- axis labels -->
    <xsl:if test="c:tickLblPos/@val = 'none' ">
      <xsl:attribute name="chart:display-label">
        <xsl:text>false</xsl:text>
      </xsl:attribute>
    </xsl:if>

    <!-- axis label rotation -->
    <xsl:for-each select="c:txPr/a:bodyPr">
      <xsl:call-template name="TextRotation"/>
    </xsl:for-each>

    <!-- logarythmic scale -->
    <xsl:if test="c:scaling/c:logBase">
      <xsl:attribute name="chart:logarithmic">
        <xsl:text>true</xsl:text>
      </xsl:attribute>
    </xsl:if>

    <!-- min/max value-->
    <xsl:if test="c:scaling/c:max">
      <xsl:attribute name="chart:maximum">
        <xsl:value-of select="c:scaling/c:max/@val"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="c:scaling/c:min">
      <xsl:attribute name="chart:minimum">
        <xsl:value-of select="c:scaling/c:min/@val"/>
      </xsl:attribute>
    </xsl:if>

    <!-- major interval marks-->
    <xsl:if test="c:majorTickMark">
      <xsl:choose>
        <!-- cross-->
        <xsl:when test="c:majorTickMark/@val = 'cross' ">
          <xsl:attribute name="chart:tick-marks-major-inner">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-major-outer">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- in -->
        <xsl:when test="c:majorTickMark/@val = 'in' ">
          <xsl:attribute name="chart:tick-marks-major-inner">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-major-outer">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- out -->
        <xsl:when test="c:majorTickMark/@val = 'out' ">
          <xsl:attribute name="chart:tick-marks-major-inner">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-major-outer">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- none -->
        <xsl:when test="c:majorTickMark/@val = 'none' ">
          <xsl:attribute name="chart:tick-marks-major-inner">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-major-outer">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    <!-- minor interval marks-->
    <xsl:if test="c:minorTickMark">
      <xsl:choose>
        <!-- cross-->
        <xsl:when test="c:minorTickMark/@val = 'cross' ">
          <xsl:attribute name="chart:tick-marks-minor-inner">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-minor-outer">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- in -->
        <xsl:when test="c:minorTickMark/@val = 'in' ">
          <xsl:attribute name="chart:tick-marks-minor-inner">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-minor-outer">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <!-- out -->
        <xsl:when test="c:minorTickMark/@val = 'out' ">
          <xsl:attribute name="chart:tick-marks-minor-inner">
            <xsl:text>false</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="chart:tick-marks-minor-outer">
            <xsl:text>true</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    <!-- axis at -->
    <xsl:for-each select="parent::node()/c:valAx[generate-id(.) != $id][1]">
      <xsl:if test="c:crossesAt">
        <xsl:attribute name="chart:origin">
          <xsl:value-of select="c:crossesAt/@val"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:for-each>

    <!-- major unit -->
    <xsl:choose>
      <xsl:when test="c:majorUnit">
        <xsl:attribute name="chart:interval-major">
          <xsl:value-of select="c:majorUnit/@val"/>
        </xsl:attribute>
        <xsl:if test="c:minorUnit">
          <xsl:attribute name="chart:interval-minor-divisor">
            <xsl:value-of select="c:majorUnit/@val div c:minorUnit/@val"/>
          </xsl:attribute>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <!-- when there is no majorUnit it has to be maximum of scale to calculate minor-divisor -->
        <xsl:if test="c:minorUnit and c:scaling/c:max">
          <xsl:attribute name="chart:interval-minor-divisor">
            <xsl:value-of select="c:scaling/c:max/@val div c:minorUnit/@val"/>
          </xsl:attribute>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>