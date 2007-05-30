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
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0">

  <!-- @Filename: chart.xsl -->
  <!-- @Description: This stylesheet is used for charts conversion -->
  <!-- @Created: 2007-05-24 -->

  <xsl:key name="rows" match="table:table-rows" use="''"/>
  <xsl:key name="header" match="table:table-header-rows" use="''"/>
  <xsl:key name="series" match="chart:series" use="''"/>
  <xsl:key name="style" match="style:style" use="@style:name"/>
  <xsl:key name="chart" match="chart:chart" use="''"/>

  <xsl:template name="CreateChartFile">
    <!-- @Description: Searches for all charts within sheet and creates output chart files. -->
    <!-- @Context: table:table -->

    <xsl:param name="sheetNum"/>
    <!-- (number) sheet number -->

    <xsl:for-each
      select="descendant::draw:frame/draw:object[document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart]">
      <pzip:entry pzip:target="{concat('xl/charts/chart',$sheetNum,'_',position(),'.xml')}">

        <!-- example chart file-->
        <xsl:for-each
          select="document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart">
          <c:chartSpace>
            <c:lang val="pl-PL"/>

            <xsl:for-each select="chart:chart">
              <xsl:call-template name="InsertChart"/>
            </xsl:for-each>

            <c:spPr>
              <a:solidFill>
                <a:srgbClr val="FFFFFF"/>
              </a:solidFill>
              <a:ln w="9525">
                <a:noFill/>
              </a:ln>
            </c:spPr>
            <c:txPr>
              <a:bodyPr/>
              <a:lstStyle/>
              <a:p>
                <a:pPr>
                  <a:defRPr sz="1000" b="0" i="0" u="none" strike="noStrike" baseline="0">
                    <a:solidFill>
                      <a:srgbClr val="000000"/>
                    </a:solidFill>
                    <a:latin typeface="Arial"/>
                    <a:ea typeface="Arial"/>
                    <a:cs typeface="Arial"/>
                  </a:defRPr>
                </a:pPr>
                <a:endParaRPr lang="pl-PL"/>
              </a:p>
            </c:txPr>

            <c:printSettings>
              <c:headerFooter alignWithMargins="0"/>
              <c:pageMargins b="1" l="0.75000000000000044" r="0.75000000000000044" t="1"
                header="0.49212598450000022" footer="0.49212598450000022"/>
              <c:pageSetup/>
            </c:printSettings>
          </c:chartSpace>
        </xsl:for-each>
      </pzip:entry>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertChart">
    <!-- @Description: Writes chart definition to output chart file. -->
    <!-- @Context: chart:chart -->

    <c:chart>
      <xsl:call-template name="InsertTitle"/>
      <xsl:call-template name="InsertPlotArea"/>
      <xsl:call-template name="InsertLegend"/>
      <xsl:call-template name="InsertAdditionalProperties"/>
    </c:chart>
  </xsl:template>

  <xsl:template name="InsertTitle">
    <!-- @Description: Inserts chart title -->
    <!-- @Context: chart:chart -->
    <c:title>
      <c:tx>
        <c:rich>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:pPr>
              <a:defRPr sz="1300" b="0" i="0" u="none" strike="noStrike" baseline="0">
                <a:solidFill>
                  <a:srgbClr val="000000"/>
                </a:solidFill>
                <a:latin typeface="Arial"/>
                <a:ea typeface="Arial"/>
                <a:cs typeface="Arial"/>
              </a:defRPr>
            </a:pPr>
            <a:r>
              <a:rPr lang="pl-PL"/>
              <a:t>Main Title</a:t>
            </a:r>
          </a:p>
        </c:rich>
      </c:tx>
      <c:layout>
        <c:manualLayout>
          <c:xMode val="edge"/>
          <c:yMode val="edge"/>
          <c:x val="0.37282229965156838"/>
          <c:y val="3.8022813688212961E-2"/>
        </c:manualLayout>
      </c:layout>
      <c:spPr>
        <a:noFill/>
        <a:ln w="25400">
          <a:noFill/>
        </a:ln>
      </c:spPr>
    </c:title>
  </xsl:template>

  <xsl:template name="InsertPlotArea">
    <!-- @Description: Outputs chart plot area -->
    <!-- @Context: chart:chart -->

    <c:plotArea>
      <c:layout>
        <c:manualLayout>
          <c:layoutTarget val="inner"/>
          <c:xMode val="edge"/>
          <c:yMode val="edge"/>
          <c:x val="0.10452961672473868"/>
          <c:y val="0.24334600760456274"/>
          <c:w val="0.68641114982578355"/>
          <c:h val="0.60836501901140683"/>
        </c:manualLayout>
      </c:layout>

      <xsl:call-template name="InsertChartType"/>

      <xsl:if test="key('series','')[@chart:class]">
        <xsl:call-template name="InsertSecondaryLineChart"/>
      </xsl:if>

      <xsl:if test="not(@chart:class= 'chart:circle' )">
        <xsl:call-template name="InsertAxisX"/>
        <xsl:call-template name="InsertAxisY"/>
      </xsl:if>

      <c:spPr>
        <a:noFill/>
        <a:ln w="25400">
          <a:noFill/>
        </a:ln>
      </c:spPr>
    </c:plotArea>
  </xsl:template>

  <xsl:template name="InsertLegend">
    <!-- @Description: Inserts chart legend. -->
    <!-- @Context: chart:chart -->

    <c:legend>
      <c:legendPos val="r"/>
      <c:layout>
        <c:manualLayout>
          <c:xMode val="edge"/>
          <c:yMode val="edge"/>
          <c:x val="0.82926829268292679"/>
          <c:y val="0.47148288973384095"/>
          <c:w val="0.14285714285714299"/>
          <c:h val="0.15209125475285182"/>
        </c:manualLayout>
      </c:layout>
      <c:spPr>
        <a:noFill/>
        <a:ln w="3175">
          <a:solidFill>
            <a:srgbClr val="000000"/>
          </a:solidFill>
          <a:prstDash val="solid"/>
        </a:ln>
      </c:spPr>
      <c:txPr>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:pPr>
            <a:defRPr sz="550" b="0" i="0" u="none" strike="noStrike" baseline="0">
              <a:solidFill>
                <a:srgbClr val="000000"/>
              </a:solidFill>
              <a:latin typeface="Arial"/>
              <a:ea typeface="Arial"/>
              <a:cs typeface="Arial"/>
            </a:defRPr>
          </a:pPr>
          <a:endParaRPr lang="pl-PL"/>
        </a:p>
      </c:txPr>
    </c:legend>
  </xsl:template>

  <xsl:template name="InsertAdditionalProperties">

    <c:dispBlanksAs val="gap"/>
  </xsl:template>

  <xsl:template name="InsertChartType">
    <!-- @Description: Inserts appriopiate type of chart -->
    <!-- @Context: chart:chart -->

    <xsl:choose>
      <xsl:when test="@chart:class='chart:bar' ">
        <c:barChart>

          <!-- bar or column chart -->
          <xsl:choose>
            <xsl:when
              test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:vertical = 'false' ">
              <c:barDir val="col"/>
            </xsl:when>
            <xsl:otherwise>
              <c:barDir val="bar"/>
            </xsl:otherwise>
          </xsl:choose>

          <c:grouping val="clustered">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:call-template name="InsertChartContent"/>

          <!-- set overlap for stacked data charts -->
          <xsl:for-each
            select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
            <xsl:if test="@chart:stacked = 'true' or @chart:percentage = 'true' ">
              <c:overlap val="100"/>
            </xsl:if>
          </xsl:for-each>

        </c:barChart>
      </xsl:when>

      <xsl:when
        test="@chart:class='chart:line' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
        <c:line3DChart>
          <c:grouping val="standard"/>

          <xsl:call-template name="InsertChartContent"/>
        </c:line3DChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:line' ">
        <c:lineChart>

          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:call-template name="InsertChartContent"/>
        </c:lineChart>
      </xsl:when>

      <xsl:when
        test="@chart:class='chart:area' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
        <c:area3DChart>

          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:call-template name="InsertChartContent"/>
        </c:area3DChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:area' ">
        <c:areaChart>

          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:call-template name="InsertChartContent"/>
        </c:areaChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:circle' ">
        <c:pieChart>
          <c:varyColors val="1"/>
          <xsl:call-template name="InsertChartContent"/>
        </c:pieChart>
      </xsl:when>

      <!-- making problems at his time -->
      <!--<xsl:when test="@chart:class='chart:scatter' ">
        <c:scatterChart>
          <c:scatterStyle val="lineMarker"/>
          <xsl:call-template name="InsertChartContent"/>
        </c:scatterChart>
      </xsl:when>
      
      <xsl:when test="@chart:class='chart:radar' ">
        <c:radarChart>
          <c:radarStyle val="marker"/>
          <xsl:call-template name="InsertChartContent"/>
        </c:radarChart>
      </xsl:when>
      
      <xsl:when test="@chart:class='chart:stock' ">
        <c:stockChart>
          <xsl:call-template name="InsertChartContent"/>
        </c:stockChart>
      </xsl:when>-->

      <!-- temporary otherwise eventually none -->
      <xsl:otherwise>
        <c:barChart>
          <c:barDir val="col"/>
          <c:grouping val="clustered"/>
          <xsl:call-template name="InsertChartContent"/>
        </c:barChart>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertChartContent">
    <!-- @Description: Inserts chart content -->
    <!-- @Context: chart:chart -->

    <xsl:variable name="numSeries">
      <!-- (number) number of series inside chart -->
      <xsl:value-of select="count(key('series','')[not(@chart:class='chart:line')])"/>
    </xsl:variable>

    <xsl:variable name="numPoints">
      <!-- (number) maximum number of data point -->
      <xsl:value-of select="count(key('rows','')/table:table-row)"/>
    </xsl:variable>

    <!-- reverse categories for bar charts -->
    <xsl:variable name="reverseCategories">
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <xsl:when test="@chart:vertical = 'true' ">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="reverseSeries">
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <!-- reverse series for: (normal bar chart) or (2D normal area chart) -->
          <xsl:when
            test="(@chart:vertical = 'true' and not(@chart:stacked = 'true' or @chart:percentage = 'true' )) or 
            (key('chart','')/@chart:class = 'chart:area' and not(@chart:stacked = 'true' or @chart:percentage = 'true' ) and @chart:three-dimensional = 'false' )">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:for-each select="key('rows','')">
      <xsl:call-template name="InsertSeries">
        <xsl:with-param name="numSeries" select="$numSeries"/>
        <xsl:with-param name="numPoints" select="$numPoints"/>
        <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
        <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
      </xsl:call-template>
    </xsl:for-each>


    <c:axId val="110226048"/>
    <c:axId val="110498176"/>

  </xsl:template>

  <xsl:template name="InsertAxisX">
    <!-- @Description: Inserts X-Axis -->
    <!-- @Context: chart:chart -->

    <c:catAx>
      <c:axId val="110226048"/>
      <c:scaling>
        <c:orientation val="minMax"/>
      </c:scaling>
      <c:axPos val="b"/>
      <c:numFmt formatCode="General" sourceLinked="1"/>
      <c:tickLblPos val="low"/>
      <c:spPr>
        <a:ln w="3175">
          <a:solidFill>
            <a:srgbClr val="000000"/>
          </a:solidFill>
          <a:prstDash val="solid"/>
        </a:ln>
      </c:spPr>
      <c:txPr>
        <a:bodyPr rot="0" vert="horz"/>
        <a:lstStyle/>
        <a:p>
          <a:pPr>
            <a:defRPr sz="700" b="0" i="0" u="none" strike="noStrike" baseline="0">
              <a:solidFill>
                <a:srgbClr val="000000"/>
              </a:solidFill>
              <a:latin typeface="Arial"/>
              <a:ea typeface="Arial"/>
              <a:cs typeface="Arial"/>
            </a:defRPr>
          </a:pPr>
          <a:endParaRPr lang="pl-PL"/>
        </a:p>
      </c:txPr>
      <c:crossAx val="110498176"/>
      <c:crossesAt val="0"/>
      <c:auto val="1"/>
      <c:lblAlgn val="ctr"/>
      <c:lblOffset val="100"/>
      <c:tickLblSkip val="1"/>
      <c:tickMarkSkip val="1"/>
    </c:catAx>
  </xsl:template>

  <xsl:template name="InsertAxisY">
    <!-- @Description: Inserts X-Axis -->
    <!-- @Context: chart:chart -->

    <c:valAx>
      <c:axId val="110498176"/>
      <c:scaling>
        <c:orientation val="minMax"/>
      </c:scaling>
      <c:axPos val="l"/>
      <c:majorGridlines>
        <c:spPr>
          <a:ln w="3175">
            <a:solidFill>
              <a:srgbClr val="000000"/>
            </a:solidFill>
            <a:prstDash val="solid"/>
          </a:ln>
        </c:spPr>
      </c:majorGridlines>
      <c:numFmt formatCode="General" sourceLinked="0"/>
      <c:tickLblPos val="low"/>
      <c:spPr>
        <a:ln w="3175">
          <a:solidFill>
            <a:srgbClr val="000000"/>
          </a:solidFill>
          <a:prstDash val="solid"/>
        </a:ln>
      </c:spPr>
      <c:txPr>
        <a:bodyPr rot="0" vert="horz"/>
        <a:lstStyle/>
        <a:p>
          <a:pPr>
            <a:defRPr sz="700" b="0" i="0" u="none" strike="noStrike" baseline="0">
              <a:solidFill>
                <a:srgbClr val="000000"/>
              </a:solidFill>
              <a:latin typeface="Arial"/>
              <a:ea typeface="Arial"/>
              <a:cs typeface="Arial"/>
            </a:defRPr>
          </a:pPr>
          <a:endParaRPr lang="pl-PL"/>
        </a:p>
      </c:txPr>
      <c:crossAx val="110226048"/>
      <c:crosses val="autoZero"/>

      <!-- cross type -->
      <xsl:choose>
        <xsl:when
          test="key('chart','')/@chart:class='chart:area' or key('chart','')/@chart:class='chart:line' ">
          <c:crossBetween val="midCat"/>
        </xsl:when>
        <xsl:otherwise>
          <c:crossBetween val="between"/>
        </xsl:otherwise>
      </xsl:choose>


    </c:valAx>
  </xsl:template>

  <xsl:template name="InsertSeries">
    <!-- @Description: Outputs chart series and their values -->
    <!-- @Context: table:table-rows -->

    <xsl:param name="numSeries"/>
    <!-- (number) number of series inside chart -->
    <xsl:param name="numPoints"/>
    <!-- (number) maximum number of data point -->
    <xsl:param name="count" select="0"/>
    <!-- (number) loop counter -->
    <xsl:param name="reverseSeries"/>
    <!-- (string) is chart vertically aligned -->
    <xsl:param name="reverseCategories"/>

    <xsl:choose>
      <xsl:when test="$count &lt; $numSeries">
        <c:ser>
          <c:idx val="{$count}"/>
          <c:order val="{$count}"/>

          <!-- series name -->
          <c:tx>
            <c:v>
              <xsl:choose>
                <xsl:when test="$reverseSeries = 'true' ">
                  <xsl:value-of
                    select="key('header','')/table:table-row/table:table-cell[$numSeries + 1 - $count]"
                  />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of
                    select="key('header','')/table:table-row/table:table-cell[$count + 2]"/>
                </xsl:otherwise>
              </xsl:choose>
            </c:v>
          </c:tx>

          <xsl:call-template name="InsertSeriesShapeProperty">
            <xsl:with-param name="totalSeries" select="$numSeries"/>
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
          </xsl:call-template>

          <!-- insert data categories -->
          <c:cat>
            <c:strLit>
              <c:ptCount val="{$numPoints}"/>
              <xsl:choose>
                <xsl:when test="$reverseCategories = 'true' ">
                  <xsl:for-each select="key('rows','')">
                    <xsl:call-template name="InsertCategoriesReverse">
                      <xsl:with-param name="numCategories" select="$numPoints"/>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:for-each select="key('rows','')">
                    <xsl:call-template name="InsertCategories">
                      <xsl:with-param name="numCategories" select="$numPoints"/>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </c:strLit>
          </c:cat>

          <!-- series values -->
          <c:val>
            <c:numRef>
              <!-- TO DO: reference to sheet cell -->
              <!-- i.e. <c:f>Sheet1!$D$3:$D$4</c:f> -->
              <c:numCache>
                <c:formatCode>General</c:formatCode>
                <c:ptCount val="{$numPoints}"/>

                <!-- number of this series -->
                <xsl:variable name="thisSeries">
                  <xsl:choose>
                    <!-- when $reverseSeries = 'true' then count backwards -->
                    <xsl:when test="$reverseSeries = 'true' ">
                      <xsl:value-of select="$numSeries - 1 - $count"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="$count"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>

                <xsl:for-each select="ancestor::chart:chart">
                  <xsl:choose>
                    <xsl:when test="$reverseCategories = 'true' ">
                      <xsl:for-each select="key('rows','')">
                        <xsl:call-template name="InsertPointsReverse">
                          <xsl:with-param name="series" select="$thisSeries"/>
                          <xsl:with-param name="numCategories" select="$numPoints"/>
                        </xsl:call-template>
                      </xsl:for-each>
                    </xsl:when>

                    <xsl:otherwise>
                      <xsl:for-each select="key('rows','')">
                        <xsl:call-template name="InsertPoints">
                          <xsl:with-param name="series" select="$thisSeries"/>
                        </xsl:call-template>
                      </xsl:for-each>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </c:numCache>
            </c:numRef>
          </c:val>

          <!-- smooth line -->
          <xsl:for-each select="ancestor::chart:chart">
            <xsl:if test="@chart:class = 'chart:line' ">
              <xsl:for-each
                select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
                <xsl:if test="@chart:interpolation != 'none' ">
                  <c:smooth val="1"/>
                </xsl:if>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
        </c:ser>

        <xsl:call-template name="InsertSeries">
          <xsl:with-param name="numSeries" select="$numSeries"/>
          <xsl:with-param name="numPoints" select="$numPoints"/>
          <xsl:with-param name="count" select="$count + 1"/>
          <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
          <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertPoints">
    <!-- @Description: Outputs series data points -->
    <!-- @Context: table:table-rows -->

    <xsl:param name="series"/>

    <xsl:for-each select="table:table-row">
      <xsl:if test="table:table-cell[$series + 2]/text:p != '1.#NAN' ">
        <c:pt idx="{position() - 1}">
          <c:v>
            <!-- $ series + 2 because position starts with 1 and we skip first cell -->
            <xsl:value-of select="table:table-cell[$series + 2]/text:p"/>
          </c:v>
        </c:pt>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertPointsReverse">
    <!-- @Description: Outputs series data points -->
    <!-- @Context: table:table-rows -->

    <xsl:param name="series"/>
    <xsl:param name="numCategories"/>
    <xsl:param name="count" select="0"/>

    <xsl:choose>
      <xsl:when test="$count &lt; $numCategories">
        <xsl:for-each select="table:table-row[$numCategories - $count]">
          <xsl:if test="table:table-cell[$series + 2]/text:p != '1.#NAN' ">
            <c:pt idx="{$count}">
              <c:v>
                <!-- $ series + 2 because position starts with 1 and we skip first cell -->
                <xsl:value-of select="table:table-cell[$series + 2]/text:p"/>
              </c:v>
            </c:pt>
          </xsl:if>
        </xsl:for-each>

        <xsl:call-template name="InsertPointsReverse">
          <xsl:with-param name="series" select="$series"/>
          <xsl:with-param name="numCategories" select="$numCategories"/>
          <xsl:with-param name="count" select="$count + 1"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertCategories">
    <!-- @Description: Outputs categories names-->
    <!-- @Context: table:table-rows -->

    <xsl:param name="numCategories"/>

    <!-- categories names -->
    <xsl:for-each select="table:table-row">
      <c:pt idx="{position() - 1}">
        <c:v>
          <xsl:value-of select="table:table-cell[1]/text:p"/>
        </c:v>
      </c:pt>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertCategoriesReverse">
    <!-- @Description: Outputs categories names-->
    <!-- @Context: table:table-rows -->

    <xsl:param name="numCategories"/>
    <xsl:param name="count" select="0"/>

    <!-- categories names -->
    <xsl:choose>
      <xsl:when test="$count &lt; $numCategories">
        <xsl:for-each select="table:table-row[$numCategories - $count]">
          <c:pt idx="{$count}">
            <c:v>
              <xsl:value-of select="table:table-cell[1]/text:p"/>
            </c:v>
          </c:pt>
        </xsl:for-each>

        <xsl:call-template name="InsertCategoriesReverse">
          <xsl:with-param name="numCategories" select="$numCategories"/>
          <xsl:with-param name="count" select="$count + 1"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="SetDataGroupingAtribute">
    <!-- @Description: Sets data grouping type -->
    <!-- @Context: chart:chart -->

    <!-- choose data grouping -->
    <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
      <xsl:choose>
        <xsl:when test="@chart:stacked = 'true' ">
          <xsl:attribute name="val">
            <xsl:text>stacked</xsl:text>
          </xsl:attribute>
        </xsl:when>

        <xsl:when test="@chart:percentage = 'true' ">
          <xsl:attribute name="val">
            <xsl:text>percentStacked</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertSeriesShapeProperty">
    <xsl:param name="totalSeries"/>
    <xsl:param name="count"/>
    <xsl:param name="reverseSeries"/>

    <!-- count series from backwards if reverseSeries is = "true" -->
    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$reverseSeries = 'true' ">
          <xsl:value-of select="$totalSeries - $count"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$count + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- series shape property -->
    <c:spPr>
      <xsl:choose>
        <xsl:when test="key('chart','' )/@chart:class = 'chart:circle' ">
          <a:ln w="28575">
            <a:noFill/>
          </a:ln>
        </xsl:when>

        <xsl:otherwise>
          <!-- fill color -->
          <a:solidFill>
            <a:srgbClr val="9999FF">
              <xsl:variable name="styleName">
                <!-- (string) series style name -->
                <xsl:value-of select="key('series','')[position() = $number]/@chart:style-name"/>
              </xsl:variable>
              <xsl:attribute name="val">
                <xsl:value-of
                  select="substring(key('style',$styleName)/style:graphic-properties/@draw:fill-color,2)"
                />
              </xsl:attribute>
            </a:srgbClr>
          </a:solidFill>

          <!-- line color -->
          <a:ln w="3175">
            <a:solidFill>
              <a:srgbClr val="000000">
                <xsl:variable name="styleName">
                  <!-- (string) series style name -->
                  <xsl:value-of select="key('series','')[position() = $number]/@chart:style-name"/>
                </xsl:variable>
                <xsl:attribute name="val">
                  <xsl:value-of
                    select="substring(key('style',$styleName)/style:graphic-properties/@svg:stroke-color,2)"
                  />
                </xsl:attribute>
              </a:srgbClr>
            </a:solidFill>
            <a:prstDash val="solid"/>
          </a:ln>
        </xsl:otherwise>
      </xsl:choose>
    </c:spPr>

    <!-- marker type -->
    <xsl:if test="key('chart','' )/@chart:class = 'chart:line' ">
      <xsl:for-each
        select="ancestor::chart:chart/chart:plot-area/chart:series[position() = $number]">
        <xsl:choose>
          <xsl:when
            test="key('style',@chart:style-name )/style:chart-properties/@chart:symbol-type = 'none' ">
            <c:marker>
              <c:symbol val="none"/>
            </c:marker>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template name="InsertSecondaryLineChart">
    <c:lineChart>
      <c:grouping val="standard"/>

      <xsl:call-template name="InsertSecondaryChartContent"/>

    </c:lineChart>
  </xsl:template>

  <xsl:template name="InsertSecondaryChartContent">
    <!-- @Description: Inserts chart content -->
    <!-- @Context: chart:chart -->

    <xsl:variable name="numSeries">
      <!-- (number) number of series inside chart -->
      <xsl:value-of select="count(key('series','')[@chart:class='chart:line'])"/>
    </xsl:variable>

    <xsl:variable name="numPoints">
      <!-- (number) maximum number of data point -->
      <xsl:value-of select="count(key('rows','')/table:table-row)"/>
    </xsl:variable>

    <xsl:variable name="primarySeries">
      <xsl:value-of select="count(key('series','')[not(@chart:class='chart:line')])"/>
    </xsl:variable>

    <xsl:for-each select="key('rows','')">
      <xsl:call-template name="InsertSecondaryChartSeries">
        <xsl:with-param name="numSeries" select="$numSeries"/>
        <xsl:with-param name="numPoints" select="$numPoints"/>
        <xsl:with-param name="primarySeries" select="$primarySeries"/>
      </xsl:call-template>
    </xsl:for-each>

    <c:axId val="110226048"/>
    <c:axId val="110498176"/>

  </xsl:template>

  <xsl:template name="InsertSecondaryChartSeries">
    <!-- @Description: Outputs chart series and their values -->
    <!-- @Context: table:table-rows -->

    <xsl:param name="numSeries"/>
    <!-- (number) number of series inside chart -->
    <xsl:param name="numPoints"/>
    <!-- (number) maximum number of data point -->
    <xsl:param name="primarySeries"/>
    <xsl:param name="count" select="0"/>
    <!-- (number) loop counter -->

    <xsl:choose>
      <xsl:when test="$count &lt; $numSeries">
        <c:ser>
          <c:idx val="{$primarySeries + $count}"/>
          <c:order val="{$primarySeries + $count}"/>

          <!-- series name -->
          <c:tx>
            <c:v>
              <xsl:value-of
                select="key('header','')/table:table-row/table:table-cell[$primarySeries + $count + 2]"
              />
            </c:v>
          </c:tx>

          <xsl:call-template name="InsertSeriesShapeProperty">
            <xsl:with-param name="totalSeries" select="$numSeries"/>
            <xsl:with-param name="count" select="$primarySeries + $count"/>
          </xsl:call-template>

          <!-- insert data categories -->
          <c:cat>
            <c:strLit>
              <c:ptCount val="{$numPoints}"/>
              <xsl:for-each select="key('rows','')">
                <xsl:call-template name="InsertCategories">
                  <xsl:with-param name="numCategories" select="$numPoints"/>
                </xsl:call-template>
              </xsl:for-each>
            </c:strLit>
          </c:cat>

          <!-- series values -->
          <c:val>
            <c:numRef>
              <!-- TO DO: reference to sheet cell -->
              <!-- i.e. <c:f>Sheet1!$D$3:$D$4</c:f> -->
              <c:numCache>
                <c:formatCode>General</c:formatCode>
                <c:ptCount val="{$numPoints}"/>

                <!-- number of this series -->
                <xsl:variable name="thisSeries">
                  <xsl:value-of select="$primarySeries + $count"/>
                </xsl:variable>

                <xsl:for-each select="ancestor::chart:chart">
                  <xsl:for-each select="key('rows','')">
                    <xsl:call-template name="InsertPoints">
                      <xsl:with-param name="series" select="$thisSeries"/>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:for-each>
              </c:numCache>
            </c:numRef>
          </c:val>

          <!-- smooth line -->
          <xsl:for-each select="ancestor::chart:chart">
            <xsl:if test="@chart:class = 'chart:line' ">
              <xsl:for-each
                select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
                <xsl:if test="@chart:interpolation != 'none' ">
                  <c:smooth val="1"/>
                </xsl:if>
              </xsl:for-each>
            </xsl:if>
          </xsl:for-each>
        </c:ser>

        <xsl:call-template name="InsertSecondaryChartSeries">
          <xsl:with-param name="numSeries" select="$numSeries"/>
          <xsl:with-param name="numPoints" select="$numPoints"/>
          <xsl:with-param name="primarySeries" select="$primarySeries"/>
          <xsl:with-param name="count" select="$count + 1"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
