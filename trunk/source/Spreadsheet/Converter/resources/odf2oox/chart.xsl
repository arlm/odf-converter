﻿<?xml version="1.0" encoding="UTF-8"?>
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
<!--
Modification Log
LogNo. |Date       |ModifiedBy   |BugNo.   |Modification                                                      |
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
RefNo-1 19-Dec-2007 Sandeep S     1832369   Changes done to avoid crash, while converting column charts "combination Chart".  
RefNo-2 02-Jan-2008 Sandeep S     1797015   Changes done to fix the secondary y-axis and stock chart 3rd type problem.
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:pzip="urn:cleverage:xmlns:post-processings:zip"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
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
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
                  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0">

  <!-- @Filename: chart.xsl -->
  <!-- @Description: This stylesheet is used for charts conversion -->
  <!-- @Created: 2007-05-24 -->

  <!--<xsl:import href="number.xsl"/>
  <xsl:import href="gradient.xsl"/>-->



  <xsl:key name="numtextStyle" match="style:style" use="@style:data-style-name"/>
  <xsl:key name="number" match="number:number-style" use="@style:name"/>
  <xsl:key name="rows" match="table:table-rows" use="''"/>
  <xsl:key name="header" match="table:table-header-rows" use="''"/>
  <xsl:key name="series" match="chart:series" use="''"/>
  <xsl:key name="style" match="office:automatic-styles/child::node()" use="@style:name"/>
  <xsl:key name="chart" match="chart:chart" use="''"/>

  <xsl:template name="CreateChartFile">
    <!-- @Description: Searches for all charts within sheet and creates output chart files. -->
    <!-- @Context: table:table -->

    <xsl:param name="sheetNum"/>
    <!-- (number) sheet number -->

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

    <xsl:if test="contains($chart, 'true')">
      <xsl:for-each
        select="descendant::draw:frame/draw:object[document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart]">

        <xsl:variable name="chartDirectory">
          <xsl:value-of select="translate(@xlink:href,'./','')"/>
        </xsl:variable>

        <xsl:variable name="chartNum">
          <xsl:value-of select="position()"/>
        </xsl:variable>

        <!-- insert chart file content -->
        <xsl:for-each
          select="document(concat(translate(@xlink:href,'./',''),'/content.xml'))/office:document-content/office:body/office:chart">
          <pzip:entry pzip:target="{concat('xl/charts/chart',$sheetNum,'_',$chartNum,'.xml')}">

            <c:chartSpace>
              <c:lang val="pl-PL"/>

              <xsl:for-each select="chart:chart">
                <xsl:call-template name="InsertChart">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>
                <!-- chart area properties -->
                <xsl:call-template name="InsertSpPr">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                  <xsl:with-param name="defaultFill" select="'solid'"/>
                </xsl:call-template>
              </xsl:for-each>

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
          </pzip:entry>

          <xsl:call-template name="CreateChartRelationships">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            <xsl:with-param name="chartFile">
              <xsl:value-of select="concat('chart',$sheetNum,'_',$chartNum)"/>
            </xsl:with-param>
          </xsl:call-template>

        </xsl:for-each>


      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template name="CreateChartRelationships">
    <xsl:param name="chartFile"/>
    <xsl:param name="chartDirectory"/>

    <!-- check if there is bitmap fill -->
    <xsl:if
      test="/office:document-content/office:automatic-styles/style:style/style:graphic-properties[@draw:fill = 'bitmap' ]">
      <pzip:entry pzip:target="{concat('xl/charts/_rels/',$chartFile,'.xml.rels')}">
        <xsl:call-template name="InsertChartRels">
          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        </xsl:call-template>
      </pzip:entry>
    </xsl:if>

  </xsl:template>

  <xsl:template name="InsertChart">
    <!-- @Description: Writes chart definition to output chart file. -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartDirectory"/>

    <xsl:variable name="chartWidth">
      <xsl:value-of select="substring-before(@svg:width,'cm')"/>
    </xsl:variable>

    <xsl:variable name="chartHeight">
      <xsl:value-of select="substring-before(@svg:height,'cm')"/>
    </xsl:variable>

    <c:chart>
      <xsl:for-each select="chart:title">
        <xsl:call-template name="InsertTitle">
          <xsl:with-param name="chartWidth" select="$chartWidth"/>
          <xsl:with-param name="chartHeight" select="$chartHeight"/>
          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        </xsl:call-template>
      </xsl:for-each>

      <xsl:call-template name="InsertView3D"/>

      <xsl:call-template name="InsertPlotArea">
        <xsl:with-param name="chartWidth" select="$chartWidth"/>
        <xsl:with-param name="chartHeight" select="$chartHeight"/>
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
      </xsl:call-template>

      <xsl:call-template name="InsertLegend">
        <xsl:with-param name="chartWidth" select="$chartWidth"/>
        <xsl:with-param name="chartHeight" select="$chartHeight"/>
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
      </xsl:call-template>

      <xsl:call-template name="InsertAdditionalProperties"/>
    </c:chart>
  </xsl:template>

  <xsl:template name="InsertTitle">
    <!-- @Description: Inserts chart title -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>
    <xsl:param name="chartDirectory"/>

    <c:title>
      <c:tx>
        <c:rich>
          <a:bodyPr>
            <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
              <xsl:call-template name="InsertTextRotation"/>
            </xsl:for-each>
          </a:bodyPr>
          <a:lstStyle/>

          <a:p>
            <a:pPr>
              <a:defRPr sz="1300" b="0" i="0" u="none" strike="noStrike" baseline="0">

                <xsl:for-each select="key('style',@chart:style-name)/style:text-properties">
                  <xsl:call-template name="InsertRunProperties"/>
                </xsl:for-each>

              </a:defRPr>
            </a:pPr>
            <a:r>
              <a:rPr lang="pl-PL"/>
              <a:t>
                <xsl:value-of xml:space="preserve" select="text:p"/>
              </a:t>
            </a:r>
          </a:p>
        </c:rich>
      </c:tx>

      <!-- manual layout commented because lack of reverse conversion -->
      <c:layout>
        <!--c:manualLayout>
          <c:xMode val="edge"/>
          <c:yMode val="edge"/>

          <xsl:call-template name="InsideChartPosition">
            <xsl:with-param name="chartWidth" select="$chartWidth"/>
            <xsl:with-param name="chartHeight" select="$chartHeight"/>
          </xsl:call-template>

        </c:manualLayout-->
      </c:layout>

      <xsl:call-template name="InsertSpPr">
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
      </xsl:call-template>

    </c:title>
  </xsl:template>

  <xsl:template name="InsertPlotArea">
    <!-- @Description: Outputs chart plot area -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>
    <xsl:param name="chartDirectory"/>

    <xsl:variable name="chartType">
      <xsl:value-of select="@chart:class"/>
    </xsl:variable>

    <xsl:for-each select="chart:plot-area">

      <xsl:variable name="plotXOffset">
        <xsl:value-of select="substring-before(@svg:x,'cm' ) div $chartWidth"/>
      </xsl:variable>

      <xsl:variable name="plotYOffset">
        <xsl:value-of select="substring-before(@svg:y,'cm' ) div $chartHeight "/>
      </xsl:variable>

      <c:plotArea>
        <!-- best results are when position is default -->
        <c:layout/>

        <!--c:layout>
          <c:manualLayout>
            <c:layoutTarget val="inner"/>
            <c:xMode val="edge"/>
            <c:yMode val="edge"/>

            <xsl:call-template name="InsideChartPosition">
              <xsl:with-param name="chartWidth" select="$chartWidth"/>
              <xsl:with-param name="chartHeight" select="$chartHeight"/>
            </xsl:call-template-->

        <!--c:x val="0.10452961672473868"/>
          <c:y val="0.24334600760456274"/>
          <c:w val="0.68641114982578355"/>
          <c:h val="0.60836501901140683"/-->
        <!--/c:manualLayout>
        </c:layout-->

        <!-- change context to chart:chart and insert chart type -->
        <xsl:for-each select="parent::node()">
          <xsl:call-template name="InsertChartType">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </xsl:for-each>

        <!-- secondary charts -->
        <xsl:choose>
          <!-- line chart for 'bar chart with lines' -->
          <!--Start of RefNo-1-->
          <!--<xsl:when
            test="$chartType = 'chart:bar' and key('series','')[@chart:class = 'chart:line' ]">
            <xsl:for-each select="parent::node()">
              <c:lineChart>
                <c:grouping val="standard"/>

                <xsl:call-template name="InsertSecondaryChartContent">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>

              </c:lineChart>
            </xsl:for-each>
          </xsl:when>-->
          <!--End of RefNo-1-->
          <!-- bar chart for 'stock chart with bar'  (StockChart 3&4) -->
          <xsl:when
            test="$chartType = 'chart:scatter' and key('series','')[@chart:class = 'chart:bar' ]">
            <xsl:for-each select="parent::node()">
              <c:barChart>
                <c:grouping val="standard"/>

                <xsl:call-template name="InsertSecondaryChartContent">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>

              </c:barChart>
            </xsl:for-each>
          </xsl:when>
          <!-- secondary axis case (eliminate for now case when third chart is required - bar chart with lines and secondary axis) -->
          <!-- 'chart:stock' condition is temporary till this chart type is properly conversed -->
          <!--Start of RefNo-2:uncommented the code-->
          <xsl:when
            test="key('series','')[@chart:attached-axis = 'secondary-y'] and not(key('series','')[@chart:attached-axis = 'secondary-y' and @chart:class])">
            <xsl:for-each select="parent::node()">
              <!--Start of RefNo-2:Check for min. no. of cols in case of stock 3 & 4-->
              <xsl:choose>
                <xsl:when test="@chart:class='chart:stock' and count(key('series','')) &lt; 4">
                  <!--<xsl:message terminate="no">translation.odf2oox.StockChartType3</xsl:message>-->
                </xsl:when>
                <xsl:otherwise>
                  <xsl:call-template name="InsertChartType">
                    <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                    <xsl:with-param name="priority">
                      <xsl:text>secondary</xsl:text>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <!--End of RefNo-2-->
            </xsl:for-each>
          </xsl:when>
          <!--End of RefNo-2-->
        </xsl:choose>

        <xsl:if
          test="not(key('chart','')/@chart:class = 'chart:circle' or key('chart','')/@chart:class = 'chart:ring' )">

          <!-- primary X axis -->
          <xsl:for-each select="chart:axis[@chart:name = 'primary-x' ]">
            <xsl:if test="position()=1">
            <xsl:choose>
              <!-- scater chart has value axis-X-->
              <xsl:when test="key('chart','')/@chart:class = 'chart:scatter' ">
                <c:valAx>
                  <xsl:call-template name="InsertAxisX">
                    <xsl:with-param name="chartWidth" select="$chartWidth"/>
                    <xsl:with-param name="chartHeight" select="$chartHeight"/>
                    <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                    <xsl:with-param name="priority">
                      <xsl:text>primary</xsl:text>
                    </xsl:with-param>
                    <xsl:with-param name="type">
                      <xsl:text>valAx</xsl:text>
                    </xsl:with-param>
                  </xsl:call-template>
                </c:valAx>
              </xsl:when>
              <xsl:otherwise>
                <c:catAx>
                  <xsl:call-template name="InsertAxisX">
                    <xsl:with-param name="chartWidth" select="$chartWidth"/>
                    <xsl:with-param name="chartHeight" select="$chartHeight"/>
                    <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                    <xsl:with-param name="priority">
                      <xsl:text>primary</xsl:text>
                    </xsl:with-param>
                    <xsl:with-param name="type">
                      <xsl:text>catAx</xsl:text>
                    </xsl:with-param>
                  </xsl:call-template>
                </c:catAx>
              </xsl:otherwise>
            </xsl:choose>
            </xsl:if>
          </xsl:for-each>

          <!-- primary Y axis -->
          <xsl:for-each select="chart:axis[@chart:name='primary-y']">
            <xsl:call-template name="InsertAxisY">
              <xsl:with-param name="chartWidth" select="$chartWidth"/>
              <xsl:with-param name="chartHeight" select="$chartHeight"/>
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              <xsl:with-param name="priority">
                <xsl:text>primary</xsl:text>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>

          <!--Commented by Sateesh Because temp.ods,estads.ods,mallocs.ods files are crashing -->
          <!-- 'chart:stock' condition is temporary till this chart type is properly conversed -->
          <!--Start of RefNo-2:uncommented the code and Added condition to chk wheather any series is attached to seconday-y-axis.-->
          <xsl:if test="chart:axis[contains(@chart:name,'secondary')]">
            <xsl:if
              test="key('series','')[@chart:attached-axis = 'secondary-y'] and not(key('series','')[@chart:attached-axis = 'secondary-y' and @chart:class])">
              <!--secondary Y axis-->
              <xsl:choose>
                <xsl:when test="$chartType = 'chart:stock' and count(key('series','')) &lt; 4">
                  <!--<xsl:message terminate="no">translation.odf2oox.StockChartType3</xsl:message>-->
                </xsl:when>
                <xsl:otherwise>
                  <xsl:choose>
                    <xsl:when test="chart:axis[@chart:name='secondary-y']">
                      <xsl:for-each select="chart:axis[@chart:name='secondary-y']">
                        <xsl:call-template name="InsertAxisY">
                          <xsl:with-param name="chartWidth" select="$chartWidth"/>
                          <xsl:with-param name="chartHeight" select="$chartHeight"/>
                          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                          <xsl:with-param name="priority">
                            <xsl:text>secondary</xsl:text>
                          </xsl:with-param>
                        </xsl:call-template>
                      </xsl:for-each>
                    </xsl:when>
                    <!--hidden default axis-->
                    <xsl:otherwise>
                      <c:valAx>
                        <c:axId val="104461824"/>
                        <c:scaling>
                          <c:orientation val="minMax"/>
                        </c:scaling>
                        <c:delete val="1"/>
                        <c:axPos val="r"/>
                        <c:numFmt formatCode="General" sourceLinked="0"/>
                        <c:tickLblPos val="nextTo"/>
                        <c:crossAx val="104425728"/>
                        <c:crosses val="max"/>
                        <c:crossBetween val="between"/>
                      </c:valAx>
                    </xsl:otherwise>
                  </xsl:choose>
                  <!--secondary X axis (there can't be one in Calc?)-->
                  <!--default axes-->
                  <xsl:choose>
                    <!--scater chart has value axis-X-->
                    <xsl:when test="key('chart','')/@chart:class = 'chart:scatter' ">
                      <c:valAx>
                        <c:axId val="104425728"/>
                        <c:scaling>
                          <c:orientation val="minMax"/>
                        </c:scaling>
                        <c:delete val="1"/>
                        <c:axPos val="t"/>
                        <c:numFmt formatCode="General" sourceLinked="1"/>
                        <c:tickLblPos val="nextTo"/>
                        <c:crossAx val="104461824"/>
                        <c:crossBetween val="midCat"/>
                      </c:valAx>
                    </xsl:when>
                    <xsl:otherwise>
                      <c:catAx>
                        <c:axId val="104425728"/>
                        <c:scaling>
                          <c:orientation val="minMax"/>
                        </c:scaling>
                        <c:delete val="1"/>
                        <c:axPos val="t"/>
                        <c:tickLblPos val="nextTo"/>
                        <c:crossAx val="104461824"/>
                        <c:auto val="1"/>
                        <c:lblAlgn val="ctr"/>
                        <c:lblOffset val="100"/>
                      </c:catAx>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:if>
          <!--End of RefNo-2-->
        </xsl:if>

        <!-- for the Radar Chart  in OOo < 2.3 -->
        <xsl:if
          test="key('chart','')/@chart:class='chart:radar' and not(key('chart','')/chart:plot-area/chart:axis/chart:categories) and not(key('chart','')/chart:plot-area/chart:axis[@chart:dimension = 'x' ])">
          <xsl:for-each select="chart:axis[@chart:dimension = 'y' ]">
            <xsl:if test="position()=1">
            <c:catAx>
              <xsl:call-template name="InsertAxisX">
                <xsl:with-param name="chartWidth" select="$chartWidth"/>
                <xsl:with-param name="chartHeight" select="$chartHeight"/>
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="priority">
                  <xsl:text>primary</xsl:text>
                </xsl:with-param>
                <xsl:with-param name="type">
                  <xsl:text>catAx</xsl:text>
                </xsl:with-param>
              </xsl:call-template>
            </c:catAx>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>

        <!-- plot area graphic properties -->
        <xsl:for-each select="chart:wall">
          <xsl:call-template name="InsertSpPr">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            <xsl:with-param name="defaultFill" select="'solid'"/>
          </xsl:call-template>
        </xsl:for-each>

      </c:plotArea>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertLegend">
    <!-- @Description: Inserts chart legend. -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>
    <xsl:param name="chartDirectory"/>

    <xsl:for-each select="chart:legend">
      <c:legend>
        <c:legendPos val="r">
          <xsl:attribute name="val">
            <xsl:choose>
              <xsl:when test="@chart:legend-position = 'end' ">
                <xsl:text>r</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:legend-position = 'bottom' ">
                <xsl:text>b</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:legend-position = 'top' ">
                <xsl:text>t</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:legend-position = 'start' ">
                <xsl:text>l</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </c:legendPos>
        <c:layout>
          <!--c:manualLayout>
            <c:xMode val="edge"/>
            <c:yMode val="edge"/>

            <xsl:call-template name="InsideChartPosition">
              <xsl:with-param name="chartWidth" select="$chartWidth"/>
              <xsl:with-param name="chartHeight" select="$chartHeight"/>
            </xsl:call-template>

          </c:manualLayout-->
        </c:layout>

        <xsl:call-template name="InsertSpPr">
          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        </xsl:call-template>

        <c:txPr>
          <a:bodyPr/>
          <a:lstStyle/>
          <a:p>
            <a:pPr>
              <a:defRPr sz="550" b="0" i="0" u="none" strike="noStrike" baseline="0">

                <xsl:for-each select="key('style',@chart:style-name)/style:text-properties">
                  <xsl:call-template name="InsertRunProperties"/>
                </xsl:for-each>

              </a:defRPr>
            </a:pPr>
            <a:endParaRPr lang="pl-PL"/>
          </a:p>
        </c:txPr>
      </c:legend>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertAdditionalProperties">

    <c:dispBlanksAs val="gap"/>
  </xsl:template>

  <xsl:template name="InsertChartType">
    <!-- @Description: Inserts appriopiate type of chart -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartDirectory"/>
    <xsl:param name="priority" select="'primary'"/>

    <xsl:choose>
      <xsl:when
        test="@chart:class='chart:bar' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
        <c:bar3DChart>

          <!-- bar or column chart -->
          <xsl:choose>
            <xsl:when
              test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:vertical = 'true' ">
              <c:barDir val="bar"/>
            </xsl:when>
            <xsl:otherwise>
              <c:barDir val="col"/>
            </xsl:otherwise>
          </xsl:choose>

          <c:grouping val="clustered">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

          <!-- set shape -->
          <c:shape val="box">
            <xsl:if
              test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:solid-type != 'cuboid' ">
              <xsl:attribute name="val">
                <xsl:value-of
                  select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:solid-type"
                />
              </xsl:attribute>
            </xsl:if>
          </c:shape>

        </c:bar3DChart>
      </xsl:when>
      <xsl:when test="@chart:class='chart:bar' ">
        <c:barChart>

          <!-- bar or column chart -->
          <xsl:choose>
            <xsl:when
              test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:vertical = 'true' ">
              <c:barDir val="bar"/>
            </xsl:when>
            <xsl:otherwise>
              <c:barDir val="col"/>
            </xsl:otherwise>
          </xsl:choose>

          <c:grouping val="clustered">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

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

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:line3DChart>
      </xsl:when>
      <xsl:when test="@chart:class='chart:line' ">
        <c:lineChart>


          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:lineChart>
      </xsl:when>

      <xsl:when
        test="@chart:class='chart:area' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
        <c:area3DChart>

          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:area3DChart>
      </xsl:when>
      <xsl:when test="@chart:class='chart:area' ">
        <c:areaChart>

          <c:grouping val="standard">
            <xsl:call-template name="SetDataGroupingAtribute"/>
          </c:grouping>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:areaChart>
      </xsl:when>

      <xsl:when
        test="@chart:class='chart:circle' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
        <c:pie3DChart>
          <c:varyColors val="1"/>
          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </c:pie3DChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:circle' ">
        <c:pieChart>
          <c:varyColors val="1"/>
          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </c:pieChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:ring' ">
        <c:doughnutChart>
          <c:varyColors val="1"/>
          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
          <c:firstSliceAng val="0"/>
          <c:holeSize val="50"/>
        </c:doughnutChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:radar' ">
        <c:radarChart>
          <c:radarStyle val="marker"/>
          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </c:radarChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:scatter' ">
        <c:scatterChart>
          <c:scatterStyle val="lineMarker"/>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:scatterChart>
      </xsl:when>

      <!-- Stock Chart 3&4 (volume series) -->
      <xsl:when
        test="@chart:class='chart:stock'  and key('series','')[1][@chart:class = 'chart:bar'] and $priority = 'primary' ">
        <c:barChart>
          <c:barDir val="col"/>
          <c:grouping val="clustered"/>

          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>

        </c:barChart>
      </xsl:when>

      <xsl:when test="@chart:class='chart:stock' ">
        <c:stockChart>

          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:call-template name="InsertChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartContent">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="cause" select="'secondary-axis'"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>

        </c:stockChart>
      </xsl:when>

      <!-- temporary otherwise eventually none -->
      <xsl:otherwise>
        <c:barChart>
          <c:barDir val="col"/>
          <c:grouping val="clustered"/>
          <xsl:call-template name="InsertChartContent">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </c:barChart>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertChartContent">
    <!-- @Description: Inserts chart content -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartDirectory"/>

    <xsl:variable name="seriesFrom">
      <xsl:value-of
        select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:series-source"
      />
    </xsl:variable>

    <xsl:variable name="chartType">
      <xsl:value-of select="@chart:class"/>
    </xsl:variable>

    <xsl:variable name="numSeries">
      <!-- (number) number of series inside chart -->
      <!--Start of RefNo-1
      <xsl:value-of select="count(key('series','')[not(@chart:class)])"/>
      -->
      <xsl:choose>
        <xsl:when
          test="@chart:class = 'chart:bar' and key('series','')[@chart:class = 'chart:line' ]">
          <xsl:value-of select="count(key('series',''))"/>
          <xsl:message terminate="no">translation.odf2oox.BarLineCombinationChart</xsl:message>
        </xsl:when>
        <!-- ring chart series in OO 2.4 have in chart:class attribute 'chart:circle' value -->
        <xsl:when test="$chartType = 'chart:ring' ">
          <xsl:value-of
            select="count(key('series','')[not(@chart:class != 'chart:ring' and @chart:class != 'chart:circle' )])"
          />
        </xsl:when>
<!-- excel will support maximum 4 series for stock charts -->
        <xsl:when test="$chartType = 'chart:stock' ">
          <xsl:value-of  select="'4'"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- (number) number of series inside chart -->
          <xsl:value-of select="count(key('series','')[not(@chart:class != $chartType)])"/>
        </xsl:otherwise>
      </xsl:choose>
      <!--End of RefNo-1-->
    </xsl:variable>

    <xsl:variable name="numPoints">
      <!-- (number) maximum number of data point -->
      <xsl:choose>
        <!-- for chart with swapped data sources -->
        <xsl:when test="$seriesFrom='rows'">
          <xsl:call-template name="MaxPointNumber">
            <xsl:with-param name="rowNumber">
              <xsl:value-of select="1"/>
            </xsl:with-param>
            <xsl:with-param name="CountCellsInRow">
              <xsl:value-of
                select="count(key('rows','')/table:table-row[1]/table:table-cell[@office:value-type != 'string'])"
              />
            </xsl:with-param>
            <xsl:with-param name="maxValue">
              <xsl:value-of select="1"/>
            </xsl:with-param>
            <xsl:with-param name="rowsQuantity">
              <xsl:value-of select="count(key('rows','')/table:table-row)"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="count(key('rows','')/table:table-row)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="reverseCategories">
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <!-- reverse categories for: (pie charts) or (ring charts) or (2D bar charts stacked or percentage) -->
          <xsl:when
            test="(key('chart','')/@chart:class = 'chart:circle' ) or (key('chart','')/@chart:class = 'chart:ring' ) or 
            (@chart:vertical = 'true' and not(@chart:three-dimensional = 'true') )">
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
          <!-- reverse series for: (2D normal bar chart) or (2D normal area chart) or (ring:chart) -->
          <xsl:when
            test="(@chart:vertical = 'true' and not(@chart:stacked = 'true' or @chart:percentage = 'true' ) and not(@chart:three-dimensional = 'true' ) ) or 
            (key('chart','')/@chart:class = 'chart:area' and not(@chart:stacked = 'true' or @chart:percentage = 'true' ) and not(@chart:three-dimensional = 'true') ) or
            (key('chart','')/@chart:class = 'chart:ring')">
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
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
        <xsl:with-param name="chartType" select="$chartType"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:if
      test="key('style',chart:plot-area/chart:series/@chart:style-name)/style:chart-properties/@chart:data-label-number = 'value' or 
      key('style',chart:plot-area/chart:series/@chart:style-name)/style:chart-properties/@chart:data-label-text = 'true' ">
      <c:dLbls>
        <c:showVal val="1"/>
      </c:dLbls>
    </xsl:if>

    <!-- only for stock chart 1&2 -->
    <xsl:if test="$chartType = 'chart:stock' and not(key('series','')/@chart:class)">
      <c:hiLowLines>
        <xsl:for-each select="chart:plot-area/chart:stock-range-line">
          <xsl:call-template name="InsertSpPr">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </xsl:for-each>
      </c:hiLowLines>

      <!-- stock gain/loss bars -->
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)">
        <xsl:if test="style:chart-properties/@chart:japanese-candle-stick = 'true' ">
          <c:upDownBars>
            <c:gapWidth val="150"/>

            <c:upBars>
              <xsl:for-each select="chart:plot-area/chart:stock-gain-marker">
                <xsl:call-template name="InsertSpPr">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>
              </xsl:for-each>
            </c:upBars>

            <c:downBars>
              <xsl:for-each select="chart:plot-area/chart:stock-loss-marker">
                <xsl:call-template name="InsertSpPr">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>
              </xsl:for-each>
            </c:downBars>

          </c:upDownBars>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>

    <c:axId val="104463360"/>
    <c:axId val="104460288"/>

  </xsl:template>

  <xsl:template name="InsertAxisX">
    <!-- @Description: Inserts X-Axis -->
    <!-- @Context: chart:chart-axis -->
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>
    <xsl:param name="chartDirectory"/>
    <xsl:param name="priority"/>
    <xsl:param name="type"/>

    <xsl:choose>
      <!-- primary X id -->
      <xsl:when test="$priority = 'primary' ">
        <c:axId val="104463360"/>
      </xsl:when>
      <!-- secondary X id -->
      <xsl:otherwise>
        <c:axId val="104425728"/>
      </xsl:otherwise>
    </xsl:choose>

    <c:scaling>
      <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
        <xsl:if test="@chart:logarithmic = 'true' and $type = 'valAx' ">
          <c:logBase val="10"/>
        </xsl:if>

				<xsl:if test="(@chart:reverse-direction='true') and (($type = 'valAx') or ($type = 'catAx'))">
					<c:orientation val="maxMin"/>
				</xsl:if>
				<xsl:if test="@chart:reverse-direction='false' and (($type = 'valAx') or ($type = 'catAx'))">
      <c:orientation val="minMax"/>
				</xsl:if>	

      </xsl:for-each>
<!--
      <c:orientation val="minMax"/>
-->

      <!-- axis min and max value -->
      <xsl:if test="$type = 'valAx' ">
        <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
          <xsl:if test="@chart:maximum">
            <c:max>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:maximum"/>
              </xsl:attribute>
            </c:max>
          </xsl:if>
          <xsl:if test="@chart:minimum">
            <c:min>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:minimum"/>
              </xsl:attribute>
            </c:min>
          </xsl:if>
        </xsl:for-each>
      </xsl:if>
    </c:scaling>

    <!-- axis position -->
    <!-- key('chart','')[1] is the office:chart element,  key('chart','')[2] is the chart:chart element -->
    <xsl:for-each select="key('chart','')[2]">
      <xsl:choose>
        <!-- Edited by Sonata:for bar charts -->
        <xsl:when
				  test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:vertical = 'true' ">
          <xsl:choose>
            <xsl:when test="$priority = 'primary'">
              <c:axPos val="l"/>
            </xsl:when>
            <xsl:otherwise>
              <c:axPos val="r"/>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:when>
       <!-- Edited by Sonata:for bar charts -->
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$priority = 'primary'">
              <c:axPos val="b"/>
            </xsl:when>
            <xsl:otherwise>
              <c:axPos val="t"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>

    <!--Sonata:major grid lines -->
    <xsl:choose>
      <xsl:when test="chart:grid[@chart:class='major']">
        <xsl:for-each select="chart:grid[@chart:class='major']">
          <c:majorGridlines>
            <xsl:call-template name="InsertSpPr">
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            </xsl:call-template>
          </c:majorGridlines>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="key('chart','')/@chart:class = 'chart:radar' ">
        <c:majorGridlines/>
      </xsl:when>
    </xsl:choose>
    <!--Sonata:minor grid lines -->
    <xsl:choose>
      <xsl:when test="chart:grid[@chart:class='minor']">
        <xsl:for-each select="chart:grid[@chart:class='minor']">
          <c:minorGridlines>
            <xsl:call-template name="InsertSpPr">
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            </xsl:call-template>
          </c:minorGridlines>
        </xsl:for-each>
      </xsl:when>
      <!--<xsl:when test="key('chart','')/@chart:class = 'chart:radar' ">
        <c:minorGridlines/>
      </xsl:when>-->
    </xsl:choose>


    <!-- axis title -->
    <xsl:for-each select="chart:title">
      <xsl:call-template name="InsertTitle">
        <xsl:with-param name="chartWidth" select="$chartWidth"/>
        <xsl:with-param name="chartHeight" select="$chartHeight"/>
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
      </xsl:call-template>
    </xsl:for-each>

   <!-- <c:numFmt formatCode="General" sourceLinked="1"/>-->

    <!--c:numFmt formatCode="General">
      <xsl:choose>
        <xsl:when test="not(key('style',@chart:style-name)/@style:data-style-name)">
          <xsl:attribute name="sourceLinked">
            <xsl:text>1</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="key('style',@chart:style-name)">
            <xsl:variable name="styles">
              <xsl:value-of select="concat(@style:data-style-name,';',@style:data-style-name,'P0;',@style:data-style-name,'P1;',@style:data-style-name,'P2;')"/>
            </xsl:variable>
            <xsl:for-each select="/office:document-content/office:automatic-styles[1]">
              <xsl:apply-templates select="." mode="numFormat"/>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </c:numFmt-->
<xsl:for-each select="key('style',@chart:style-name)">
            <xsl:variable name="styles">
              <xsl:value-of select="concat(@style:data-style-name,';',@style:data-style-name,'P0;',@style:data-style-name,'P1;',@style:data-style-name,'P2;')"/>
            </xsl:variable>
      <xsl:for-each select="key('style',@style:data-style-name)">
        <xsl:apply-templates select="." mode="ChartnumFormat"/>
            </xsl:for-each>
          </xsl:for-each>

    <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
      <xsl:if
        test="@chart:tick-marks-major-inner and not (@chart:tick-marks-major-inner = 'false' and @chart:tick-marks-major-outer = 'true' )">
        <c:majorTickMark>
          <xsl:attribute name="val">
            <xsl:choose>
              <xsl:when
                test="@chart:tick-marks-major-inner = 'true' and @chart:tick-marks-major-outer = 'true' ">
                <xsl:text>cross</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:tick-marks-major-inner = 'true' ">
                <xsl:text>in</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:tick-marks-major-outer = 'true' ">
                <xsl:text>out</xsl:text>
              </xsl:when>
              <xsl:when
                test="@chart:tick-marks-major-inner = 'false' and @chart:tick-marks-major-outer = 'false' ">
                <xsl:text>none</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </c:majorTickMark>
      </xsl:if>

      <xsl:if
        test="@chart:tick-marks-minor-inner = 'true' or @chart:tick-marks-minor-outer = 'true' ">
        <c:minorTickMark>
          <xsl:attribute name="val">
            <xsl:choose>
              <xsl:when
                test="@chart:tick-marks-minor-inner = 'true' and @chart:tick-marks-minor-outer = 'true' ">
                <xsl:text>cross</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:tick-marks-minor-inner = 'true' ">
                <xsl:text>in</xsl:text>
              </xsl:when>
              <xsl:when test="@chart:tick-marks-minor-outer = 'true' ">
                <xsl:text>out</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </c:minorTickMark>
      </xsl:if>
    </xsl:for-each>

    <xsl:choose>
      <xsl:when test="key('style',@chart:style-name)/style:chart-properties/@chart:label-arrangement='side-by-side'">
        <c:tickLblPos val="nextTo"/>
      </xsl:when>
      <xsl:otherwise>
    <c:tickLblPos val="low">
      <xsl:if
        test="key('style',@chart:style-name)/style:chart-properties/@chart:display-label = 'false' ">
        <xsl:attribute name="val">
          <xsl:text>none</xsl:text>
        </xsl:attribute>
      </xsl:if>
    </c:tickLblPos>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if
      test="key('style',@chart:style-name)/style:chart-properties/@chart:display-label = 'true' ">

      <xsl:call-template name="InsertSpPr">
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
      </xsl:call-template>

      <c:txPr>
        <a:bodyPr rot="0" vert="horz">
          <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
            <xsl:call-template name="InsertTextRotation"/>
          </xsl:for-each>
        </a:bodyPr>
        <a:lstStyle/>
        <a:p>
          <a:pPr>
            <a:defRPr>

              <xsl:for-each select="key('style',@chart:style-name)/style:text-properties">
                <!-- template common with text-box-->
                <xsl:call-template name="InsertRunProperties"/>
              </xsl:for-each>

            </a:defRPr>
          </a:pPr>
          <a:endParaRPr lang="pl-PL"/>
        </a:p>
      </c:txPr>
    </xsl:if>

    <xsl:choose>
      <!-- primary Y id -->
      <xsl:when test="$priority = 'primary' ">
        <c:crossAx val="104460288"/>
      </xsl:when>
      <!-- secondary Y id -->
      <xsl:otherwise>
        <c:crossAx val="104461824"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:for-each
      select="key('style',parent::node()/chart:axis[@chart:name = 'primary-y']/@chart:style-name)/style:chart-properties[@chart:origin != '' ]">
      <c:crossesAt val="0">
        <xsl:attribute name="val">
          <xsl:choose>
            <xsl:when test="@chart:origin">
              <xsl:value-of select="@chart:origin"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>0</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </c:crossesAt>
    </xsl:for-each>

    <xsl:if test="$type = 'valAx' ">
      <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <xsl:when test="@chart:interval-major">
            <c:majorUnit>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:interval-major"/>
              </xsl:attribute>
            </c:majorUnit>
            <xsl:if test="@chart:interval-minor-divisor">
              <c:minorUnit>
                <xsl:attribute name="val">
                  <xsl:value-of select="@chart:interval-major div @chart:interval-minor-divisor"/>
                </xsl:attribute>
              </c:minorUnit>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="@chart:interval-minor-divisor">
              <c:minorUnit>
                <xsl:attribute name="val">
                  <xsl:value-of select="@chart:maximum div @chart:interval-minor-divisor"/>
                </xsl:attribute>
              </c:minorUnit>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:if>

    <c:auto val="1"/>
    <c:lblAlgn val="ctr"/>
    <c:lblOffset val="100"/>
    <c:tickLblSkip val="1"/>
    <c:tickMarkSkip val="1"/>
  </xsl:template>

  <xsl:template name="InsertAxisY">
    <!-- @Description: Inserts Y-Axis -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>
    <xsl:param name="chartDirectory"/>
    <xsl:param name="priority"/>

    <c:valAx>

      <xsl:choose>
        <!-- primary Y id -->
        <xsl:when test="$priority = 'primary' ">
          <c:axId val="104460288"/>
        </xsl:when>
        <!-- secondary Y id -->
        <xsl:otherwise>
          <c:axId val="104461824"/>
        </xsl:otherwise>
      </xsl:choose>

      <c:scaling>
        <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
          <xsl:if test="@chart:logarithmic = 'true' ">
            <c:logBase val="10"/>
          </xsl:if>
					<xsl:choose>
						<xsl:when test="@chart:reverse-direction='true'">
							<c:orientation val="maxMin"/>
						</xsl:when>
						<xsl:when test="@chart:reverse-direction='false'">
        <c:orientation val="minMax"/>
						</xsl:when>
					</xsl:choose>
        </xsl:for-each>
 <!-- 
        <c:orientation val="minMax"/>
-->

        <!-- axis min and max value -->
        <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
          <xsl:if test="@chart:maximum">
            <c:max>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:maximum"/>
              </xsl:attribute>
            </c:max>
          </xsl:if>
          <xsl:if test="@chart:minimum">
            <c:min>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:minimum"/>
              </xsl:attribute>
            </c:min>
          </xsl:if>
        </xsl:for-each>
      </c:scaling>


      <xsl:for-each select="key('chart','')[2]">
        <xsl:choose>
          <!-- for bar charts -->
          <xsl:when
					  test="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:vertical = 'true' ">
            <xsl:choose>
              <xsl:when test="$priority = 'primary'">
                <c:axPos val="b"/>
              </xsl:when>
              <xsl:otherwise>
                <c:axPos val="t"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$priority = 'primary'">
          <c:axPos val="l"/>
        </xsl:when>
        <xsl:otherwise>
          <c:axPos val="r"/>
        </xsl:otherwise>
      </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

      <!--sonata:major grid lines -->
      <xsl:choose>
        <xsl:when test="chart:grid[@chart:class='major']">
          <xsl:for-each select="chart:grid[@chart:class='major']">
        <c:majorGridlines>
          <xsl:call-template name="InsertSpPr">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </c:majorGridlines>
      </xsl:for-each>
        </xsl:when>
        <xsl:when test="key('chart','')/@chart:class = 'chart:radar' ">
          <c:majorGridlines/>
        </xsl:when>
      </xsl:choose>
      <!--minor grid lines -->
      <xsl:choose>
        <xsl:when test="chart:grid[@chart:class='minor']">
          <xsl:for-each select="chart:grid[@chart:class='minor']">
            <c:minorGridlines>
              <xsl:call-template name="InsertSpPr">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              </xsl:call-template>
            </c:minorGridlines>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="key('chart','')/@chart:class = 'chart:radar' ">
          <c:minorGridlines/>
        </xsl:when>
      </xsl:choose>


      <xsl:if
        test="key('style',@chart:style-name)/style:chart-properties/@chart:display-label = 'true' ">
        <xsl:for-each select="chart:title">
          <xsl:call-template name="InsertTitle">
            <xsl:with-param name="chartWidth" select="$chartWidth"/>
            <xsl:with-param name="chartHeight" select="$chartHeight"/>
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:if>
      <!--code added by sonata for bug no 1806343-->
      <xsl:for-each select="key('style',@chart:style-name)">
        <xsl:variable name="styles">
          <xsl:value-of select="concat(@style:data-style-name,';',@style:data-style-name,'P0;',@style:data-style-name,'P1;',@style:data-style-name,'P2;')"/>
        </xsl:variable>
        <xsl:for-each select="key('style',@style:data-style-name)">
          <xsl:apply-templates select="." mode="ChartnumFormat"/>
        </xsl:for-each>
      </xsl:for-each>
      <!--<xsl:variable name="dataStyleName" select=" key('style',@chart:style-name)/@style:data-style-name"/>
      <xsl:for-each select="key('style',$dataStyleName)">
       <xsl:variable name="curSymbl">
          <xsl:value-of select="number:currency-symbol"/>
        </xsl:variable>

        <c:numFmt  sourceLinked="0">
          <xsl:attribute name="formatCode">
            <xsl:choose>
              <xsl:when test="$curSymbl !=''">
                <xsl:value-of select="concat('&quot;',$curSymbl,'&quot;','#,##0.00')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'General'"/>
              </xsl:otherwise>
            </xsl:choose>

          </xsl:attribute>
        </c:numFmt>
      </xsl:for-each>-->
      <!--end-->



      <!--<c:numFmt formatCode="General" sourceLinked="0"/>-->

      <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
        <xsl:if
          test="@chart:tick-marks-major-inner and not (@chart:tick-marks-major-inner = 'false' and @chart:tick-marks-major-outer = 'true' )">
          <c:majorTickMark>
            <xsl:attribute name="val">
              <xsl:choose>
                <xsl:when
                  test="@chart:tick-marks-major-inner = 'true' and @chart:tick-marks-major-outer = 'true' ">
                  <xsl:text>cross</xsl:text>
                </xsl:when>
                <xsl:when test="@chart:tick-marks-major-inner = 'true' ">
                  <xsl:text>in</xsl:text>
                </xsl:when>
                <xsl:when test="@chart:tick-marks-major-outer = 'true' ">
                  <xsl:text>out</xsl:text>
                </xsl:when>
                <xsl:when
                  test="@chart:tick-marks-major-inner = 'false' and @chart:tick-marks-major-outer = 'false' ">
                  <xsl:text>none</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </c:majorTickMark>
        </xsl:if>

        <xsl:if
          test="@chart:tick-marks-minor-inner = 'true' or @chart:tick-marks-minor-outer = 'true' ">
          <c:minorTickMark>
            <xsl:attribute name="val">
              <xsl:choose>
                <xsl:when
                  test="@chart:tick-marks-minor-inner = 'true' and @chart:tick-marks-minor-outer = 'true' ">
                  <xsl:text>cross</xsl:text>
                </xsl:when>
                <xsl:when test="@chart:tick-marks-minor-inner = 'true' ">
                  <xsl:text>in</xsl:text>
                </xsl:when>
                <xsl:when test="@chart:tick-marks-minor-outer = 'true' ">
                  <xsl:text>out</xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:attribute>
          </c:minorTickMark>
        </xsl:if>
      </xsl:for-each>

      <!--<c:tickLblPos val="low">
        <xsl:attribute name="val">
          <xsl:choose>
            <xsl:when test="$priority = 'primary' ">
              <xsl:text>low</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>nextTo</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>-->

      <c:tickLblPos val="nextTo">
        <xsl:if
          test="key('style',@chart:style-name)/style:chart-properties/@chart:display-label = 'false' ">
          <xsl:attribute name="val">
            <xsl:text>none</xsl:text>
          </xsl:attribute>
        </xsl:if>
      </c:tickLblPos>

      <xsl:if
        test="key('style',@chart:style-name)/style:chart-properties/@chart:display-label = 'true' ">

        <xsl:call-template name="InsertSpPr">
          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        </xsl:call-template>

        <c:txPr>
          <a:bodyPr rot="0" vert="horz">
            <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
              <xsl:call-template name="InsertTextRotation"/>
            </xsl:for-each>
          </a:bodyPr>
          <a:lstStyle/>
          <a:p>
            <a:pPr>
              <a:defRPr sz="700" b="0" i="0" u="none" strike="noStrike" baseline="0">

                <xsl:for-each select="key('style',@chart:style-name)/style:text-properties">
                  <!-- template common with text-box-->
                  <xsl:call-template name="InsertRunProperties"/>
                </xsl:for-each>

              </a:defRPr>
            </a:pPr>
            <a:endParaRPr lang="pl-PL"/>
          </a:p>
        </c:txPr>
      </xsl:if>

      <xsl:choose>
        <!-- primary X id -->
        <xsl:when test="$priority = 'primary' ">
          <c:crossAx val="104463360"/>
        </xsl:when>
        <!-- secondary X id -->
        <xsl:otherwise>
          <c:crossAx val="104425728"/>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:for-each
        select="key('style',parent::node()/chart:axis[@chart:name = 'primary-x']/@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <xsl:when
            test="key('chart','')/@chart:class = 'chart:scatter' and @chart:origin != '' and @chart:origin != 0">
            <c:crossesAt>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:origin"/>
              </xsl:attribute>
            </c:crossesAt>
          </xsl:when>

          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$priority = 'primary'">
                <c:crosses val="autoZero"/>
              </xsl:when>
              <xsl:otherwise>
                <c:crosses val="max"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>

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

      <xsl:for-each select="key('style',@chart:style-name)/style:chart-properties">
        <xsl:if test="@chart:interval-major">
          <c:majorUnit>
            <xsl:attribute name="val">
              <xsl:value-of select="@chart:interval-major"/>
            </xsl:attribute>
          </c:majorUnit>
          <xsl:if test="@chart:interval-minor-divisor">
            <c:minorUnit>
              <xsl:attribute name="val">
                <xsl:value-of select="@chart:interval-major div @chart:interval-minor-divisor"/>
              </xsl:attribute>
            </c:minorUnit>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>

    </c:valAx>
  </xsl:template>

  <xsl:template name="InsertSeries">
    <!-- @Description: Outputs chart series and their values -->
    <!-- @Context: table:table-rows -->
    <xsl:param name="chartDirectory"/>

    <xsl:param name="numSeries"/>
    <!-- (number) number of series inside chart -->
    <xsl:param name="numPoints"/>
    <!-- (number) maximum number of data point -->
    <xsl:param name="count" select="0"/>
    <!-- (number) loop counter -->
    <xsl:param name="reverseSeries"/>
    <!-- (string) is chart vertically aligned -->
    <xsl:param name="reverseCategories"/>
    <!-- series data source - rows or columns-->
    <xsl:param name="seriesFrom"/>
    <xsl:param name="chartType"/>

    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$reverseSeries = 'true' ">
          <xsl:value-of select="$numSeries - $count"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$count + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$count &lt; $numSeries">
        <xsl:choose>
          <!-- if there is secondary axis ommit its series -->
          <xsl:when test="key('series','')[position() = $number and @chart:attached-axis]">
            <xsl:if
              test="key('series','')[position() = $number and @chart:attached-axis = 'primary-y']">
              <xsl:call-template name="Series">
                <xsl:with-param name="numSeries" select="$numSeries"/>
                <xsl:with-param name="numPoints" select="$numPoints"/>
                <xsl:with-param name="count" select="$count"/>
                <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
                <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                <xsl:with-param name="chartType" select="$chartType"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="Series">
              <xsl:with-param name="numSeries" select="$numSeries"/>
              <xsl:with-param name="numPoints" select="$numPoints"/>
              <xsl:with-param name="count" select="$count"/>
              <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
              <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
              <xsl:with-param name="chartType" select="$chartType"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="InsertSeries">
          <xsl:with-param name="numSeries" select="$numSeries"/>
          <xsl:with-param name="numPoints" select="$numPoints"/>
          <xsl:with-param name="count" select="$count + 1"/>
          <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
          <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
          <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
          <xsl:with-param name="chartType" select="$chartType"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="Series">
    <xsl:param name="numSeries"/>
    <xsl:param name="numPoints"/>
    <xsl:param name="count"/>
    <xsl:param name="reverseSeries"/>
    <xsl:param name="reverseCategories"/>
    <xsl:param name="chartDirectory"/>
    <xsl:param name="seriesFrom"/>
    <xsl:param name="primarySeries" select="0"/>
    <!-- (number) when this is secondary chart series primarySeries equals total number of primary series -->
    <xsl:param name="chartType"/>

    <!-- count series from backwards if reverseSeries is = "true" -->
    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$reverseSeries = 'true' ">
          <xsl:value-of select="$numSeries - $count + $primarySeries"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$count + 1 + $primarySeries"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="styleName">
      <!-- (string) series style name -->
      <xsl:value-of select="key('series','')[position() = $number]/@chart:style-name"/>
    </xsl:variable>
<!--addedd to skip creation of series more than 4 for stock chart-->
    <xsl:choose>
      <xsl:when test="$count &gt;= 4 and $chartType='chart:stock'"/>
      <xsl:otherwise>
    <c:ser>
      <c:idx val="{$primarySeries + $count}"/>
      <c:order val="{$primarySeries + $count}"/>

      <xsl:if test="key('style', $styleName)/style:chart-properties/@chart:pie-offset">
        <c:explosion>
          <xsl:attribute name="val">
            <xsl:value-of select="key('style', $styleName)/style:chart-properties/@chart:pie-offset"
            />
          </xsl:attribute>
        </c:explosion>
      </xsl:if>

      <xsl:for-each select="key('series','')[position() = $number]">
        <xsl:if test="chart:regression-curve">
          <c:trendline>
            <xsl:for-each select="chart:regression-curve[1]">
              <xsl:call-template name="InsertSpPr">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="defaultFill" select="'solid'"/>
              </xsl:call-template>
            </xsl:for-each>
            <xsl:for-each select="key('style', @chart:style-name)">
              <c:trendlineType>
                <xsl:attribute name="val">
                  <xsl:choose>
                    <xsl:when test="style:chart-properties/@chart:regression-type = 'linear' ">
                      <xsl:text>linear</xsl:text>
                    </xsl:when>
                    <xsl:when test="style:chart-properties/@chart:regression-type = 'logarithmic' ">
                      <xsl:text>log</xsl:text>
                    </xsl:when>
                    <xsl:when test="style:chart-properties/@chart:regression-type = 'exponential' ">
                      <xsl:text>exp</xsl:text>
                    </xsl:when>
                    <xsl:when test="style:chart-properties/@chart:regression-type = 'power' ">
                      <xsl:text>power</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>linear</xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
              </c:trendlineType>
            </xsl:for-each>
          </c:trendline>
        </xsl:if>
      </xsl:for-each>

      <!-- series name -->
      <xsl:choose>
        <!-- pie chart series name is also a chart title and it can be occur only if chart title is displayed -->
        <xsl:when test="$chartType = 'chart:circle' ">
          <xsl:if test="key('chart','')/chart:title">
            <c:tx>
              <c:v>
                <xsl:choose>
                  <!-- for chart with swapped data sources-->
                  <xsl:when test="$seriesFrom = 'rows'">
                    <xsl:value-of
                      select="key('rows','')/table:table-row[position() = $number]/table:table-cell[1]"
                    />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of
                      select="key('header','')/table:table-row/table:table-cell[$number + 1]"/>
                  </xsl:otherwise>
                </xsl:choose>
              </c:v>
            </c:tx>
          </xsl:if>
        </xsl:when>

        <xsl:otherwise>
          <c:tx>
            <c:v>
              <xsl:choose>
                <xsl:when test="$chartType = 'chart:scatter' ">
                  <xsl:value-of
                    select="key('header','')/table:table-row/table:table-cell[$number + 2]"/>
                </xsl:when>
                <!-- for chart with swapped data sources-->
                <xsl:when test="$seriesFrom = 'rows'">
                  <xsl:value-of
                    select="key('rows','')/table:table-row[position() = $number]/table:table-cell[1]"
                  />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of
                    select="key('header','')/table:table-row/table:table-cell[$number + 1]"/>
                </xsl:otherwise>
              </xsl:choose>
            </c:v>
          </c:tx>
        </xsl:otherwise>
      </xsl:choose>

      <!-- insert series shape properties -->
      <xsl:choose>
        <!-- in scatter chart series properties define properties of line between points -->
        <xsl:when test="$chartType = 'chart:scatter' ">
          <c:spPr>

            <!-- draw line -->
            <xsl:for-each select="key('chart','')/chart:plot-area">
              <xsl:for-each select="key('style',@chart:style-name)">
                <xsl:choose>
                  <xsl:when test="style:chart-properties/@chart:lines = 'false' ">
                    <a:ln w="28575">
                      <a:noFill/>
                    </a:ln>
                  </xsl:when>
                  <xsl:when test="key('style',$styleName)/style:graphic-properties/@draw:stroke = 'none' ">
                    <a:ln w="28575">
                      <a:noFill/>
                    </a:ln>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:for-each select="key('style',$styleName)/style:graphic-properties">
                      <xsl:if test="@svg:stroke-width and @svg:stroke-color">
                        <xsl:call-template name="InsertDrawingBorder"/>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:for-each>

          </c:spPr>
        </xsl:when>

        <xsl:when test="$chartType = 'chart:radar' ">
          <xsl:for-each select="key('series','')[position() = $number]">

            <xsl:if test="@svg:stroke-width and @svg:stroke-color">
              <c:spPr>
                <xsl:call-template name="InsertDrawingBorder"/>
              </c:spPr>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>

        <!-- without line between points in series in stockChart4 -->
        <xsl:when test="$chartType = 'chart:stock' ">
          <c:spPr>
            <a:ln w="28575">
              <a:noFill/>
            </a:ln>
          </c:spPr>
        </xsl:when>
        <xsl:when test="$chartType = 'chart:ring'"/>
        <xsl:otherwise>
          <xsl:for-each select="key('series','')[position() = $number]">
            <xsl:call-template name="InsertSpPr">
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              <xsl:with-param name="defaultFill" select="'solid'"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>

      <!-- insert this series data points shape properties -->
      <xsl:choose>
        <xsl:when test="$chartType = 'chart:ring' ">
          <xsl:for-each select="key('series','')[last()]">
            <xsl:call-template name="InsertRingPointsShapeProperties">
              <xsl:with-param name="totalPoints" select="$numPoints"/>
              <xsl:with-param name="series" select="$number"/>
              <xsl:with-param name="ChartDirecotry">
                <xsl:value-of select="$chartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>

        <xsl:when test="$reverseCategories = 'true' ">
          <xsl:for-each select="key('series','')[position() = $number]/chart:data-point[last()]">
            <xsl:call-template name="InsertDataPointsShapeProperties">
              <xsl:with-param name="parentStyleName" select="$styleName"/>
              <xsl:with-param name="reverse" select=" 'true' "/>
              <xsl:with-param name="ChartDirectory">
                <xsl:value-of select="$chartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>

        <xsl:otherwise>
          <xsl:for-each select="key('series','')[position() = $number]/chart:data-point[1]">
            <xsl:call-template name="InsertDataPointsShapeProperties">
              <xsl:with-param name="parentStyleName" select="$styleName"/>
              <xsl:with-param name="ChartDirectory">
                <xsl:value-of select="$chartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>

      <!-- label -->
      <xsl:variable name="label">
        <xsl:for-each select="key('series','')">
          <xsl:if
            test="key('style',@chart:style-name)/style:chart-properties/@chart:data-label-number = 'value' or 
            key('style',@chart:style-name)/style:chart-properties/@chart:data-label-text = 'true' ">
            <xsl:text>true</xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="$label != '' ">
        <c:dLbls>
          <xsl:for-each select="key('style',$styleName)">
            <!-- label content -->
            <xsl:for-each select="style:chart-properties">
              <xsl:choose>
                <xsl:when
                  test="@chart:data-label-number = 'value' or @chart:data-label-text = 'true' or @chart:data-label-number = 'value-and-percentage' ">
                  <!-- value -->
                  <xsl:if test="@chart:data-label-number = 'value' or @chart:data-label-number = 'value-and-percentage' ">
                    <c:showVal val="1"/>
                  </xsl:if>
                  <!-- percent -->
                  <xsl:if test="@chart:data-label-number = 'percentage' or @chart:data-label-number = 'value-and-percentage' ">
                    <c:showPercent val="1"/>
                  </xsl:if>
                  <!-- name -->
                  <xsl:if test="@chart:data-label-text = 'true' ">
                    <c:showCatName val="1"/>
                  </xsl:if>
                  <!-- icon -->
                  <xsl:if test="@chart:data-label-text = 'true' ">
                    <c:showLegendKey val="1"/>
                  </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                  <c:delete val="1"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>

            <!-- lable text properties -->
            <c:txPr>
              <a:bodyPr rot="0" vert="horz"/>
              <a:lstStyle/>
              <a:p>
                <a:pPr>
                  <a:defRPr>
                    <xsl:for-each select="style:text-properties">
                      <!-- template common with text-box-->
                      <xsl:call-template name="InsertRunProperties"/>
                    </xsl:for-each>
                  </a:defRPr>
                </a:pPr>
                <a:endParaRPr lang="pl-PL"/>
              </a:p>
            </c:txPr>
          </xsl:for-each>
        </c:dLbls>
      </xsl:if>

      <!-- error indicator -->
      <xsl:for-each select="key('series','')[position() = $number]">
        <xsl:if test="chart:error-indicator">
          <xsl:variable name="type">
            <xsl:value-of
              select="key('style',$styleName)/style:chart-properties/@chart:error-category"/>
          </xsl:variable>

          <!-- only this types can be converted -->
          <xsl:if test="$type = 'constant' or $type = 'percentage' ">
            <c:errBars>

              <xsl:for-each select="key('style',$styleName)/style:chart-properties">

                <!-- indicators -->
                <c:errBarType val="both">
                  <xsl:attribute name="val">
                    <xsl:choose>
                      <xsl:when
                        test="@chart:error-upper-indicator = 'true' and @chart:error-lower-indicator = 'true' ">
                        <xsl:text>both</xsl:text>
                      </xsl:when>
                      <xsl:when test="@chart:error-upper-indicator = 'true' ">
                        <xsl:text>plus</xsl:text>
                      </xsl:when>
                      <xsl:when test="@chart:error-lower-indicator = 'true' ">
                        <xsl:text>minus</xsl:text>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:attribute>
                </c:errBarType>

                <!-- error type -->
                <xsl:choose>
                  <!-- fixed value -->
                  <xsl:when test="$type = 'constant' ">
                    <xsl:choose>
                      <xsl:when test="@chart:error-lower-limit = @chart:error-upper-limit">
                        <c:errValType val="fixedVal"/>
                        <c:val>
                          <xsl:attribute name="val">
                            <xsl:value-of select="@chart:error-lower-limit"/>
                          </xsl:attribute>
                        </c:val>
                      </xsl:when>
                      <xsl:otherwise>
                        <c:errValType val="cust"/>
                        <c:plus>
                          <c:numLit>
                            <c:formatCode>General</c:formatCode>
                            <c:ptCount val="1"/>
                            <c:pt idx="0">
                              <c:v>
                                <xsl:value-of select="@chart:error-upper-limit"/>
                              </c:v>
                            </c:pt>
                          </c:numLit>
                        </c:plus>
                        <c:minus>
                          <c:numLit>
                            <c:formatCode>General</c:formatCode>
                            <c:ptCount val="1"/>
                            <c:pt idx="0">
                              <c:v>
                                <xsl:value-of select="@chart:error-lower-limit"/>
                              </c:v>
                            </c:pt>
                          </c:numLit>
                        </c:minus>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <!-- percentage -->
                  <xsl:when test="$type = 'percentage' ">
                    <c:errValType val="percentage"/>
                    <c:val>
                      <xsl:attribute name="val">
                        <xsl:value-of select="@chart:error-percentage"/>
                      </xsl:attribute>
                    </c:val>
                  </xsl:when>
                </xsl:choose>

              </xsl:for-each>

              <!-- error indicator graphic properties -->
              <xsl:for-each select="chart:error-indicator">
                <xsl:for-each select="key('style', @chart:style-name)/style:graphic-properties">
                  <c:spPr>
                    <xsl:call-template name="InsertDrawingBorder"/>
                  </c:spPr>
                </xsl:for-each>
              </xsl:for-each>

            </c:errBars>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>

      <xsl:variable name="japaneseCandle">
        <xsl:for-each select="key('chart','')[2]">
          <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)">
            <xsl:value-of select="@chart:japanese-candle-stick"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <!-- marker type -->
      <!-- if line chart or radar chart or bar chart with lines -->
      <xsl:if
        test="$chartType = 'chart:line' or $chartType = 'chart:radar' or ancestor::chart:chart/chart:plot-area/chart:series[position() = $number]/@chart:class = 'chart:line' or 
        $chartType = 'chart:scatter' or $chartType = 'chart:stock' ">
        <xsl:for-each select="ancestor::chart:chart/chart:plot-area">
          <xsl:choose>
            <!-- when plot-area has 'no symbol' property -->
            <xsl:when
              test="key('style',@chart:style-name )/style:chart-properties/@chart:symbol-type = 'none' ">
              <c:marker>
                <c:symbol val="none"/>
              </c:marker>
            </xsl:when>
            <xsl:when
              test="key('style',$styleName)/style:chart-properties/@chart:symbol-type = 'none' ">
              <c:marker>
                <c:symbol val="none"/>
              </c:marker>
            </xsl:when>
            <xsl:when
              test="key('style',$styleName)/style:chart-properties/@chart:symbol-type = 'named-symbol' ">
              <xsl:for-each select="key('style',$styleName)/style:chart-properties">
                <c:marker>
                  <c:symbol>
                    <xsl:attribute name="val">
                      <xsl:choose>
                        <xsl:when test="@chart:symbol-name = 'diamond' ">
                          <xsl:text>diamond</xsl:text>
                        </xsl:when>
                            <xsl:when test="contains(@chart:symbol-name,'arrow-up')">
                          <xsl:text>triangle</xsl:text>
                        </xsl:when>
                            <xsl:when test="contains(@chart:symbol-name,'square')">
                          <xsl:text>square</xsl:text>
                            </xsl:when>
                        <xsl:otherwise>
                              <xsl:text>none</xsl:text>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:attribute>
                  </c:symbol>
                      <xsl:if test="@chart:symbol-width and (@chart:symbol-name='diamond' or @chart:symbol-name='arrow-up' or @chart:symbol-name='square') ">
                    <c:size>
                      <xsl:attribute name="val">
                        <xsl:variable name="size">
                          <xsl:call-template name="point-measure">
                            <xsl:with-param name="length" select="@chart:symbol-width"/>
                          </xsl:call-template>
                        </xsl:variable>
                        <xsl:value-of select="round($size)"/>
                      </xsl:attribute>
                    </c:size>
                  </xsl:if>
                  <c:spPr>
                    <a:ln>
                      <a:solidFill>
                        <a:srgbClr val="000000"/>
                      </a:solidFill>
                    </a:ln>
                  </c:spPr>
                </c:marker>
              </xsl:for-each>
            </xsl:when>
            <!-- default marker type for series in stockCharts -->
            <xsl:when test="$chartType = 'chart:stock' ">
              <xsl:choose>
                <!-- close price marker for stock chart 1 -->
                <xsl:when test="$numSeries = 3 and $count = 2">
                  <c:marker>
                    <c:symbol val="dot"/>
                    <c:size val="3"/>
                  </c:marker>
                </xsl:when>
                <!-- close price marker for stock chart 3 -->
                <xsl:when
                  test="$numSeries = 4 and $count = 3 and chart:series/@chart:class = 'chart:bar' ">
                  <c:marker>
                    <c:symbol val="dot"/>
                    <c:size val="3"/>
                  </c:marker>
                </xsl:when>
                <xsl:otherwise>
                  <c:marker>
                    <c:symbol val="none"/>
                  </c:marker>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:if>

      <xsl:choose>
        <!-- insert X and Y values-->
        <xsl:when test="$chartType = 'chart:scatter' ">
          <c:xVal>
            <c:numRef>
              <c:numCache>
                <c:formatCode>General</c:formatCode>
                <c:ptCount val="{$numPoints}"/>
                <xsl:for-each select="key('rows','')">
                  <xsl:call-template name="InsertPoints">
                    <!-- the x values are the first points -->
                    <xsl:with-param name="series" select="0"/>
                    <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                  </xsl:call-template>
                </xsl:for-each>
              </c:numCache>
            </c:numRef>
          </c:xVal>
          <c:yVal>
            <c:numRef>
              <c:numCache>
                <c:formatCode>General</c:formatCode>
                <c:ptCount val="{$numPoints}"/>
                <xsl:for-each select="key('rows','')">
                  <xsl:call-template name="InsertPoints">
                    <!-- the first points are the x values so add 1 -->
                    <xsl:with-param name="series" select="$count + 1"/>
                    <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                  </xsl:call-template>
                </xsl:for-each>
              </c:numCache>
            </c:numRef>
          </c:yVal>
        </xsl:when>

        <!-- insert categories and values -->
        <xsl:otherwise>
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
                      <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
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

                <xsl:for-each select="key('rows','')">
                  <xsl:choose>
                    <xsl:when test="$reverseCategories = 'true' ">
                      <xsl:call-template name="InsertPointsReverse">
                        <xsl:with-param name="series" select="$thisSeries + $primarySeries"/>
                        <xsl:with-param name="numCategories" select="$numPoints"/>
                      </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="InsertPoints">
                        <xsl:with-param name="series" select="$thisSeries + $primarySeries"/>
                        <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                      </xsl:call-template>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </c:numCache>
            </c:numRef>
          </c:val>
        </xsl:otherwise>
      </xsl:choose>

      <!-- smooth line -->
      <xsl:for-each select="ancestor::chart:chart">
        <xsl:if test="@chart:class = 'chart:line' or @chart:class = 'chart:scatter' ">
          <xsl:for-each
            select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
            <xsl:if test="@chart:interpolation != 'none' ">
              <c:smooth val="1"/>
              <xsl:if test="@chart:interpolation = 'b-spline' ">
                <xsl:message terminate="no"
                >translation.odf2oox.LineChartSmoothingBSpline</xsl:message>
              </xsl:if>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </c:ser>
      </xsl:otherwise>
    </xsl:choose>

  
  </xsl:template>

  <xsl:template name="InsertPoints">
    <!-- @Description: Outputs series data points -->
    <!-- @Context: table:table-rows -->

    <xsl:param name="series"/>
    <xsl:param name="seriesFrom"/>

    <xsl:choose>
      <xsl:when test="$seriesFrom != 'rows'">
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
      </xsl:when>
      <!-- for chart with swapped data sources -->
      <xsl:otherwise>
        <xsl:for-each select="key('rows','')/table:table-row">
          <xsl:if test="position()-1 = $series ">
            <xsl:for-each select="table:table-cell">
              <xsl:if test="@office:value-type!='string' and self::node()/text:p !='1.#NAN' ">
                <c:pt idx="{position()-2  }">
                  <c:v>
                    <xsl:value-of select="self::node()/text:p"/>
                  </c:v>
                </c:pt>
              </xsl:if>
            </xsl:for-each>
          </xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
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
    <xsl:param name="seriesFrom"/>

    <xsl:choose>
      <xsl:when test="$seriesFrom != 'rows'">
        <!-- categories names -->
        <xsl:for-each select="table:table-row">
          <c:pt idx="{position() - 1}">
            <c:v>
              <xsl:value-of select="table:table-cell[1]/text:p"/>
            </c:v>
          </c:pt>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="key('header','')/table:table-row/table:table-cell/text:p">
          <xsl:if test="./node() != '' and (position()-2) &gt; -1">
            <c:pt idx="{position() - 2}">
              <c:v>
                <xsl:value-of select="./node()"/>
              </c:v>
            </c:pt>
          </xsl:if>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
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

        <xsl:when test="@chart:deep = 'true' ">
          <xsl:attribute name="val">
            <xsl:text>standard</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="InsertSpPr">
    <xsl:param name="chartDirectory"/>
    <xsl:param name="defaultFill"/>

    <c:spPr>

      <xsl:choose>

        <xsl:when
          test="key('style',@chart:style-name)/style:graphic-properties/@draw:fill='gradient'">
          <xsl:for-each select="key('style',@chart:style-name)/style:graphic-properties">
            <xsl:call-template name="tmpGradientFill">
              <xsl:with-param name="gradStyleName" select="@draw:fill-gradient-name"/>
              <xsl:with-param name="opacity" select="substring-before(@draw:opacity,'%')"/>
              <xsl:with-param name="ChartDirectory">
                <xsl:value-of select="$chartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
            <!--added by sonata for the bug no 2015063 -->
            <xsl:call-template name="InsertDrawingBorder">
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              
            </xsl:call-template>
            <!--end-->
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>

          <xsl:for-each select="key('style', @chart:style-name)/style:graphic-properties">

            <xsl:call-template name="InsertDrawingFill">
              <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
              <xsl:with-param name="default" select="$defaultFill"/>
            </xsl:call-template>

            <xsl:call-template name="InsertDrawingBorder"/>

          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </c:spPr>

  </xsl:template>

  <xsl:template name="InsertShapeProperties">
    <xsl:param name="styleName"/>
    <xsl:param name="parentStyleName"/>
    <xsl:param name="ChartDirectory"/>


        <!-- series shape property -->
        <c:spPr>

          <!-- fill color -->
          <xsl:if
            test="key('style',$styleName)/style:graphic-properties/@draw:fill-color or key('style',$parentStyleName)/style:graphic-properties/@draw:fill-color">
            <a:solidFill>
              <a:srgbClr val="9999FF">
                <xsl:attribute name="val">
                  <xsl:choose>
                    <xsl:when
                      test="key('style',$styleName)/style:graphic-properties/@draw:fill-color">
                      <xsl:value-of
                        select="substring(key('style',$styleName)/style:graphic-properties/@draw:fill-color,2)"
                      />
                    </xsl:when>
                    <xsl:when
                      test="key('style',$parentStyleName)/style:graphic-properties/@draw:fill-color">
                      <xsl:value-of
                        select="substring(key('style',$parentStyleName)/style:graphic-properties/@draw:fill-color,2)"
                      />
                    </xsl:when>
                  </xsl:choose>
                </xsl:attribute>
              </a:srgbClr>
            </a:solidFill>
          </xsl:if>

          <!-- line color -->
          <xsl:if test="not(key('style',$styleName)/style:graphic-properties/@draw:stroke = 'none')">
            <a:ln w="3175">
              <a:solidFill>
                <a:srgbClr val="000000">
                  <xsl:if
                    test="(key('style',$styleName)/style:graphic-properties/@svg:stroke-color or key('style',$parentStyleName)/style:graphic-properties/@svg:stroke-color)">
                    <xsl:attribute name="val">
                      <xsl:choose>
                        <xsl:when
                          test="key('style',$styleName)/style:graphic-properties/@svg:stroke-color">
                          <xsl:value-of
                            select="substring(key('style',$styleName)/style:graphic-properties/@svg:stroke-color,2)"
                          />
                        </xsl:when>
                        <xsl:when
                          test="key('style',$parentStyleName)/style:graphic-properties/@svg:stroke-color">
                          <xsl:value-of
                            select="substring(key('style',$parentStyleName)/style:graphic-properties/@svg:stroke-color,2)"
                          />
                        </xsl:when>
                      </xsl:choose>
                    </xsl:attribute>
                  </xsl:if>
                </a:srgbClr>
              </a:solidFill>
              <a:prstDash val="solid"/>
            </a:ln>
          </xsl:if>
        </c:spPr>

   
  </xsl:template>

  <xsl:template name="InsertDataPointsShapeProperties">
    <!-- @Description: Sets data grouping type -->
    <!-- @Context: chart:data-point -->

    <xsl:param name="parentStyleName"/>
    <xsl:param name="reverse"/>
    <xsl:param name="count" select="0"/>
    <xsl:param name="ChartDirectory"/>

    <xsl:variable name="points">
      <xsl:choose>
        <xsl:when test="@chart:repeated">
          <xsl:value-of select="@chart:repeated"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>1</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- only fill and stroke color for now -->
    <xsl:if test="@chart:style-name">
      <c:dPt>
        <c:idx val="{$count}"/>
        <xsl:call-template name="InsertShapeProperties">
          <xsl:with-param name="parentStyleName" select="$parentStyleName"/>
          <xsl:with-param name="styleName" select="@chart:style-name"/>
          <xsl:with-param name="ChartDirectory">
            <xsl:value-of select="$ChartDirectory"/>
          </xsl:with-param>
        </xsl:call-template>
      </c:dPt>
    </xsl:if>

    <!-- get next data point -->
    <xsl:choose>
      <!-- previous if categories are aligned in reverse order -->
      <xsl:when test="$reverse = 'true' ">
        <xsl:if test="preceding-sibling::chart:data-point[1]">
          <xsl:for-each select="preceding-sibling::chart:data-point[1]">
            <xsl:call-template name="InsertDataPointsShapeProperties">
              <xsl:with-param name="parentStyleName" select="$parentStyleName"/>
              <xsl:with-param name="reverse" select="$reverse"/>
              <xsl:with-param name="count" select="$count + $points"/>
              <xsl:with-param name="ChartDirectory">
                <xsl:value-of select="$ChartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </xsl:when>
      <!-- folowing data point -->
      <xsl:otherwise>
        <xsl:if test="following-sibling::chart:data-point[1]">
          <xsl:for-each select="following-sibling::chart:data-point[1]">
            <xsl:call-template name="InsertDataPointsShapeProperties">
              <xsl:with-param name="parentStyleName" select="$parentStyleName"/>
              <xsl:with-param name="count" select="$count + $points"/>
              <xsl:with-param name="ChartDirectory">
                <xsl:value-of select="$ChartDirectory"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertSecondaryChartContent">
    <!-- @Description: Inserts chart content -->
    <!-- @Context: chart:chart -->
    <xsl:param name="chartDirectory"/>
    <xsl:param name="cause" select="'chart-class'"/>

    <xsl:variable name="seriesFrom">
      <xsl:value-of
        select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:series-source"
      />
    </xsl:variable>

    <xsl:variable name="numSeries">
      <!-- (number) number of secondary series inside chart -->
      <xsl:choose>
        <xsl:when test="$cause = 'chart-class' ">
          <xsl:value-of select="count(key('series','')[@chart:class])"/>
        </xsl:when>
        <xsl:otherwise>
          <!--Start of RefNo-2: Added condition to chk for the stock chart of 3rd & 4th type, if 3rd & 4th type then 
          numSeries is total no. series - 1, as the last series is attached to primay axis sometimes in ods. -->
          <!--<xsl:value-of select="count(key('series','')[@chart:attached-axis = 'secondary-y' ])"/>-->
          <xsl:choose>
            <xsl:when test="key('chart','')/@chart:class = 'chart:stock'">
              <xsl:value-of select="count(key('series','')) - 1"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="count(key('series','')[@chart:attached-axis = 'secondary-y' ])"
              />
            </xsl:otherwise>
          </xsl:choose>
          <!--End of RefNo-2-->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="primarySeries">
      <xsl:choose>
        <xsl:when test="$cause = 'chart-class' ">
          <xsl:value-of select="count(key('series','')[not(@chart:class)])"/>
        </xsl:when>
        <xsl:otherwise>
          <!--Start of RefNo-2:Changes done to get the total no. of ser, insted of only primaySeries cnt-->
          <!--<xsl:value-of select="count(key('series','')[not(@chart:attached-axis = 'secondary-y' )])"/>-->
          <xsl:choose>
            <xsl:when
              test="@chart:class = 'chart:bar' and key('series','')[@chart:class = 'chart:line' ]">
              <xsl:value-of select="count(key('series',''))"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- (number) number of series inside chart -->
              <xsl:value-of select="count(key('series','')[not(@chart:class)])"/>
            </xsl:otherwise>
          </xsl:choose>
          <!--End of RefNo-2-->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="chartType">
      <xsl:choose>
        <xsl:when test="key('chart','')/@chart:class = 'chart:stock' ">
          <xsl:text>chart:stock</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="key('series','')[@chart:class][1]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="numPoints">
      <!-- (number) maximum number of data point -->
      <xsl:choose>
        <!-- for chart with swapped data sources -->
        <xsl:when test="$seriesFrom='rows'">
          <xsl:call-template name="MaxPointNumber">
            <xsl:with-param name="rowNumber">
              <xsl:value-of select="1"/>
            </xsl:with-param>
            <xsl:with-param name="CountCellsInRow">
              <xsl:value-of
                select="count(key('rows','')/table:table-row[1]/table:table-cell[@office:value-type != 'string'])"
              />
            </xsl:with-param>
            <xsl:with-param name="maxValue">
              <xsl:value-of select="1"/>
            </xsl:with-param>
            <xsl:with-param name="rowsQuantity">
              <xsl:value-of select="count(key('rows','')/table:table-row)"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="count(key('rows','')/table:table-row)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="reverseCategories">
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)/style:chart-properties">
        <xsl:choose>
          <!-- reverse categories for: (pie charts) or (ring charts) or (2D bar charts stacked or percentage) -->
          <xsl:when
            test="(key('chart','')/@chart:class = 'chart:circle' ) or (key('chart','')/@chart:class = 'chart:ring' ) or 
            (@chart:vertical = 'true' and @chart:three-dimensional = 'false' )">
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
          <!-- reverse series for: (2D normal bar chart) or (2D normal area chart) or (ring:chart) -->
          <xsl:when
            test="(@chart:vertical = 'true' and not(@chart:stacked = 'true' or @chart:percentage = 'true' ) and @chart:three-dimensional = 'false' ) or 
            (key('chart','')/@chart:class = 'chart:area' and not(@chart:stacked = 'true' or @chart:percentage = 'true' ) and @chart:three-dimensional = 'false' ) or
            (key('chart','')/@chart:class = 'chart:ring')">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>

    <xsl:for-each select="key('rows','')">
      <xsl:call-template name="InsertSecondaryChartSeries">
        <xsl:with-param name="numSeries" select="$numSeries"/>
        <xsl:with-param name="numPoints" select="$numPoints"/>
        <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
        <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
        <xsl:with-param name="primarySeries" select="$primarySeries"/>
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
        <xsl:with-param name="chartType" select="$chartType"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- for stock chart 3&4 -->
    <xsl:if test="@chart:class = 'chart:stock' and key('series','')/@chart:class = 'chart:bar' ">
      <c:hiLowLines>
        <xsl:for-each select="chart:plot-area/chart:stock-range-line">
          <xsl:call-template name="InsertSpPr">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
          </xsl:call-template>
        </xsl:for-each>
      </c:hiLowLines>

      <!-- stock gain/loss bars -->
      <xsl:for-each select="key('style',chart:plot-area/@chart:style-name)">
        <xsl:if test="style:chart-properties/@chart:japanese-candle-stick = 'true' ">
          <c:upDownBars>
            <c:gapWidth val="150"/>

            <c:upBars>
              <xsl:for-each select="chart:plot-area/chart:stock-gain-marker">
                <xsl:call-template name="InsertSpPr">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>
              </xsl:for-each>
            </c:upBars>

            <c:downBars>
              <xsl:for-each select="chart:plot-area/chart:stock-loss-marker">
                <xsl:call-template name="InsertSpPr">
                  <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                </xsl:call-template>
              </xsl:for-each>
            </c:downBars>

          </c:upDownBars>
        </xsl:if>
      </xsl:for-each>
    </xsl:if>
    <xsl:choose>
      <!-- primary axes -->
      <xsl:when test="not(chart:plot-area/chart:axis/@chart:name = 'secondary-y')">
        <c:axId val="104463360"/>
        <c:axId val="104460288"/>
        <!--<c:axId val="104425728"/>
        <c:axId val="104461824"/>-->
      </xsl:when>
      <!-- secondary axes -->
      <xsl:otherwise>
        <c:axId val="104425728"/>
        <c:axId val="104461824"/>
        <!--<c:axId val="104463360"/>
        <c:axId val="104460288"/>-->
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="InsertSecondaryChartSeries">
    <!-- @Description: Outputs chart series and their values -->
    <!-- @Context: table:table-rows -->
    <xsl:param name="chartDirectory"/>

    <xsl:param name="numSeries"/>
    <!-- (number) number of series inside chart -->
    <xsl:param name="numPoints"/>
    <!-- (number) maximum number of data point -->
    <xsl:param name="primarySeries"/>
    <xsl:param name="reverseCategories"/>
    <xsl:param name="reverseSeries"/>
    <xsl:param name="seriesFrom"/>
    <xsl:param name="chartType"/>
    <xsl:param name="count" select="0"/>
    <!-- (number) loop counter -->

    <xsl:variable name="number">
      <xsl:choose>
        <xsl:when test="$reverseSeries = 'true' ">
          <xsl:value-of select="$numSeries - $count"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$count + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--Start of RefNo-2:Added code to chk if the series is secondary-->
    <!--<xsl:if test="$count &lt; $numSeries">
      <xsl:call-template name="Series">
        <xsl:with-param name="numSeries" select="$numSeries"/>
        <xsl:with-param name="primarySeries" select="$primarySeries"/>
        <xsl:with-param name="numPoints" select="$numPoints"/>
        <xsl:with-param name="count" select="$count"/>
        <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
        <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
        <xsl:with-param name="chartType" select="$chartType"/>
      </xsl:call-template>

      <xsl:call-template name="InsertSecondaryChartSeries">
        <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
        <xsl:with-param name="numSeries" select="$numSeries"/>
        <xsl:with-param name="numPoints" select="$numPoints"/>
        <xsl:with-param name="primarySeries" select="$primarySeries"/>
        <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
        <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
        <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
        <xsl:with-param name="count" select="$count + 1"/>
        <xsl:with-param name="chartType" select="$chartType"/>
      </xsl:call-template>
    </xsl:if>-->
    <xsl:if test="$count &lt; $numSeries">
      <xsl:choose>
        <!-- if there is secondary axis ommit its series -->
        <xsl:when
          test="(key('chart','')/@chart:class = 'chart:stock') and (count(key('series','')) = 4) and ($count = 3) and (key('series','')[position() = $number and @chart:attached-axis])">
          <xsl:call-template name="Series">
            <xsl:with-param name="numSeries" select="$numSeries"/>
            <!--<xsl:with-param name="primarySeries" select="$primarySeries"/>-->
            <xsl:with-param name="numPoints" select="$numPoints"/>
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
            <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
            <xsl:with-param name="chartType" select="$chartType"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when
          test="key('series','')[position() = $number and @chart:attached-axis = 'secondary-y']">
          <xsl:call-template name="Series">
            <xsl:with-param name="numSeries" select="$numSeries"/>
            <!--<xsl:with-param name="primarySeries" select="$primarySeries"/>-->
            <xsl:with-param name="numPoints" select="$numPoints"/>
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
            <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
            <xsl:with-param name="chartType" select="$chartType"/>
          </xsl:call-template>
          <xsl:call-template name="InsertSecondaryChartSeries">
            <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
            <xsl:with-param name="numSeries" select="$numSeries"/>
            <xsl:with-param name="numPoints" select="$numPoints"/>
            <xsl:with-param name="primarySeries" select="$primarySeries"/>
            <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
            <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
            <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
            <xsl:with-param name="count" select="$count + 1"/>
            <xsl:with-param name="chartType" select="$chartType"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$count + 1 &lt; $primarySeries">
              <xsl:call-template name="InsertSecondaryChartSeries">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="numSeries" select="$numSeries + 1"/>
                <xsl:with-param name="numPoints" select="$numPoints"/>
                <xsl:with-param name="primarySeries" select="$primarySeries"/>
                <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
                <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
                <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                <xsl:with-param name="count" select="$count + 1"/>
                <xsl:with-param name="chartType" select="$chartType"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="InsertSecondaryChartSeries">
                <xsl:with-param name="chartDirectory" select="$chartDirectory"/>
                <xsl:with-param name="numSeries" select="$numSeries"/>
                <xsl:with-param name="numPoints" select="$numPoints"/>
                <xsl:with-param name="primarySeries" select="$primarySeries"/>
                <xsl:with-param name="reverseCategories" select="$reverseCategories"/>
                <xsl:with-param name="reverseSeries" select="$reverseSeries"/>
                <xsl:with-param name="seriesFrom" select="$seriesFrom"/>
                <xsl:with-param name="count" select="$count + 1"/>
                <xsl:with-param name="chartType" select="$chartType"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <!--End of RefNo-2-->
  </xsl:template>

  <xsl:template name="InsertView3D">
    <!-- @Description: Sets 3D view definition -->
    <!-- @Context: chart:chart -->

    <xsl:if
      test="@chart:class = 'chart:circle' and key('style',chart:plot-area/@chart:style-name)/style:chart-properties/@chart:three-dimensional = 'true' ">
      <c:view3D>
        <c:rotY val="90"/>
      </c:view3D>
    </xsl:if>

  </xsl:template>

  <xsl:template name="InsertRingPointsShapeProperties">
    <!-- @Description: Inserts ring chart data point shape property-->
    <!-- @Context: chart:series[last()] -->
    <xsl:param name="totalPoints"/>
    <xsl:param name="series"/>
    <xsl:param name="count" select="0"/>
    <xsl:param name="ChartDirecotry"/>

    <xsl:variable name="dataPointStyle">
      <xsl:for-each
        select="parent::node()/chart:series[position() = $totalPoints - $count]/chart:data-point[position() = 1]">
        <xsl:call-template name="GetDataPointStyleName">
          <xsl:with-param name="point" select="$series"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="styleName">
      <xsl:choose>
        <xsl:when test="$dataPointStyle != '' ">
          <xsl:value-of select="$dataPointStyle"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@chart:style-name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <c:dPt>
      <c:idx val="{$count}"/>
      <xsl:call-template name="InsertShapeProperties">
        <xsl:with-param name="styleName" select="$styleName"/>
        <xsl:with-param name="ChartDirectory">
          <xsl:value-of select="$ChartDirecotry"/>
        </xsl:with-param>
      </xsl:call-template>
    </c:dPt>

    <xsl:for-each select="preceding-sibling::node()[name() = 'chart:series' ][1]">
      <xsl:call-template name="InsertRingPointsShapeProperties">
        <xsl:with-param name="totalPoints" select="$totalPoints"/>
        <xsl:with-param name="series" select="$series"/>
        <xsl:with-param name="count" select="$count + 1"/>
        <xsl:with-param name="ChartDirecotry">
          <xsl:value-of select="$ChartDirecotry"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

  <xsl:template name="GetDataPointStyleName">
    <!-- @Description: Gets data point style name -->
    <!-- @Context: chart:data-point[1] -->

    <xsl:param name="point"/>
    <xsl:param name="count" select="0"/>

    <xsl:variable name="points">
      <xsl:choose>
        <xsl:when test="@chart:repeated">
          <xsl:value-of select="@chart:repeated"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>1</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$count + $points &gt;= $point ">
        <xsl:value-of select="@chart:style-name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="following-sibling::chart:data-point">
          <xsl:for-each select="following-sibling::chart:data-point[1]">
            <xsl:call-template name="GetDataPointStyleName">
              <xsl:with-param name="point" select="$point"/>
              <xsl:with-param name="count" select="$count + $points"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsideChartPosition">
    <xsl:param name="chartWidth"/>
    <xsl:param name="chartHeight"/>

    <xsl:variable name="xOffset">
      <xsl:value-of select="substring-before(@svg:x,'cm' )"/>
    </xsl:variable>

    <xsl:variable name="yOffset">
      <xsl:value-of select="substring-before(@svg:y,'cm' )"/>
    </xsl:variable>

    <xsl:variable name="width">
      <xsl:value-of select="substring-before(@svg:width,'cm' )"/>
    </xsl:variable>

    <xsl:variable name="height">
      <xsl:value-of select="substring-before(@svg:height,'cm' )"/>
    </xsl:variable>

    <!-- ugly hack for plot area height increase when width is too wide -->
    <xsl:variable name="plotWidthCorrection">
      <xsl:text>0.025</xsl:text>
    </xsl:variable>

    <xsl:variable name="plotHeightCorrection">
      <xsl:text>0.05</xsl:text>
    </xsl:variable>

    <!-- ugly hack for axis Y title influence on plot-area display -->
    <xsl:variable name="plotXCorrection">
      <xsl:text>0.1</xsl:text>
    </xsl:variable>

    <xsl:if test="$xOffset div $chartWidth">
      <c:x>

        <xsl:attribute name="val">
          <xsl:variable name="correction">
            <xsl:choose>
              <xsl:when
                test="chart:axis[@chart:dimension = 'y' ]/chart:title and name() = 'chart:plot-area' ">
                <xsl:value-of select="$plotXCorrection"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="0"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="$xOffset div $chartWidth + $correction"/>
        </xsl:attribute>

      </c:x>
    </xsl:if>


    <xsl:choose>
      <!-- when axis Y title -->
      <xsl:when test="parent::node()/@chart:dimension = 'y' ">
        <xsl:if test="1 - $yOffset div $chartHeight">
          <c:y>
            <xsl:attribute name="val">
              <xsl:value-of select="1 - $yOffset div $chartHeight"/>
            </xsl:attribute>
          </c:y>
        </xsl:if>
      </xsl:when>
      <xsl:when test="key('chart','')/@chart:class = 'chart:radar' ">
        <c:y>
          <xsl:attribute name="val">
            <xsl:value-of select="20"/>
          </xsl:attribute>
        </c:y>
      </xsl:when>
      <xsl:when test="$yOffset div $chartHeight">
        <c:y>
          <xsl:attribute name="val">
            <xsl:value-of select="$yOffset div $chartHeight"/>
          </xsl:attribute>
        </c:y>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>

    <xsl:if test="@svg:width">
      <c:w>
        <xsl:attribute name="val">

          <xsl:variable name="correction">
            <xsl:choose>
              <!-- ugly hack for axis title influence on plot-area display -->
              <!--xsl:when
                test="chart:axis[@chart:dimension = 'y' ]/chart:title and name() = 'chart:plot-area' ">
                <xsl:value-of select="$plotWidthCorrection + $plotXCorrection"/>
              </xsl:when-->
              <xsl:when test="name() = 'chart:plot-area' ">
                <xsl:value-of select="$plotWidthCorrection"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="0"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:value-of select="$width div $chartWidth - $correction"/>
        </xsl:attribute>

      </c:w>
    </xsl:if>

    <xsl:if test="@svg:height">
      <c:h>
        <xsl:attribute name="val">
          <xsl:variable name="correction">
            <xsl:choose>
              <!-- ugly hack for axis title influence on plot-area display -->
              <xsl:when
                test="chart:axis[@chart:dimension = 'x' ]/chart:title and name() = 'chart:plot-area' ">
                <xsl:value-of select="$plotHeightCorrection + $plotXCorrection"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="0"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <!--xsl:value-of select="$height div $chartHeight - $correction"/-->
          <xsl:value-of select="$height div $chartHeight"/>
        </xsl:attribute>

      </c:h>
    </xsl:if>

  </xsl:template>

  <!-- template returning the maximum amount of non-string cells in a row  -->
  <xsl:template name="MaxPointNumber">
    <!-- global amount of rows to be processed -->
    <xsl:param name="rowsQuantity"/>
    <!-- current row number -->
    <xsl:param name="rowNumber"/>
    <!-- max value until now -->
    <xsl:param name="maxValue"/>
    <!-- cells amount in the current row -->
    <xsl:param name="CountCellsInRow"/>

    <xsl:choose>
      <xsl:when test="$maxValue &lt; $CountCellsInRow and $rowNumber = $rowsQuantity">
        <xsl:value-of select="$CountCellsInRow"/>
      </xsl:when>
      <xsl:when test="$maxValue &gt;= $CountCellsInRow and $rowNumber = $rowsQuantity">
        <xsl:value-of select="$maxValue"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="MaxPointNumber">
          <xsl:with-param name="rowsQuantity">
            <xsl:value-of select="$rowsQuantity"/>
          </xsl:with-param>
          <xsl:with-param name="maxValue">
            <xsl:choose>
              <xsl:when test="$maxValue &lt; $CountCellsInRow">
                <xsl:value-of select="$CountCellsInRow"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$maxValue"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="CountCellsInRow">
            <xsl:value-of
              select="count(key('rows','')/table:table-row[$rowNumber+1]/table:table-cell[@office:value-type != 'string'])"
            />
          </xsl:with-param>
          <xsl:with-param name="rowNumber">
            <xsl:value-of select="$rowNumber+1"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>


<!-- Sonata: Number style for Charts -->
  <xsl:template match="number:date-style" mode="ChartnumFormat">
    <xsl:param name="numId"/>
    <c:numFmt>
      <xsl:attribute name="formatCode">
        <xsl:apply-templates mode="date"/>
        <xsl:text>;@</xsl:text>
      </xsl:attribute>
    </c:numFmt>
    <xsl:choose>
      <xsl:when test="following-sibling::number:date-style">
        <xsl:apply-templates select="following-sibling::number:date-style[1]" mode="ChartnumFormat">
          <xsl:with-param name="numId">
            <xsl:value-of select="$numId + 1"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="number:time-style" mode="ChartnumFormat">
    <xsl:param name="numId"/>
    <c:numFmt>
      <xsl:attribute name="formatCode">
        <xsl:apply-templates mode="date"/>
        <xsl:text>;@</xsl:text>
      </xsl:attribute>
    </c:numFmt>
    <xsl:choose>
      <xsl:when test="following-sibling::number:time-style">
        <xsl:apply-templates select="following-sibling::number:time-style[1]" mode="ChartnumFormat">
          <xsl:with-param name="numId">
            <xsl:value-of select="$numId + 1"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- insert year format -->

  <xsl:template match="number:year" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long'">yyyy</xsl:when>
      <xsl:otherwise>yy</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- insert month format -->

  <xsl:template match="number:month" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long' and @number:textual='true'">mmmm</xsl:when>
      <xsl:when test="@number:textual='true'">mmm</xsl:when>
      <xsl:when test="@number:style='long'">mm</xsl:when>
      <xsl:otherwise>m</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- insert day of week format -->

  <xsl:template match="number:day-of-week" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long'">dddd</xsl:when>
      <xsl:otherwise>ddd</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- insert day format -->

  <xsl:template match="number:day" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long'">dd</xsl:when>
      <xsl:otherwise>d</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- insert hour format -->

  <xsl:template match="number:hours" mode="date">
    <xsl:if test="parent::node()/@number:truncate-on-overflow='false'">[</xsl:if>
    <xsl:choose>
      <xsl:when test="@number:style='long'">hh</xsl:when>
      <xsl:otherwise>h</xsl:otherwise>
    </xsl:choose>
    <xsl:if test="parent::node()/@number:truncate-on-overflow='false'">]</xsl:if>
  </xsl:template>

  <!-- insert minute format -->

  <xsl:template match="number:minutes" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long'">mm</xsl:when>
      <xsl:otherwise>m</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- add am or pm -->

  <xsl:template match="number:am-pm" mode="date">AM/PM</xsl:template>

  <!-- insert second format -->

  <xsl:template match="number:seconds" mode="date">
    <xsl:choose>
      <xsl:when test="@number:style='long'">ss</xsl:when>
      <xsl:otherwise>s</xsl:otherwise>
    </xsl:choose>
    <xsl:if test="@number:decimal-places and @number:decimal-places != ''">
      <xsl:call-template name="AddDecimalPlaces">
        <xsl:with-param name="value">.</xsl:with-param>
        <xsl:with-param name="num">
          <xsl:value-of select="@number:decimal-places"/>
        </xsl:with-param>
        <xsl:with-param name="decimalReplacement">
          <xsl:choose>
            <xsl:when test="@number:decimal-replacement=''">#</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- add all formatting characters -->

  <xsl:template match="number:text" mode="date">
    <xsl:variable name="text">
      <xsl:value-of select="."/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when
        test="$text=':' or $text='-' or $text='/' or $text='\' or $text=' ' or $text=',' or $text=', ' or $text='.' or $text='. '">
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:when test="$text=''"/>
      <xsl:otherwise>
        <xsl:value-of select="concat(concat('&quot;',$text),'&quot;')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="number:text-style" mode="ChartnumFormat">
    <!-- @Description: inserts number format -->
    <!-- @Context: none -->
    <xsl:param name="numId"/>
    <!--(int) number format id -->
    <!--<xsl:param name="format"/>-->
    <!--(string) format code -->
    <xsl:param name="styleName"/>
    <!--(string) style name -->
    <xsl:variable name ="numTextStyleName">
      <xsl:value-of select ="@style:name"/>
    </xsl:variable>
    <xsl:if test ="key('numtextStyle',$numTextStyleName)">
      <xsl:for-each select ="key('numtextStyle',$numTextStyleName)">
        <xsl:variable name ="mainStyle">
          <xsl:value-of select ="@style:name"/>
        </xsl:variable>
        <xsl:variable name ="Data">
          <xsl:value-of select ="key('table-cell',$mainStyle)/@office:value"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test ="$Data=''">

          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name ="styleToBeUsed">
              <xsl:choose>
                <xsl:when test ="$Data &gt; 0">
                  <xsl:value-of select ="key('text',$numTextStyleName)/style:map[@style:condition='value()&gt;0']/@style:apply-style-name"/>
                </xsl:when>
                <xsl:when test ="$Data &lt; 0">
                  <xsl:value-of select ="key('text',$numTextStyleName)/style:map[@style:condition='value()&lt;0']/@style:apply-style-name"/>
                </xsl:when>
                <xsl:when test ="$Data = 0">
                  <xsl:value-of select ="key('text',$numTextStyleName)/style:map[@style:condition='value()=0']/@style:apply-style-name"/>
                </xsl:when>
              </xsl:choose>
            </xsl:variable>
            <xsl:for-each select ="key('number',$styleToBeUsed)">
              <c:numFmt>
                <xsl:attribute name="formatCode">
                  <xsl:variable name="thisFormat">
                    <xsl:call-template name="GetFormatCodeForText">
                      <xsl:with-param name ="styleToBeUsed">
                        <xsl:value-of select ="$styleToBeUsed"/>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:variable>
                  <xsl:value-of select="$thisFormat"/>
                </xsl:attribute>
              </c:numFmt>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:apply-templates select="following-sibling::number:text-style[1]" mode="ChartnumFormat">
        <xsl:with-param name="numId">
          <xsl:value-of select="$numId + 1"/>
        </xsl:with-param>
        <xsl:with-param name="styleName">
          <xsl:value-of select="substring(@style:name,1,string-length(@style:name)-2)"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test ="not(key('numtextStyle',$numTextStyleName))">
      <xsl:apply-templates select="following-sibling::number:text-style" mode="ChartnumFormat">
        <xsl:with-param name="numId">
          <xsl:value-of select="$numId + 1"/>
        </xsl:with-param>
        <xsl:with-param name="styleName"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="number:percentage-style" mode="ChartnumFormat">

    <!-- @Description: inserts percentage formats -->
    <!-- @Context: none -->

    <xsl:param name="numId"/>
    <!--(int) number format id -->
    <xsl:param name="format"/>
    <!--(string) format code -->
    <xsl:param name="styleName"/>
    <!--(string) style name -->

    <xsl:choose>

      <!-- separate format or last part of partly format -->
      <xsl:when
        test="not((substring(@style:name,string-length(@style:name)-1) = 'P0') or (substring(@style:name,string-length(@style:name)-1) = 'P1') or (substring(@style:name,string-length(@style:name)-1) = 'P2'))">
        <c:numFmt>
          <xsl:attribute name="formatCode">
            <xsl:variable name="thisFormat">
              <xsl:call-template name="GetFormatCode"/>

            </xsl:variable>
            <xsl:choose>
              <xsl:when test="@style:name = $styleName">
                <xsl:value-of select="concat($format,$thisFormat,'%')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat($thisFormat,'%')"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </c:numFmt>
        <xsl:choose>
          <xsl:when test="following-sibling::number:percentage-style">
            <xsl:apply-templates select="following-sibling::number:percentage-style[1]"
              mode="ChartnumFormat">
              <xsl:with-param name="numId">
                <xsl:value-of select="$numId + 1"/>
              </xsl:with-param>
              <xsl:with-param name="format">
                <xsl:choose>
                  <xsl:when test="@style:name = $styleName"/>
                  <xsl:otherwise>
                    <xsl:value-of select="$format"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="styleName"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:when>

      <!-- partly format -->
      <xsl:otherwise>
        <xsl:variable name="thisFormat">
          <xsl:call-template name="GetFormatCode"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="following-sibling::number:percentage-style">
            <xsl:apply-templates select="following-sibling::number:percentage-style[1]"
              mode="ChartnumFormat">
              <xsl:with-param name="numId">
                <xsl:value-of select="$numId + 1"/>
              </xsl:with-param>
              <xsl:with-param name="format">
                <xsl:choose>
                  <xsl:when test="@style:name=substring($styleName,1,string-length($styleName)-2)">
                    <xsl:value-of select="concat($format,$thisFormat,'%;')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="concat($thisFormat,'%;')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="styleName">
                <xsl:value-of select="substring(@style:name,1,string-length(@style:name)-2)"/>
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <xsl:template match="number:currency-style" mode="ChartnumFormat">

    <!-- @Description: inserts currency formats -->
    <!--  @Context: none -->

    <xsl:param name="numId"/>
    <!--(int) number format id-->
    <xsl:param name="format"/>
    <!-- (string) format code -->
    <xsl:param name="styleName"/>
    <!-- (string) style name -->

    <xsl:variable name="currencySymbol">
      <xsl:call-template name="ConvertValueSymbol">
        <xsl:with-param name="symbol">
          <xsl:value-of select="number:currency-symbol"/>
        </xsl:with-param>
        <xsl:with-param name="language" select="number:currency-symbol/@number:language"/>
        <xsl:with-param name="country" select="number:currency-symbol/@number:country"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:choose>

      <!-- separate format or last part of partly format -->
      <xsl:when
        test="not((substring(@style:name,string-length(@style:name)-1) = 'P0') or (substring(@style:name,string-length(@style:name)-1) = 'P1') or (substring(@style:name,string-length(@style:name)-1) = 'P2'))">
        <c:numFmt>
          <xsl:attribute name="formatCode">
            <xsl:variable name="thisFormat">

              <xsl:call-template name="GetFormatCode">
                <xsl:with-param name="currencySymbol" select="$currencySymbol"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="@style:name = $styleName">
                <xsl:value-of select="concat($format,$thisFormat)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$thisFormat"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </c:numFmt>
        <xsl:choose>
          <xsl:when test="following-sibling::number:currency-style">
            <xsl:apply-templates select="following-sibling::number:currency-style[1]"
              mode="ChartnumFormat">
              <xsl:with-param name="numId">
                <xsl:value-of select="$numId + 1"/>
              </xsl:with-param>
              <xsl:with-param name="format">
                <xsl:choose>
                  <xsl:when test="@style:name = $styleName"/>
                  <xsl:otherwise>
                    <xsl:value-of select="$format"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="styleName"/>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:when>

      <!-- partly format -->
      <xsl:otherwise>
        <xsl:variable name="thisFormat">
          <xsl:call-template name="GetFormatCode">
            <xsl:with-param name="currencySymbol" select="$currencySymbol"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="following-sibling::number:currency-style">
            <xsl:apply-templates select="following-sibling::number:currency-style[1]"
              mode="ChartnumFormat">
              <xsl:with-param name="numId">
                <xsl:value-of select="$numId + 1"/>
              </xsl:with-param>
              <xsl:with-param name="format">
                <xsl:choose>
                  <xsl:when test="@style:name=substring($styleName,1,string-length($styleName)-2)">
                    <xsl:value-of select="concat($format,$thisFormat,';')"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="concat($thisFormat,';')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="styleName">
                <xsl:value-of select="substring(@style:name,1,string-length(@style:name)-2)"/>
              </xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <xsl:template name="GetFormatCode">

    <!-- @Description: gets number code format -->
    <!-- @Context: none -->

    <xsl:param name="currencySymbol"/>
    <!--(string) currency symbol if it's currency format -->

    <xsl:variable name="value">
      <xsl:choose>

        <!-- add leading zeros if min-integer-digits > 0 -->
        <xsl:when
          test="number:number/@number:min-integer-digits and number:number/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:number/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when
          test="number:scientific-number/@number:min-integer-digits and number:scientific-number/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:scientific-number/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when
          test="number:fraction/@number:min-integer-digits and number:fraction/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:fraction/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test="number:fraction/@number:min-integer-digits = 0">#</xsl:when>

        <!-- plain fraction format -->
        <xsl:when test="number:fraction"/>

        <xsl:otherwise>#</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="endValue">
      <xsl:choose>

        <!-- add decimal places -->
        <xsl:when
          test="number:number/@number:decimal-places &gt; 0 or (number:number and not(number:number/@number:decimal-places) and not(number:fraction) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places &gt; 0)">
          <xsl:call-template name="AddDecimalPlaces">
            <xsl:with-param name="value">
              <xsl:choose>

                <!-- add grouping -->
                <xsl:when
                  test="number:number/@number:grouping and number:number/@number:grouping = 'true'">
                  <xsl:call-template name="AddGrouping">
                    <xsl:with-param name="value">
                      <xsl:value-of select="concat($value,'.')"/>
                    </xsl:with-param>
                    <xsl:with-param name="numDigits">
                      <xsl:choose>
                        <xsl:when test="number:number/@number:min-integer-digits">
                          <xsl:value-of select="3 - number:number/@number:min-integer-digits"/>
                        </xsl:when>
                        <xsl:otherwise>2</xsl:otherwise>
                      </xsl:choose>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:value-of select="concat($value,'.')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="num">
              <xsl:choose>
                <xsl:when test="number:number/@number:decimal-places &gt; 0">
                  <xsl:value-of select="number:number/@number:decimal-places"/>
                </xsl:when>
                <xsl:when test="not(number:number/@number:decimal-places)">
                  <xsl:value-of
                    select="document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                  />
                </xsl:when>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="decimalReplacement">
              <xsl:choose>
                <xsl:when test="number:number/@number:decimal-replacement=''">#</xsl:when>
                <xsl:when
                  test="not(number:number/@number:decimal-places) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                  >#</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>

          <xsl:if
            test="number:number/@number:display-factor and number:number/@number:display-factor != '' ">
            <xsl:call-template name="UseThousandDisplayFactor">
              <xsl:with-param name="displayFactor">
                <xsl:value-of select="number:number/@number:display-factor"/>
              </xsl:with-param>
              <xsl:with-param name="value">
                <xsl:value-of select="''"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>

        </xsl:when>

        <!-- add decimal places to scientific format -->
        <xsl:when
          test="number:scientific-number/@number:decimal-places &gt; 0 or (number:scientific-number and not(number:scientific-number/@number:decimal-places) and not(number:fraction) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places &gt; 0)">
          <xsl:variable name="scientificFormat">
            <xsl:call-template name="AddDecimalPlaces">
              <xsl:with-param name="value">
                <xsl:choose>

                  <!-- add grouping -->
                  <xsl:when
                    test="number:scientific-number/@number:grouping and number:scientific-number/@number:grouping = 'true'">
                    <xsl:call-template name="AddGrouping">
                      <xsl:with-param name="value">
                        <xsl:value-of select="concat($value,'.')"/>
                      </xsl:with-param>
                      <xsl:with-param name="numDigits">
                        <xsl:choose>
                          <xsl:when test="number:scientific-number/@number:min-integer-digits">
                            <xsl:value-of
                              select="3 - number:scientific-number/@number:min-integer-digits"/>
                          </xsl:when>
                          <xsl:otherwise>2</xsl:otherwise>
                        </xsl:choose>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:when>

                  <xsl:otherwise>
                    <xsl:value-of select="concat($value,'.')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="num">
                <xsl:choose>
                  <xsl:when test="number:scientific-number/@number:decimal-places &gt; 0">
                    <xsl:value-of select="number:scientific-number/@number:decimal-places"/>
                  </xsl:when>
                  <xsl:when test="not(number:scientific-number/@number:decimal-places)">
                    <xsl:value-of
                      select="document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                    />
                  </xsl:when>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="decimalReplacement">
                <xsl:choose>
                  <xsl:when test="number:scientific-number/@number:decimal-replacement=''">#</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
            <xsl:if
              test="number:scientific-number/@number:display-factor and number:scientific-number/@number:display-factor != '' ">
              <xsl:call-template name="UseThousandDisplayFactor">
                <xsl:with-param name="displayFactor">
                  <xsl:value-of select="number:number/@number:display-factor"/>
                </xsl:with-param>
                <xsl:with-param name="value">
                  <xsl:value-of select="''"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>
          </xsl:variable>
          <xsl:call-template name="AddMinExponentDigits">
            <xsl:with-param name="number">
              <xsl:value-of select="number:scientific-number/@number:min-exponent-digits"/>
            </xsl:with-param>
            <xsl:with-param name="scientificFormat" select="concat($scientificFormat,'E+')"/>
          </xsl:call-template>
        </xsl:when>

        <!-- add fraction -->
        <xsl:when test="number:fraction">
          <xsl:call-template name="AddFraction">
            <xsl:with-param name="value">
              <xsl:choose>

                <!-- add grouping -->
                <xsl:when
                  test="number:fraction/@number:grouping and number:fraction/@number:grouping = 'true'">
                  <xsl:call-template name="AddGrouping">
                    <xsl:with-param name="value">
                      <xsl:value-of select="concat($value,'.')"/>
                    </xsl:with-param>
                    <xsl:with-param name="numDigits">
                      <xsl:choose>
                        <xsl:when test="number:fraction/@number:min-integer-digits">
                          <xsl:value-of select="3 - number:fraction/@number:min-integer-digits"/>
                        </xsl:when>
                        <xsl:otherwise>2</xsl:otherwise>
                      </xsl:choose>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:value-of select="concat($value,'.')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="numerator">
              <xsl:value-of select="number:fraction/@number:min-numerator-digits"/>
            </xsl:with-param>
            <xsl:with-param name="denominator">
              <xsl:value-of select="number:fraction/@number:min-denominator-digits"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>

        <!-- add scientific number format -->
        <xsl:when test="number:scientific-number">
          <xsl:variable name="scientificFormat">
            <xsl:choose>

              <!-- add grouping -->
              <xsl:when
                test="number:scientific-number/@number:grouping and number:scientific-number/@number:grouping = 'true'">
                <xsl:call-template name="AddGrouping">
                  <xsl:with-param name="value">
                    <xsl:value-of select="$value"/>
                  </xsl:with-param>
                  <xsl:with-param name="numDigits">
                    <xsl:choose>
                      <xsl:when test="number:scientific-number/@number:min-integer-digits">
                        <xsl:value-of
                          select="3 - number:scientific-number/@number:min-integer-digits"/>
                      </xsl:when>
                      <xsl:otherwise>2</xsl:otherwise>
                    </xsl:choose>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>

              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when
                    test="number:scientific-number/@number:display-factor and number:scientific-number/@number:display-factor!=''">
                    <xsl:call-template name="UseThousandDisplayFactor">
                      <xsl:with-param name="displayFactor">
                        <xsl:value-of select="number:scientific-number/@number:display-factor"/>
                      </xsl:with-param>
                      <xsl:with-param name="value">
                        <xsl:value-of select="$value"/>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$value"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:call-template name="AddMinExponentDigits">
            <xsl:with-param name="number">
              <xsl:value-of select="number:scientific-number/@number:min-exponent-digits"/>
            </xsl:with-param>
            <xsl:with-param name="scientificFormat" select="concat($scientificFormat,'.E+')"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:otherwise>
          <xsl:choose>

            <!-- add grouping -->
            <xsl:when
              test="number:number/@number:grouping and number:number/@number:grouping = 'true'">
              <xsl:call-template name="AddGrouping">
                <xsl:with-param name="value">
                  <xsl:value-of select="$value"/>
                </xsl:with-param>
                <xsl:with-param name="numDigits">
                  <xsl:choose>
                    <xsl:when test="number:number/@number:min-integer-digits">
                      <xsl:value-of select="3 - number:number/@number:min-integer-digits"/>
                    </xsl:when>
                    <xsl:otherwise>2</xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>
              <xsl:choose>
                <xsl:when
                  test="number:number/@number:display-factor and number:number/@number:display-factor!=''">
                  <xsl:call-template name="UseThousandDisplayFactor">
                    <xsl:with-param name="displayFactor">
                      <xsl:value-of select="number:number/@number:display-factor"/>
                    </xsl:with-param>
                    <xsl:with-param name="value">
                      <xsl:value-of select="$value"/>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$value"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- add color to negative number formatting when necessary -->
    <xsl:variable name="finalValue">
      <xsl:choose>
        <xsl:when test="style:text-properties/@fo:color='#ff0000'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Red]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Red]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#00ffff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Cyan]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Cyan]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#0000ff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Blue]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Blue]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#00ff00'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Green]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Green]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ffff00'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Yellow]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Yellow]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ff00ff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Magenta]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Magenta]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ffffff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[White]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[White]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <xsl:otherwise>
          <xsl:value-of select="$endValue"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- add currency symbol -->
    <xsl:variable name="valueWithCurrency">
      <xsl:choose>
        <xsl:when
          test="$currencySymbol and $currencySymbol!='' and number:number/following-sibling::number:currency-symbol">

          <!-- add space before currency symbol -->
          <xsl:variable name="currencyFormat">
            <xsl:choose>
              <xsl:when test="number:number/following-sibling::number:text = ' '">
                <xsl:value-of select="concat('\ ',$currencySymbol)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$currencySymbol"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:value-of select="concat($finalValue,$currencyFormat)"/>
        </xsl:when>
        <xsl:when
          test="$currencySymbol and $currencySymbol!='' and number:number/preceding-sibling::number:currency-symbol">

          <!-- add space after currency symbol -->
          <xsl:variable name="currencyFormat2">
            <xsl:choose>
              <xsl:when test="number:number/preceding-sibling::number:text = ' '">
                <xsl:value-of select="concat($currencySymbol,'\ ')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$currencySymbol"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="concat($currencyFormat2,$finalValue)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$finalValue"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="startText">
      <xsl:choose>
        <xsl:when
        test="number:text = '-'">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:when
          test="number:text[not(preceding-sibling::node())] != ' ' and number:text[not(preceding-sibling::node())] != '.'">
          <xsl:value-of select="number:text[not(preceding-sibling::node())]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="endText">
      <xsl:choose>
        <xsl:when
          test="number:text[not(following-sibling::node())] != ' ' and number:text[not(following-sibling::node())] != '-' and number:text[not(preceding-sibling::node())] != '.'">
          <xsl:value-of select="number:text[not(following-sibling::node())]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- handle text in number format -->
    <xsl:choose>
      <xsl:when test="$startText != '' and $endText != '' ">
        <xsl:value-of
          select="concat('&quot;',$startText,'&quot;',$valueWithCurrency,'&quot;',$endText,'&quot;')"
        />
      </xsl:when>
      <xsl:when test="$startText != '' ">
        <xsl:value-of select="concat('&quot;',$startText,'&quot;',$valueWithCurrency)"/>
      </xsl:when>
      <xsl:when test="$endText != '' ">
        <xsl:value-of select="concat($valueWithCurrency,'&quot;',$endText,'&quot;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$valueWithCurrency"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="AddLeadingZeros">

    <!-- @Description: adds leading zeros -->
    <!-- @Context: none -->

    <xsl:param name="num"/>
    <!--(int) number of leading zeros-->
    <xsl:param name="val"/>
    <!--(string) output format value -->
    <xsl:choose>
      <xsl:when test="$num &gt; 0">
        <xsl:call-template name="AddLeadingZeros">
          <xsl:with-param name="num">
            <xsl:value-of select="$num - 1"/>
          </xsl:with-param>
          <xsl:with-param name="val">
            <xsl:value-of select="concat('0',$val)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$val"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="AddMinExponentDigits">

    <!-- @Description: adds minimum exponent-digits -->
    <!-- @Context: none -->

    <xsl:param name="number"/>
    <!-- (int) number of minimum exponent digits -->
    <xsl:param name="scientificFormat"/>
    <!-- (string) whole scientific format -->
    <xsl:choose>
      <xsl:when test="$number &gt; 0">
        <xsl:call-template name="AddMinExponentDigits">
          <xsl:with-param name="number">
            <xsl:value-of select="$number -1"/>
          </xsl:with-param>
          <xsl:with-param name="scientificFormat">
            <xsl:value-of select="concat($scientificFormat,'0')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$scientificFormat"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="AddGrouping">

    <!-- @Description: adds grouping -->
    <!-- @Context: none -->

    <xsl:param name="numDigits"/>
    <!--(int) number of digits -->
    <xsl:param name="value"/>
    <!-- (string) output format value -->
    <xsl:choose>
      <xsl:when test="$numDigits &gt; 0">
        <xsl:call-template name="AddGrouping">
          <xsl:with-param name="numDigits">
            <xsl:value-of select="$numDigits -1"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="concat('#',$value)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('#,',$value)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="AddDecimalPlaces">

    <!-- @Description: adds decimal places -->
    <!-- @Context: none -->

    <xsl:param name="value"/>
    <!--(string) format value -->
    <xsl:param name="num"/>
    <!-- (int) decimal places -->
    <xsl:param name="decimalReplacement"/>
    <!--(string) decimal replacement -->
    <xsl:choose>
      <xsl:when test="$num &gt; 0">
        <xsl:call-template name="AddDecimalPlaces">
          <xsl:with-param name="value">
            <xsl:value-of select="concat($value,$decimalReplacement)"/>
          </xsl:with-param>
          <xsl:with-param name="num">
            <xsl:value-of select="$num - 1"/>
          </xsl:with-param>
          <xsl:with-param name="decimalReplacement" select="$decimalReplacement"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="AddFraction">

    <!-- @Description: adds fraction format -->
    <!-- @Context: none -->

    <xsl:param name="value"/>
    <!-- (string) output fraction format -->
    <xsl:param name="numerator"/>
    <!-- (int) number of digits in numerator -->
    <xsl:param name="denominator"/>
    <!-- (int) number of digits in denominator -->
    <xsl:variable name="fraction">
      <xsl:call-template name="ConvertNumeratorDenominator">
        <xsl:with-param name="numerator" select="$numerator"/>
        <xsl:with-param name="denominator" select="$denominator"/>
        <xsl:with-param name="value">/</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="concat(translate($value,'.',''),'&quot; &quot;',$fraction)"/>
  </xsl:template>

  <xsl:template name="ConvertNumeratorDenominator">

    <!-- @Description: converts number of digits in numerator and denominator into plain fraction format -->
    <!-- @Context: none -->

    <xsl:param name="numerator"/>
    <!-- (int) number of digits in numerator -->
    <xsl:param name="denominator"/>
    <!-- (int) number of digits in denominator -->
    <xsl:param name="value"/>
    <!-- (string) output fraction format -->
    <xsl:choose>
      <xsl:when test="$numerator &gt; 0">
        <xsl:call-template name="ConvertNumeratorDenominator">
          <xsl:with-param name="numerator">
            <xsl:value-of select="$numerator - 1"/>
          </xsl:with-param>
          <xsl:with-param name="denominator" select="$denominator"/>
          <xsl:with-param name="value">
            <xsl:value-of select="concat('?',$value)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$denominator &gt; 0">
        <xsl:call-template name="ConvertNumeratorDenominator">
          <xsl:with-param name="numerator" select="$numerator"/>
          <xsl:with-param name="denominator">
            <xsl:value-of select="$denominator - 1"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="concat($value,'?')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="UseThousandDisplayFactor">

    <!-- @Description: inserts display factor -->
    <!-- @Context: none -->

    <xsl:param name="displayFactor"/>
    <!--(int) display factor -->
    <xsl:param name="value"/>
    <!--(string) output format value -->
    <xsl:choose>
      <xsl:when test="string-length($displayFactor) &gt; 1">
        <xsl:call-template name="UseThousandDisplayFactor">
          <xsl:with-param name="displayFactor">
            <xsl:value-of select="number($displayFactor) div 1000"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="concat($value,',')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- template to get number format id -->

  <xsl:template name="GetNumFmtId">
    <xsl:param name="numStyle"/>
    <xsl:param name="numStyleCount"/>
    <xsl:param name="styleNumStyleCount"/>
    <xsl:param name="percentStyleCount"/>
    <xsl:param name="stylePercentStyleCount"/>
    <xsl:param name="currencyStyleCount"/>
    <xsl:param name="styleCurrencyStyleCount"/>
    <xsl:param name="dateStyleCount"/>
    <xsl:param name="styleDateStyleCount"/>
    <xsl:param name="timeStyleCount"/>
    <xsl:choose>
      <xsl:when test="key('number',$numStyle)">
        <xsl:for-each select="key('number',$numStyle)">
          <xsl:value-of select="count(preceding-sibling::number:number-style)+1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- 
		Defect: 1959472
		Code By :Vijayeta
		Date    :4th Jul '08
		Desc    :User Defined format ##### BF not handeled 
	-->
      <xsl:when test="key('text',$numStyle)">
        <xsl:for-each select="key('text',$numStyle)">
          <xsl:value-of select="count(preceding-sibling::number:text-style)+1"/>
        </xsl:for-each>
      </xsl:when>
      <!-- End Of code change for 1959472-->
      <xsl:when
        test="document('styles.xml')/office:document-styles/office:styles/number:number-style[@style:name=$numStyle]">
        <xsl:for-each
          select="document('styles.xml')/office:document-styles/office:styles/number:number-style[@style:name=$numStyle]">
          <xsl:value-of select="count(preceding-sibling::number:number-style)+1+$numStyleCount"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="key('percentage',$numStyle)">
        <xsl:for-each select="key('percentage',$numStyle)">
          <xsl:value-of
            select="count(preceding-sibling::number:percentage-style)+1+$numStyleCount+$styleNumStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when
        test="document('styles.xml')/office:document-styles/office:styles/number:percentage-style[@style:name=$numStyle]">
        <xsl:for-each
          select="document('styles.xml')/office:document-styles/office:styles/number:percentage-style[@style:name=$numStyle]">
          <xsl:value-of
            select="count(preceding-sibling::number:percentage-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="key('currency',$numStyle)">
        <xsl:for-each select="key('currency',$numStyle)">
          <xsl:value-of
            select="count(preceding-sibling::number:currency-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when
        test="document('styles.xml')/office:document-styles/office:styles/number:currency-style[@style:name=$numStyle]">
        <xsl:for-each
          select="document('styles.xml')/office:document-styles/office:styles/number:currency-style[@style:name=$numStyle]">
          <xsl:value-of
            select="count(preceding-sibling::number:currency-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount+$currencyStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="key('date',$numStyle)">
        <xsl:for-each select="key('date',$numStyle)">
          <xsl:value-of
            select="count(preceding-sibling::number:date-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount+$currencyStyleCount+$styleCurrencyStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when
        test="document('styles.xml')/office:document-styles/office:styles/number:date-style[@style:name=$numStyle]">
        <xsl:for-each
          select="document('styles.xml')/office:document-styles/office:styles/number:date-style[@style:name=$numStyle]">
          <xsl:value-of
            select="count(preceding-sibling::number:date-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount+$currencyStyleCount+$styleCurrencyStyleCount+$dateStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="key('time',$numStyle)">
        <xsl:for-each select="key('time',$numStyle)">
          <xsl:value-of
            select="count(preceding-sibling::number:time-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount+$currencyStyleCount+$styleCurrencyStyleCount+$dateStyleCount+$styleDateStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:when
        test="document('styles.xml')/office:document-styles/office:styles/number:time-style[@style:name=$numStyle]">
        <xsl:for-each
          select="document('styles.xml')/office:document-styles/office:styles/number:time-style[@style:name=$numStyle]">
          <xsl:value-of
            select="count(preceding-sibling::number:time-style)+1+$numStyleCount+$styleNumStyleCount+$percentStyleCount+$stylePercentStyleCount+$currencyStyleCount+$styleCurrencyStyleCount+$dateStyleCount+$styleDateStyleCount+$timeStyleCount"
          />
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ConvertValueSymbol">
    <xsl:param name="symbol"/>
    <xsl:param name="country"/>
    <xsl:param name="language"/>
    <xsl:choose>
      <xsl:when test="$symbol = '$' and $country = 'AU' and $language = 'en' ">[$$-C09]</xsl:when>
      <xsl:when test="$symbol = '$' and $country = 'CA' and $language = 'en' ">[$$-1009]</xsl:when>
      <xsl:when test="$symbol = '$' and $country = 'NZ' and $language = 'en' ">[$$-1409]</xsl:when>
      <xsl:when test="$symbol = '$' ">[$$-409]</xsl:when>
      <xsl:when test="$symbol = 'SFr.' and $language = 'it' and $country = 'CH' ">[$SFr.-810]</xsl:when>
      <xsl:when test="$symbol = 'SFr.' ">[$SFr.-807]</xsl:when>
      <xsl:when test="$symbol = 'SIT' and $language = 'sl' and $country = 'SI' ">[$SIT-424]</xsl:when>
      <xsl:when test="$symbol = 'kr' and $language = 'da' and $country = 'DK' ">[$kr-406]</xsl:when>
      <xsl:when test="$symbol = 'kr' and $language = 'nn' and $country = 'NO' ">[$kr-814]</xsl:when>
      <xsl:when test="$symbol = 'kr' and $language = 'et' and $country = 'EE' ">[$kr-425]</xsl:when>
      <xsl:when test="$symbol = 'kr' and $country = 'NO' ">[$kr-414]</xsl:when>
      <xsl:when test="$symbol = 'kr' ">[$kr-41D]</xsl:when>
      <xsl:when test="$symbol = 'kr.' ">[$kr.-40F]</xsl:when>
      <xsl:when test="$symbol = 'Kč' ">[$Kč-405]</xsl:when>
      <xsl:when test="$symbol = 'Sk' ">[$Sk-41B]</xsl:when>
      <xsl:when test="$symbol = 'Lt' ">[$Lt-427]</xsl:when>
      <xsl:when test="$symbol = 'Ls' ">[$Ls-426]</xsl:when>
      <xsl:when test="$symbol = 'lei' ">[$lei-418]</xsl:when>
      <xsl:when test="$symbol = 'Din' ">[$Din.-81A]</xsl:when>
      <xsl:when test="$symbol = 'KM' ">[$KM-141A]</xsl:when>
      <xsl:when test="$symbol = 'HK$' ">[$HK$-C04]</xsl:when>
      <xsl:when test="$symbol = 'NT$' ">[$NT$-404]</xsl:when>
      <xsl:when test="$symbol = 'Ft' ">[$Ft-40E]</xsl:when>
      <xsl:when test="$symbol = '￥' and $country = 'CN' and $language = 'zh' ">[$￥-804]</xsl:when>
      <xsl:when test="$symbol = '￥' ">[$¥-411]</xsl:when>
      <xsl:when test="$symbol = '￦' ">[$₩-412]</xsl:when>
      <xsl:when test="$symbol = 'USD' ">[$USD]</xsl:when>
      <xsl:when test="$symbol = '£' and $country = 'LU' and $language = 'lb' ">[$£-452]</xsl:when>
      <xsl:when test="$symbol = '£' ">[$£-809]</xsl:when>
      <xsl:when test="$symbol = 'GBP' ">[$GBP]</xsl:when>
      <xsl:when test="$symbol = 'zł' ">&quot;zł&quot;</xsl:when>
      <xsl:when test="$symbol = 'PLN' ">[$PLN]</xsl:when>
      <xsl:when test="$symbol = 'ДИН' ">[$Дин.-C1A]</xsl:when>
      <xsl:when test="$symbol = 'лв' or $symbol = 'лв.' ">[$лв-402]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'IE' and $language = 'ga' ">[$€-1809]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'PT' and $language = 'pt' ">[$€-816]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'NL' and $language = 'nl' ">[$€-413]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'BE' and $language = 'nl' ">[$€-813]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'FI' and $language = 'sv' ">[$€-81D]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'MC' and $language = 'fr' ">[$€-180C]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'LU' and $language = 'fr' ">[$€-140C]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'BE' and $language = 'fr' ">[$€-80C]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'FR' and $language = 'fr' ">[$€-40C]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'LU' and $language = 'de' ">[$€-1007]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'AT' and $language = 'de' ">[$€-C07]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'DE' and $language = 'de' ">[$€-407]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'FI' ">[$€-40B]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'GR' ">[$€-408]</xsl:when>
      <xsl:when test="$symbol = '€' and $country = 'IT' ">[$€-410]</xsl:when>
      <xsl:when test="$symbol = '€' ">
        <xsl:choose>
          <xsl:when test="following-sibling::number:number">[$€-2]</xsl:when>
          <xsl:otherwise>[$€-1]</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$symbol = 'EUR' ">[$EUR]</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="GetFormatCodeForText">
    <xsl:param name ="styleToBeUsed"/>
    <!-- @Description: gets number code format -->
    <!-- @Context: none -->

    <xsl:param name="currencySymbol"/>
    <!--(string) currency symbol if it's currency format -->

    <xsl:variable name="value">
      <xsl:choose>
        <!-- add leading zeros if min-integer-digits > 0 -->
        <xsl:when
				  test="number:number/@number:min-integer-digits and number:number/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:number/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when
				  test="number:scientific-number/@number:min-integer-digits and number:scientific-number/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:scientific-number/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when
				  test="number:fraction/@number:min-integer-digits and number:fraction/@number:min-integer-digits &gt; 0">
          <xsl:call-template name="AddLeadingZeros">
            <xsl:with-param name="num">
              <xsl:value-of select="number:fraction/@number:min-integer-digits"/>
            </xsl:with-param>
            <xsl:with-param name="val"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:when test="number:fraction/@number:min-integer-digits = 0">#</xsl:when>

        <!-- plain fraction format -->
        <xsl:when test="number:fraction"/>

        <xsl:otherwise>#</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="endValue">
      <xsl:choose>

        <!-- add decimal places -->
        <xsl:when
				  test="number:number/@number:decimal-places &gt; 0 or (number:number and not(number:number/@number:decimal-places) and not(number:fraction) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places &gt; 0)">
          <xsl:call-template name="AddDecimalPlaces">
            <xsl:with-param name="value">
              <xsl:choose>

                <!-- add grouping -->
                <xsl:when
								  test="number:number/@number:grouping and number:number/@number:grouping = 'true'">
                  <xsl:call-template name="AddGrouping">
                    <xsl:with-param name="value">
                      <xsl:value-of select="concat($value,'.')"/>
                    </xsl:with-param>
                    <xsl:with-param name="numDigits">
                      <xsl:choose>
                        <xsl:when test="number:number/@number:min-integer-digits">
                          <xsl:value-of select="3 - number:number/@number:min-integer-digits"/>
                        </xsl:when>
                        <xsl:otherwise>2</xsl:otherwise>
                      </xsl:choose>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:value-of select="concat($value,'.')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="num">
              <xsl:choose>
                <xsl:when test="number:number/@number:decimal-places &gt; 0">
                  <xsl:value-of select="number:number/@number:decimal-places"/>
                </xsl:when>
                <xsl:when test="not(number:number/@number:decimal-places)">
                  <xsl:value-of
									  select="document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                  />
                </xsl:when>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="decimalReplacement">
              <xsl:choose>
                <xsl:when test="number:number/@number:decimal-replacement=''">#</xsl:when>
                <xsl:when
								  test="not(number:number/@number:decimal-places) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                  >#</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>

          <xsl:if
					  test="number:number/@number:display-factor and number:number/@number:display-factor != '' ">
            <xsl:call-template name="UseThousandDisplayFactor">
              <xsl:with-param name="displayFactor">
                <xsl:value-of select="number:number/@number:display-factor"/>
              </xsl:with-param>
              <xsl:with-param name="value">
                <xsl:value-of select="''"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:if>

        </xsl:when>

        <!-- add decimal places to scientific format -->
        <xsl:when
				  test="number:scientific-number/@number:decimal-places &gt; 0 or (number:scientific-number and not(number:scientific-number/@number:decimal-places) and not(number:fraction) and document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places &gt; 0)">
          <xsl:variable name="scientificFormat">
            <xsl:call-template name="AddDecimalPlaces">
              <xsl:with-param name="value">
                <xsl:choose>

                  <!-- add grouping -->
                  <xsl:when
									  test="number:scientific-number/@number:grouping and number:scientific-number/@number:grouping = 'true'">
                    <xsl:call-template name="AddGrouping">
                      <xsl:with-param name="value">
                        <xsl:value-of select="concat($value,'.')"/>
                      </xsl:with-param>
                      <xsl:with-param name="numDigits">
                        <xsl:choose>
                          <xsl:when test="number:scientific-number/@number:min-integer-digits">
                            <xsl:value-of
														  select="3 - number:scientific-number/@number:min-integer-digits"/>
                          </xsl:when>
                          <xsl:otherwise>2</xsl:otherwise>
                        </xsl:choose>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:when>

                  <xsl:otherwise>
                    <xsl:value-of select="concat($value,'.')"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="num">
                <xsl:choose>
                  <xsl:when test="number:scientific-number/@number:decimal-places &gt; 0">
                    <xsl:value-of select="number:scientific-number/@number:decimal-places"/>
                  </xsl:when>
                  <xsl:when test="not(number:scientific-number/@number:decimal-places)">
                    <xsl:value-of
										  select="document('styles.xml')/office:document-styles/office:styles/style:default-style/style:table-cell-properties/@style:decimal-places"
                    />
                  </xsl:when>
                </xsl:choose>
              </xsl:with-param>
              <xsl:with-param name="decimalReplacement">
                <xsl:choose>
                  <xsl:when test="number:scientific-number/@number:decimal-replacement=''">#</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
            <xsl:if
						  test="number:scientific-number/@number:display-factor and number:scientific-number/@number:display-factor != '' ">
              <xsl:call-template name="UseThousandDisplayFactor">
                <xsl:with-param name="displayFactor">
                  <xsl:value-of select="number:number/@number:display-factor"/>
                </xsl:with-param>
                <xsl:with-param name="value">
                  <xsl:value-of select="''"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:if>
          </xsl:variable>
          <xsl:call-template name="AddMinExponentDigits">
            <xsl:with-param name="number">
              <xsl:value-of select="number:scientific-number/@number:min-exponent-digits"/>
            </xsl:with-param>
            <xsl:with-param name="scientificFormat" select="concat($scientificFormat,'E+')"/>
          </xsl:call-template>
        </xsl:when>

        <!-- add fraction -->
        <xsl:when test="number:fraction">
          <xsl:call-template name="AddFraction">
            <xsl:with-param name="value">
              <xsl:choose>

                <!-- add grouping -->
                <xsl:when
								  test="number:fraction/@number:grouping and number:fraction/@number:grouping = 'true'">
                  <xsl:call-template name="AddGrouping">
                    <xsl:with-param name="value">
                      <xsl:value-of select="concat($value,'.')"/>
                    </xsl:with-param>
                    <xsl:with-param name="numDigits">
                      <xsl:choose>
                        <xsl:when test="number:fraction/@number:min-integer-digits">
                          <xsl:value-of select="3 - number:fraction/@number:min-integer-digits"/>
                        </xsl:when>
                        <xsl:otherwise>2</xsl:otherwise>
                      </xsl:choose>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>

                <xsl:otherwise>
                  <xsl:value-of select="concat($value,'.')"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="numerator">
              <xsl:value-of select="number:fraction/@number:min-numerator-digits"/>
            </xsl:with-param>
            <xsl:with-param name="denominator">
              <xsl:value-of select="number:fraction/@number:min-denominator-digits"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>

        <!-- add scientific number format -->
        <xsl:when test="number:scientific-number">
          <xsl:variable name="scientificFormat">
            <xsl:choose>

              <!-- add grouping -->
              <xsl:when
							  test="number:scientific-number/@number:grouping and number:scientific-number/@number:grouping = 'true'">
                <xsl:call-template name="AddGrouping">
                  <xsl:with-param name="value">
                    <xsl:value-of select="$value"/>
                  </xsl:with-param>
                  <xsl:with-param name="numDigits">
                    <xsl:choose>
                      <xsl:when test="number:scientific-number/@number:min-integer-digits">
                        <xsl:value-of
												  select="3 - number:scientific-number/@number:min-integer-digits"/>
                      </xsl:when>
                      <xsl:otherwise>2</xsl:otherwise>
                    </xsl:choose>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>

              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when
									  test="number:scientific-number/@number:display-factor and number:scientific-number/@number:display-factor!=''">
                    <xsl:call-template name="UseThousandDisplayFactor">
                      <xsl:with-param name="displayFactor">
                        <xsl:value-of select="number:scientific-number/@number:display-factor"/>
                      </xsl:with-param>
                      <xsl:with-param name="value">
                        <xsl:value-of select="$value"/>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$value"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:call-template name="AddMinExponentDigits">
            <xsl:with-param name="number">
              <xsl:value-of select="number:scientific-number/@number:min-exponent-digits"/>
            </xsl:with-param>
            <xsl:with-param name="scientificFormat" select="concat($scientificFormat,'.E+')"/>
          </xsl:call-template>
        </xsl:when>

        <xsl:otherwise>
          <xsl:choose>

            <!-- add grouping -->
            <xsl:when
						  test="number:number/@number:grouping and number:number/@number:grouping = 'true'">
              <xsl:call-template name="AddGrouping">
                <xsl:with-param name="value">
                  <xsl:value-of select="$value"/>
                </xsl:with-param>
                <xsl:with-param name="numDigits">
                  <xsl:choose>
                    <xsl:when test="number:number/@number:min-integer-digits">
                      <xsl:value-of select="3 - number:number/@number:min-integer-digits"/>
                    </xsl:when>
                    <xsl:otherwise>2</xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>
              <xsl:choose>
                <xsl:when
								  test="number:number/@number:display-factor and number:number/@number:display-factor!=''">
                  <xsl:call-template name="UseThousandDisplayFactor">
                    <xsl:with-param name="displayFactor">
                      <xsl:value-of select="number:number/@number:display-factor"/>
                    </xsl:with-param>
                    <xsl:with-param name="value">
                      <xsl:value-of select="$value"/>
                    </xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$value"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- add color to negative number formatting when necessary -->
    <xsl:variable name="finalValue">
      <xsl:choose>
        <xsl:when test="style:text-properties/@fo:color='#ff0000'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Red]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Red]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#00ffff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Cyan]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Cyan]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#0000ff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Blue]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Blue]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#00ff00'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Green]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Green]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ffff00'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Yellow]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Yellow]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ff00ff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[Magenta]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[Magenta]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="style:text-properties/@fo:color='#ffffff'">
          <xsl:choose>
            <xsl:when test="style:text-properties/following-sibling::number:text ='-'">
              <xsl:value-of select="concat('[White]-',$endValue)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('[White]',$endValue)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <xsl:otherwise>
          <xsl:value-of select="$endValue"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- add currency symbol -->
    <xsl:variable name="valueWithCurrency">
      <xsl:choose>
        <xsl:when
				  test="$currencySymbol and $currencySymbol!='' and number:number/following-sibling::number:currency-symbol">

          <!-- add space before currency symbol -->
          <xsl:variable name="currencyFormat">
            <xsl:choose>
              <xsl:when test="number:number/following-sibling::number:text = ' '">
                <xsl:value-of select="concat('\ ',$currencySymbol)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$currencySymbol"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:value-of select="concat($finalValue,$currencyFormat)"/>
        </xsl:when>
        <xsl:when
				  test="$currencySymbol and $currencySymbol!='' and number:number/preceding-sibling::number:currency-symbol">

          <!-- add space after currency symbol -->
          <xsl:variable name="currencyFormat2">
            <xsl:choose>
              <xsl:when test="number:number/preceding-sibling::number:text = ' '">
                <xsl:value-of select="concat($currencySymbol,'\ ')"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$currencySymbol"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="concat($currencyFormat2,$finalValue)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$finalValue"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="startText">
      <xsl:choose>
        <xsl:when
				  test="number:text[not(preceding-sibling::node())] != ' ' and number:text[not(preceding-sibling::node())] != '.'">
          <xsl:value-of select="number:text[not(preceding-sibling::node())]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="endText">
      <xsl:for-each select ="key('number',$styleToBeUsed)//number:text">
        <xsl:value-of select ="."/>
      </xsl:for-each>
    </xsl:variable>

    <!-- handle text in number format -->
    <xsl:choose>
      <xsl:when test="$startText != '' and $endText != '' ">
        <xsl:value-of
				  select="concat('&quot;',$startText,'&quot;',$valueWithCurrency,'&quot;',$endText,'&quot;')"
        />
      </xsl:when>
      <xsl:when test="$startText != '' ">
        <xsl:value-of select="concat('&quot;',$startText,'&quot;',$valueWithCurrency)"/>
      </xsl:when>
      <xsl:when test="$endText != '' ">
        <xsl:value-of select="concat($valueWithCurrency,'&quot;',$endText,'&quot;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$valueWithCurrency"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--code added by sonata for fraction number format-->
  <xsl:template match="number:number-style" mode="ChartnumFormat">
    <xsl:choose>

      <xsl:when test="number:number/@number:min-integer-digits=5">
        <c:numFmt>
          <xsl:attribute name="formatCode">
            <xsl:value-of select="'00000'"/>
          </xsl:attribute>
        </c:numFmt>
      </xsl:when>
      <xsl:otherwise>
        <c:numFmt>
          <xsl:attribute name="formatCode">
            <xsl:call-template name="GetFormatCode"/>
          </xsl:attribute>
        </c:numFmt>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
