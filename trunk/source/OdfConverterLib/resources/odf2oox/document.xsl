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
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/3/main"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="office text table fo style draw xlink v svg"
  xmlns:w10="urn:schemas-microsoft-com:office:word">

  <xsl:import href="tables.xsl"/>

  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="text:p"/>
  <xsl:preserve-space elements="text:span"/>

  <xsl:key name="annotations" match="//office:annotation" use="''"/>
  <xsl:key name="automatic-styles" match="office:automatic-styles/style:style" use="@style:name"/>
  <xsl:key name="hyperlinks" match="text:a" use="''"/>
  <xsl:key name="headers" match="text:h" use="''"/>
  <xsl:key name="images" match="draw:frame[not(./draw:object-ole) and ./draw:image/@xlink:href]"
    use="''"/>
  <xsl:key name="ole-objects" match="draw:frame[./draw:object-ole] " use="''"/>
  <xsl:key name="master-pages" match="style:master-page" use="@style:name"/>
  <xsl:key name="page-layouts" match="style:page-layout" use="@style:name"/>
  <xsl:key name="master-based-styles" match="style:style[@style:master-page-name]" use="@style:name"/>
  <xsl:key name="sections" match="style:style[@style:family='section']" use="@style:name"/>


  <!-- COMMENT: what is this variable for? -->
  <xsl:variable name="type">dxa</xsl:variable>

  <!-- main document -->
  <xsl:template name="document">
    <w:document>
      <!-- COMMENT: how are we sure this is the correct background? -->
      <!-- COMMENT: See if we cannot use a key -->
      <xsl:if
        test="document('styles.xml')//style:page-layout[@style:name=//office:master-styles/style:master-page/@style:page-layout-name]/style:page-layout-properties/@fo:background-color">
        <w:background>
          <xsl:attribute name="w:color">
            <xsl:value-of
              select="translate(substring-after(document('styles.xml')//style:page-layout[@style:name=//office:master-styles/style:master-page/@style:page-layout-name]/style:page-layout-properties/@fo:background-color,'#'),'f','F')"
            />
          </xsl:attribute>
        </w:background>
      </xsl:if>
      <xsl:apply-templates select="document('content.xml')/office:document-content"/>
    </w:document>
  </xsl:template>

  <!-- document body -->
  <xsl:template match="office:body">
    <w:body>
      <xsl:apply-templates/>
      <w:sectPr>
        <!-- Header/Footer configuration -->
        <xsl:call-template name="HeaderFooter"/>
        <!-- Footnotes and endnotes configuration -->
        <xsl:apply-templates
          select="document('styles.xml')/office:document-styles/office:styles/text:notes-configuration[@text:note-class='footnote']"
          mode="note"/>
        <xsl:apply-templates
          select="document('styles.xml')/office:document-styles/office:styles/text:notes-configuration[@text:note-class='endnote']"
          mode="note"/>

        <!-- Page layout properties -->
        <!--- all the paragraphs, headings or tables tied to a master style -->
        <xsl:variable name="masterPages"
          select="descendant::text:p[key('master-based-styles', @text:style-name)] | descendant::text:h[key('master-based-styles', @text:style-name)] | descendant::table:table[key('master-based-styles', @table:style-name)]"/>
        <!-- the last one -->
        <xsl:variable name="lastMasterPage" select="$masterPages[last()]"/>
        <!-- the master page name it is related to -->
        <xsl:variable name="masterPageName"
          select="key('master-based-styles', $lastMasterPage/@text:style-name | $lastMasterPage/@table:style-name)[1]/@style:master-page-name"/>

        <!-- 
          Continuous section. Looking up for a text:section 
          If there's no master-page used after the last text:section, then the sectPr is continuous.
        -->
        <xsl:variable name="ls" select="descendant::text:section[last()]"/>
        <xsl:variable name="lastMP"
          select="$ls/following::text:p[key('master-based-styles', @text:style-name)] | $ls/following::text:h[key('master-based-styles', @text:style-name)] | $ls/following::text:table[key('master-based-styles', @table:style-name)]"/>
        <xsl:if test="$ls and not($lastMP)">
          <w:type w:val="continuous"/>
        </xsl:if>
        <xsl:for-each select="document('styles.xml')">
          <xsl:choose>
            <!-- if we use a master-page based style -->
            <xsl:when test="$masterPageName">
              <!-- get the associated page layout -->
              <xsl:variable name="pageLayoutName"
                select="key('master-pages', $masterPageName)/@style:page-layout-name"/>
              <!-- apply the layout properties -->
              <xsl:apply-templates
                select="key('page-layouts', $pageLayoutName)/style:page-layout-properties"
                mode="master-page"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- use default master page -->
              <xsl:apply-templates
                select="key('page-layouts', /office:document-styles/office:master-styles/style:master-page[1]/@style:page-layout-name)/style:page-layout-properties"
                mode="master-page"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <!-- Shall the header and footer be different on the first page -->
        <xsl:call-template name="TitlePg"/>
      </w:sectPr>
    </w:body>
  </xsl:template>

  <!-- paragraphs and headings -->
  <xsl:template match="text:p | text:h">
    <xsl:param name="level" select="0"/>
    <xsl:message terminate="no">progress:text:p</xsl:message>
    <w:p>

      <w:pPr>
        <xsl:call-template name="InsertParagraphProperties">
          <xsl:with-param name="level" select="$level"/>
        </xsl:call-template>

        <!-- Section detection  : 3 cases -->

        <!-- 1 - Following neighbour's (ie paragraph, heading or table) master style  -->
        <xsl:variable name="followings"
          select="following::text:p | following::text:h | following::table:table"/>
        <xsl:variable name="masterPageStarts"
          select="boolean(key('master-based-styles', $followings[1]/@text:style-name | $followings[1]/@table:style-name))"/>

        <!-- 2 - Section starts. The following paragraph is contained in the following section -->
        <xsl:variable name="followingSection" select="following::text:section[1]"/>
        <!-- the following section is the same as the following neighbour's ancestor section -->
        <xsl:variable name="sectionStarts"
          select="$followingSection and (generate-id($followings[1]/ancestor::text:section) = generate-id($followingSection))"/>

        <!-- 3 - Section ends. We are in a section and the following paragraph isn't -->
        <xsl:variable name="previousSection" select="ancestor::text:section[1]"/>
        <!-- the following neighbour's ancestor section and the current section are different -->
        <xsl:variable name="sectionEnds"
          select="$previousSection and not(generate-id($followings[1]/ancestor::text:section) = generate-id($previousSection))"/>

        <!-- section creation -->
        <xsl:if
          test="($masterPageStarts = 'true' or $sectionStarts = 'true' or $sectionEnds = 'true') and not(ancestor::text:note-body) and not(ancestor::table:table)">
          <w:sectPr>

            <!-- 
              Continuous sections. Looking up for a text:section 
              If the first master style following the preceding section is the same as this paragraph's following master-style,
              then no other master style is used in-between.
            -->
            <xsl:variable name="ps" select="preceding::text:section[1]"/>
            <xsl:variable name="stylesAfterSection"
              select="$ps/following::text:p[key('master-based-styles', @text:style-name)] | $ps/following::text:h[key('master-based-styles', @text:style-name)] | $ps/following::text:table[key('master-based-styles', @table:style-name)]"/>
            <xsl:variable name="followingMasterStyle"
              select="$followings[key('master-based-styles', @text:style-name|@table:style-name)]"/>
            <xsl:variable name="continuous"
              select="generate-id($stylesAfterSection[1]) = generate-id($followingMasterStyle[1])"/>
            <xsl:choose>
              <xsl:when test="$sectionEnds = 'true' ">
                <xsl:apply-templates
                  select="key('sections', $previousSection/@text:style-name)[1]/style:section-properties/text:notes-configuration[@text:note-class='footnote']"
                  mode="note"/>
                <xsl:apply-templates
                  select="key('sections', $previousSection/@text:style-name)[1]/style:section-properties/text:notes-configuration[@text:note-class='endnote']"
                  mode="note"/>
                <w:type w:val="continuous"/>
              </xsl:when>
              <xsl:when test="$continuous">
                <w:type w:val="continuous"/>
              </xsl:when>
            </xsl:choose>

            <!-- Determine the master style that rules this section -->
            <xsl:variable name="currentMasterStyle"
              select="key('master-based-styles', @text:style-name)"/>

            <xsl:choose>
              <xsl:when test="boolean($currentMasterStyle)">
                <!-- current element style is tied to a master page -->
                <xsl:for-each select="document('styles.xml')">
                  <xsl:apply-templates
                    select="key('page-layouts', key('master-pages', $currentMasterStyle[1]/@style:master-page-name)/@style:page-layout-name)/style:page-layout-properties"
                    mode="master-page"/>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <!-- current style is not tied to a master page, find the preceding one -->
                <xsl:variable name="precedings"
                  select="preceding::text:p[key('master-based-styles', @text:style-name)] | preceding::text:h[key('master-based-styles', @text:style-name)] | preceding::table:table[key('master-based-styles', @table:style-name)]"/>
                <xsl:variable name="precedingMasterStyle"
                  select="key('master-based-styles', $precedings[last()]/@text:style-name | $precedings[last()]/@table:style-name)"/>
                <xsl:choose>
                  <xsl:when test="boolean($precedingMasterStyle)">
                    <xsl:for-each select="document('styles.xml')">
                      <xsl:apply-templates
                        select="key('page-layouts', key('master-pages', $precedingMasterStyle[1]/@style:master-page-name)/@style:page-layout-name)/style:page-layout-properties"
                        mode="master-page"/>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- otherwise, apply the default master style -->
                    <xsl:for-each select="document('styles.xml')">
                      <xsl:apply-templates
                        select="key('page-layouts', /office:document-styles/office:master-styles/style:master-page[1]/@style:page-layout-name)/style:page-layout-properties"
                        mode="master-page"/>
                    </xsl:for-each>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="$sectionEnds = 'true' ">
              <xsl:apply-templates
                select="key('sections', ancestor::text:section[1]/@text:style-name)/style:section-properties"
                mode="section"/>
            </xsl:if>
          </w:sectPr>
        </xsl:if>

        <!-- insert page break before table when required -->
        <xsl:call-template name="InsertPageBreakBefore"/>

      </w:pPr>
      <!-- TOC id (used for headings only) -->
      <xsl:variable name="tocId">
        <xsl:choose>
          <xsl:when test="self::text:h">
            <xsl:value-of select="number(count(preceding::text:h)+1)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="self::text:p">
              <xsl:value-of select="number(count(preceding::text:p[@text:style-name='Standard'])+1)"
              />
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:variable>
      <xsl:choose>
        <xsl:when test="self::text:h">
          <w:bookmarkStart w:id="{$tocId}" w:name="{concat('_Toc',$tocId)}"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="@text:style-name='Standard'">
            <w:bookmarkStart w:id="{$tocId}" w:name="{concat('_Toc',$tocId)}"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
      <!-- footnotes or endnotes: insert the mark in the first paragraph -->
      <xsl:if test="parent::text:note-body and position() = 1">
        <xsl:apply-templates select="../../text:note-citation" mode="note"/>
      </xsl:if>

      <xsl:choose>

        <!-- we are in table of contents -->
        <xsl:when test="parent::text:index-body">
          <xsl:call-template name="InsertTocEntry"/>
        </xsl:when>

        <!-- ignore draw:frame/draw:text-box if it's embedded in another draw:frame/draw:text-box becouse word doesn't support it -->
        <xsl:when test="self::node()[ancestor::draw:text-box and descendant::draw:text-box]"/>

        <xsl:otherwise>
          <xsl:apply-templates mode="paragraph"/>
        </xsl:otherwise>

      </xsl:choose>

      <!-- selfstanding image before paragraph-->
      <xsl:if
        test="name(preceding-sibling::*[1]) = 'draw:frame' and preceding-sibling::*[1]/draw:image">
        <xsl:apply-templates select="preceding-sibling::*[1]" mode="paragraph"/>
      </xsl:if>

      <!-- If there is a page-break-after in the paragraph style -->
      <xsl:if
        test="key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='page'">
        <w:r>
          <w:br w:type="page"/>
        </w:r>
      </xsl:if>

      <xsl:choose>
        <xsl:when test="self::text:h">
          <w:bookmarkEnd w:id="{$tocId}"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="@text:style-name='Standard'">
            <w:bookmarkEnd w:id="{$tocId}"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

    </w:p>
  </xsl:template>

  <!-- Inserts the paragraph properties -->
  <xsl:template name="InsertParagraphProperties">
    <xsl:param name="level"/>

    <!-- insert paragraph style -->
    <xsl:call-template name="InsertParagraphStyle">
      <xsl:with-param name="styleName">
        <xsl:choose>
          <xsl:when test="count(draw:frame) = 1 and count(child::text()) = 0">
            <xsl:value-of select="draw:frame/@draw:style-name"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@text:style-name"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>

    <!-- insert heading outline level -->
    <xsl:call-template name="InsertOutlineLevel">
      <xsl:with-param name="node" select="."/>
    </xsl:call-template>

    <!-- insert indentation -->
    <xsl:call-template name="InsertIndent">
      <xsl:with-param name="level" select="$level"/>
    </xsl:call-template>



    <!-- if we are in an annotation, we may have to insert annotation reference -->
    <xsl:call-template name="InsertAnnotationReference"/>

  </xsl:template>

  <!-- Inserts the style of a paragraph -->
  <xsl:template name="InsertParagraphStyle">
    <xsl:param name="styleName"/>
    <xsl:variable name="prefixedStyleName">
      <xsl:call-template name="GetPrefixedStyleName">
        <xsl:with-param name="styleName" select="$styleName"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$prefixedStyleName != ''">
      <w:pStyle w:val="{$prefixedStyleName}"/>
    </xsl:if>
  </xsl:template>

  <!-- Inserts the outline level of a heading if needed -->
  <xsl:template name="InsertOutlineLevel">
    <xsl:param name="node"/>
    <xsl:if test="$node[self::text:h]">
      <xsl:choose>
        <xsl:when test="not($node/@text:outline-level)">
          <w:outlineLvl w:val="0"/>
        </xsl:when>
        <xsl:when test="$node/@text:outline-level &lt;= 9">
          <!-- COMMENT: See if we cannot use a key -->
          <xsl:if
            test="document('styles.xml')//office:document-styles/office:styles/text:outline-style/text:outline-level-style/@style:num-format !=''">
            <w:numPr>
              <w:ilvl w:val="{$node/@text:outline-level - 1}"/>
              <w:numId w:val="1"/>
            </w:numPr>
          </xsl:if>
          <w:outlineLvl w:val="{$node/@text:outline-level}"/>
        </xsl:when>
        <xsl:otherwise>
          <w:outlineLvl w:val="9"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$node[child::text:toc-mark-start]">
      <w:outlineLvl w:val="{$node/text:toc-mark-start/@text:outline-level}"/>
    </xsl:if>
  </xsl:template>

  <!-- Inserts paragraph indentation -->
  <!-- COMMENT: please try to split this template into smaller ones -->
  <xsl:template name="InsertIndent">
    <xsl:param name="level" select="0"/>
    <xsl:variable name="styleName">
      <xsl:call-template name="GetStyleName"/>
    </xsl:variable>
    <xsl:variable name="parentStyleName"
      select="key('automatic-styles',$styleName)/@style:parent-style-name"/>
    <xsl:variable name="listStyleName"
      select="key('automatic-styles',$styleName)/@style:list-style-name"/>
    <xsl:variable name="paragraphMargin">
      <xsl:choose>
        <xsl:when
          test="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:margin-left">
          <xsl:call-template name="twips-measure">
            <xsl:with-param name="length"
              select="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:margin-left"
            />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="document('styles.xml')">
            <xsl:choose>
              <xsl:when
                test="key('styles',$parentStyleName)/style:paragraph-properties/@fo:margin-left">
                <xsl:call-template name="twips-measure">
                  <xsl:with-param name="length"
                    select="key('styles',$parentStyleName)/style:paragraph-properties/@fo:margin-left"
                  />
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="ancestor-or-self::text:list">
        <xsl:variable name="minLabelWidthTwip">
          <xsl:choose>
            <xsl:when
              test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-width">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-width"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:when
              test="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-width">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-width"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="spaceBeforeTwip">
          <xsl:choose>
            <xsl:when
              test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:space-before">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:space-before"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:when
              test="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:space-before">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:space-before"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="minLabelDistanceTwip">
          <xsl:choose>
            <xsl:when
              test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-distance">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-distance"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:when
              test="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-distance">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('styles.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-distance"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$listStyleName=''">
              <xsl:call-template name="twips-measure">
                <xsl:with-param name="length"
                  select="document('styles.xml')//text:outline-style/*[@text:level = $level+1]/style:list-level-properties/@text:min-label-distance"
                />
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>
          <xsl:when
            test="not(ancestor-or-self::text:list-header) and (self::text:list-item or not(preceding-sibling::node()))">
            <xsl:if test="$paragraphMargin != 0">
              <xsl:variable name="textIndent">
                <xsl:choose>
                  <xsl:when
                    test="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:text-indent">
                    <xsl:call-template name="twips-measure">
                      <xsl:with-param name="length"
                        select="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:text-indent"
                      />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:for-each select="document('styles.xml')">
                      <xsl:choose>
                        <xsl:when
                          test="key('styles',$parentStyleName)/style:paragraph-properties/@fo:text-indent">
                          <xsl:call-template name="twips-measure">
                            <xsl:with-param name="length"
                              select="key('styles',$parentStyleName)/style:paragraph-properties/@fo:text-indent"
                            />
                          </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:choose>
                <xsl:when test="$textIndent != 0">
                  <w:tabs>
                    <w:tab>
                      <xsl:attribute name="w:val">clear</xsl:attribute>
                      <xsl:attribute name="w:pos">
                        <xsl:choose>
                          <xsl:when
                            test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-style-number/@text:display-levels">
                            <xsl:value-of select="$spaceBeforeTwip + $minLabelDistanceTwip"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:choose>
                              <xsl:when test="$minLabelWidthTwip &lt; $minLabelDistanceTwip">
                                <xsl:value-of
                                  select="$spaceBeforeTwip + $minLabelWidthTwip + $minLabelDistanceTwip"
                                />
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="$spaceBeforeTwip + $minLabelWidthTwip"/>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:attribute>
                    </w:tab>
                    <w:tab>
                      <xsl:attribute name="w:val">num</xsl:attribute>
                      <xsl:attribute name="w:pos">
                        <xsl:value-of
                          select="$minLabelDistanceTwip + $paragraphMargin + $textIndent"/>
                      </xsl:attribute>
                    </w:tab>
                  </w:tabs>
                  <w:ind>
                    <xsl:attribute name="w:left">
                      <xsl:value-of select="$paragraphMargin + $spaceBeforeTwip"/>
                    </xsl:attribute>
                    <xsl:if
                      test="not(ancestor-or-self::text:list-header) and (self::text:list-item or not(preceding-sibling::node()))">
                      <xsl:attribute name="w:firstLine">
                        <xsl:value-of select="$textIndent"/>
                      </xsl:attribute>
                    </xsl:if>
                  </w:ind>
                </xsl:when>
                <xsl:otherwise>
                  <w:tabs>
                    <w:tab>
                      <xsl:attribute name="w:val">clear</xsl:attribute>
                      <xsl:attribute name="w:pos">
                        <xsl:choose>
                          <xsl:when
                            test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-style-number/@text:display-levels">
                            <xsl:value-of select="$spaceBeforeTwip + $minLabelDistanceTwip"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:choose>
                              <xsl:when test="$minLabelWidthTwip &lt; $minLabelDistanceTwip">
                                <xsl:value-of
                                  select="$spaceBeforeTwip + $minLabelWidthTwip + $minLabelDistanceTwip"
                                />
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="$spaceBeforeTwip + $minLabelWidthTwip"/>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:attribute>
                    </w:tab>
                    <w:tab>
                      <xsl:attribute name="w:val">num</xsl:attribute>
                      <xsl:attribute name="w:pos">
                        <xsl:choose>
                          <xsl:when
                            test="document('content.xml')//text:list-style[@style:name = $listStyleName]/*[@text:level = $level+1]/style:list-level-style-number/@text:display-levels">
                            <xsl:value-of
                              select="$paragraphMargin + $spaceBeforeTwip + $minLabelDistanceTwip"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:choose>
                              <xsl:when test="$minLabelWidthTwip &lt; $minLabelDistanceTwip">
                                <xsl:value-of
                                  select="$paragraphMargin + $spaceBeforeTwip + $minLabelWidthTwip + $minLabelDistanceTwip"
                                />
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of
                                  select="$paragraphMargin + $spaceBeforeTwip + $minLabelWidthTwip"
                                />
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:attribute>
                    </w:tab>
                  </w:tabs>
                  <w:ind>
                    <xsl:attribute name="w:left">
                      <xsl:value-of
                        select="$paragraphMargin  + $spaceBeforeTwip + $minLabelWidthTwip"/>
                    </xsl:attribute>
                    <xsl:if
                      test="not(ancestor-or-self::text:list-header) and (self::text:list-item or not(preceding-sibling::node()))">
                      <xsl:attribute name="w:hanging">
                        <xsl:value-of select="$minLabelWidthTwip"/>
                      </xsl:attribute>
                    </xsl:if>
                  </w:ind>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <w:ind>
              <xsl:attribute name="w:left">
                <xsl:value-of select="$paragraphMargin  + $spaceBeforeTwip + $minLabelWidthTwip"/>
              </xsl:attribute>
              <xsl:if
                test="not(ancestor-or-self::text:list-header) and (self::text:list-item or not(preceding-sibling::node()))">
                <xsl:attribute name="w:hanging">
                  <xsl:value-of select="$minLabelWidthTwip"/>
                </xsl:attribute>
              </xsl:if>
            </w:ind>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$paragraphMargin != 0">
          <w:ind>
            <xsl:attribute name="w:left">
              <xsl:value-of select="$paragraphMargin"/>
            </xsl:attribute>
          </w:ind>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Computes the style name to be used be InsertIndent template -->
  <!-- COMMENT: verify that all cases are matched (I just added self::text:h
       Why not simply match text:list-item and if not everything else? -->
  <!-- COMMENT: see if we cannot reuse this template to factorise all the Set*Styles -->
  <xsl:template name="GetStyleName">
    <xsl:if test="self::text:list-item">
      <xsl:value-of select="*[1][self::text:p]/@text:style-name"/>
    </xsl:if>
    <xsl:if
      test="parent::text:list-header|self::text:p|self::text:h|self::text:list-level-style-number">
      <xsl:value-of select="@text:style-name"/>
    </xsl:if>
    <xsl:if test="ancestor::text:span">
      <xsl:value-of select="ancestor::text:span[1]/@text:style-name"/>
    </xsl:if>
  </xsl:template>

  <!-- Inserts a table of content entry -->
  <xsl:template name="InsertTocEntry">
    <xsl:variable name="num">
      <xsl:choose>
        <xsl:when test="ancestor::text:table-index">
          <xsl:value-of select="count(preceding-sibling::text:p)+count( key('headers',''))+1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:number/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="ile">
      <xsl:number/>
    </xsl:variable>

    <xsl:if test="$ile = 1">
      <w:r>
        <w:fldChar w:fldCharType="begin"/>
      </w:r>
      <w:r>
        <xsl:choose>
          <xsl:when test="ancestor::text:table-of-content">
            <w:instrText xml:space="preserve"> TOC \o <xsl:if test="not(parent::text:index-body/preceding-sibling::text:table-of-content-source[@text:use-index-marks = 'false'])">\u </xsl:if>"1-<xsl:choose><xsl:when test="parent::text:index-body/preceding-sibling::text:table-of-content-source/@text:outline-level=10">9</xsl:when><xsl:otherwise><xsl:value-of select="parent::text:index-body/preceding-sibling::text:table-of-content-source/@text:outline-level"/></xsl:otherwise></xsl:choose>"<xsl:if test="text:a"> \h </xsl:if></w:instrText>
          </xsl:when>
          <xsl:when test="ancestor::text:illustration-index">
            <w:instrText xml:space="preserve"> TOC  \c "<xsl:value-of select="parent::text:index-body/preceding-sibling::text:illustration-index-source/@text:caption-sequence-name"/>" </w:instrText>
          </xsl:when>
          <xsl:when test="ancestor::text:alphabetical-index">
            <w:instrText xml:space="preserve"> INDEX \e "" \c "<xsl:choose><xsl:when test="key('automatic-styles',ancestor::text:alphabetical-index/@text:style-name)/style:section-properties/style:columns/@fo:column-count=0">1</xsl:when><xsl:otherwise><xsl:value-of select="key('automatic-styles',ancestor::text:alphabetical-index/@text:style-name)/style:section-properties/style:columns/@fo:column-count"/></xsl:otherwise></xsl:choose>" \z "1045" </w:instrText>
          </xsl:when>
          <xsl:otherwise>
            <w:instrText xml:space="preserve"> TOC  \c "<xsl:value-of select="parent::text:index-body/preceding-sibling::text:table-index-source/@text:caption-sequence-name"/>" </w:instrText>
          </xsl:otherwise>
        </xsl:choose>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="separate"/>
      </w:r>
    </xsl:if>
    <xsl:choose>
      <!-- COMMENT: duplicate with text:a matching? -->
      <xsl:when test="text:a">
        <w:hyperlink w:history="1">
          <xsl:attribute name="w:anchor">
            <xsl:value-of select="concat('_Toc',$num)"/>
          </xsl:attribute>
          <xsl:call-template name="tableContent">
            <xsl:with-param name="num" select="$num"/>
            <xsl:with-param name="test">1</xsl:with-param>
          </xsl:call-template>
        </w:hyperlink>
      </xsl:when>
      <xsl:when test="preceding::text:p">
        <xsl:message>JESTEM</xsl:message>
        <w:hyperlink w:history="1">
          <xsl:attribute name="w:anchor">
            <xsl:value-of select="concat('_Toc',$num)"/>
          </xsl:attribute>
          <xsl:call-template name="tableContent">
            <xsl:with-param name="num" select="$num"/>
            <xsl:with-param name="test">0</xsl:with-param>
          </xsl:call-template>
        </w:hyperlink>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="tableContent">
          <xsl:with-param name="num" select="$num"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts a page break before if needed -->
  <xsl:template name="InsertPageBreakBefore">
    <!-- in the first paragraph of a table -->
    <xsl:if test="ancestor-or-self::table:table">
      <xsl:if
        test="parent::node()[name()='table:table-cell' and not(preceding-sibling::node())]
        and ancestor::node()[name()='table:table-row' and (preceding-sibling::node()[1][name()='table:table-column' or name()='table:table-columns'] or not(preceding-sibling::node()))]
        and (
        key('automatic-styles',ancestor::table:table/@table:style-name)/style:table-properties/@fo:break-before = 'page'
        or key('automatic-styles',ancestor::table:table/@table:style-name)/@style:master-page-name)">
        <w:pageBreakBefore/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Inserts an annotation reference if needed -->
  <xsl:template name="InsertAnnotationReference">
    <xsl:if test="ancestor::office:annotation and position() = 1">
      <w:r>
        <w:annotationRef/>
      </w:r>
    </xsl:if>
  </xsl:template>

  <!-- note marks -->
  <xsl:template match="text:note-citation" mode="note">
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{concat(../@text:note-class, 'Reference')}"/>
      </w:rPr>
      <xsl:choose>
        <xsl:when test="../text:note-citation/@text:label">
          <w:t>
            <xsl:value-of select="../text:note-citation"/>
          </w:t>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="../@text:note-class = 'footnote'">
              <w:footnoteRef/>
            </xsl:when>
            <xsl:when test="../@text:note-class = 'endnote' ">
              <w:endnoteRef/>
            </xsl:when>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </w:r>
    <!-- add an extra tab -->
    <w:r>
      <w:tab/>
    </w:r>
  </xsl:template>

  <!-- annotations -->
  <xsl:template match="office:annotation" mode="paragraph">
    <xsl:variable name="id">
      <xsl:call-template name="GenerateId">
        <xsl:with-param name="node" select="."/>
        <xsl:with-param name="nodetype" select="'annotation'"/>
      </xsl:call-template>
    </xsl:variable>
    <w:r>
      <xsl:call-template name="InsertRunProperties"/>
      <w:commentReference>
        <xsl:attribute name="w:id">
          <xsl:value-of select="$id"/>
        </xsl:attribute>
      </w:commentReference>
    </w:r>
  </xsl:template>

  <!-- links -->
  <xsl:template match="text:a" mode="paragraph">
    <xsl:choose>
      <!-- COMMENT: duplicate with TOC handling within paragraphs? -->
      <xsl:when test="ancestor::text:index-body">
        <xsl:variable name="num" select="count(parent::*/preceding-sibling::*)"/>
        <w:hyperlink w:history="1">
          <xsl:attribute name="w:anchor">
            <xsl:value-of select="concat('_Toc',$num)"/>
          </xsl:attribute>
          <xsl:apply-templates mode="paragraph"/>
        </w:hyperlink>
      </xsl:when>
      <xsl:otherwise>
        <w:hyperlink r:id="{generate-id()}">
          <xsl:apply-templates mode="paragraph"/>
        </w:hyperlink>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- computes text-box margin -->
  <xsl:template name="ComputeMarginX">
    <xsl:param name="parent"/>
    <xsl:choose>
      <xsl:when test="$parent">
        <xsl:variable name="recursive_result">
          <xsl:call-template name="point-measure">
            <xsl:with-param name="length">
              <xsl:call-template name="ComputeMarginX">
                <xsl:with-param name="parent" select="$parent[position()>1]"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="svgx">
          <xsl:choose>
            <xsl:when test="$parent[1]/@svg:x">
              <xsl:call-template name="point-measure">
                <xsl:with-param name="length">
                  <xsl:value-of select="$parent[1]/@svg:x"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>

        </xsl:variable>
        <xsl:value-of select="$svgx+$recursive_result"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- computes text-box margin -->
  <xsl:template name="ComputeMarginY">
    <xsl:param name="parent"/>
    <xsl:choose>
      <xsl:when test="$parent">
        <xsl:variable name="recursive_result">
          <xsl:call-template name="point-measure">
            <xsl:with-param name="length">
              <xsl:call-template name="ComputeMarginY">
                <xsl:with-param name="parent" select="$parent[position()>1]"/>
              </xsl:call-template>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="svgy">
          <xsl:choose>
            <xsl:when test="$parent[1]/@svg:y">
              <xsl:call-template name="point-measure">
                <xsl:with-param name="length">
                  <xsl:value-of select="$parent[1]/@svg:y"/>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$svgy+$recursive_result"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="0"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- text boxes -->
  <xsl:template match="draw:text-box" mode="paragraph">
    <w:r>
      <w:rPr>
        <xsl:call-template name="InsertTextBoxStyle"/>
      </w:rPr>
      <w:pict>
        <v:shapetype/>
        <v:shape type="#_x0000_t202">

          <xsl:variable name="styleGraphicProperties"
            select="key('automatic-styles', parent::draw:frame/@draw:style-name)/style:graphic-properties"/>

          <xsl:call-template name="InsertShapeProperties">
            <xsl:with-param name="styleGraphicProperties" select="$styleGraphicProperties"/>
          </xsl:call-template>

          <xsl:call-template name="InsertTextBox">
            <xsl:with-param name="styleGraphicProperties" select="$styleGraphicProperties"/>
          </xsl:call-template>

        </v:shape>
      </w:pict>
    </w:r>
  </xsl:template>

  <!--converts oo frame style properties to shape properties for text-box-->
  <xsl:template name="InsertShapeProperties">
    <xsl:param name="styleGraphicProperties"/>

    <xsl:attribute name="style">

      <!-- absolute positioning for text-box -->
      <xsl:variable name="frameWrap" select="$styleGraphicProperties/@style:wrap"/>
      <xsl:if
        test="(not($frameWrap) or $frameWrap != 'none') and not(parent::draw:frame/@text:anchor-type = 'as-char') ">
        <xsl:value-of select="'position:absolute;'"/>
      </xsl:if>

      <!--  text-box width and height-->
      <xsl:variable name="frameW">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length"
            select="parent::draw:frame/@svg:width|parent::draw:frame/@fo:min-width"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="frameH">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length" select="@fo:min-height|parent::draw:frame/@svg:height"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="relWidth"
        select="substring-before(parent::draw:frame/@style:rel-width,'%')"/>
      <xsl:variable name="relHeight"
        select="substring-before(parent::draw:frame/@style:rel-height,'%')"/>

      <xsl:value-of select="concat('width:',$frameW,'pt;')"/>
      <xsl:value-of select="concat('height:',$frameH,'pt;')"/>

      <xsl:if test="$relWidth">
        <xsl:value-of select="concat('mso-width-percent:',$relWidth,'0;')"/>
      </xsl:if>
      <xsl:if test="$relHeight">
        <xsl:value-of select="concat('mso-height-percent:',$relHeight,'0;')"/>
      </xsl:if>

      <!--z-index that we need to convert properly openoffice wrap-throught property -->
      <xsl:variable name="zIndex">
        <xsl:choose>
          <xsl:when
            test="$frameWrap='run-through' 
            and $styleGraphicProperties/@style:run-through='background'"
            >-251658240</xsl:when>
          <xsl:when
            test="$frameWrap='run-through' 
            and not($styleGraphicProperties/@style:run-through)"
            >251658240</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="parent::draw:frame/@draw:z-index"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:value-of select="concat('z-index:', $zIndex, ';')"/>

      <!-- text-box coordinates -->
      <xsl:variable name="posL">
        <xsl:if test="parent::draw:frame/@svg:x">
          <xsl:variable name="leftM">
            <xsl:call-template name="ComputeMarginX">
              <xsl:with-param name="parent" select="ancestor::draw:frame"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$leftM"/>
        </xsl:if>
      </xsl:variable>
      <xsl:variable name="posT">
        <xsl:if test="parent::draw:frame/@svg:y">
          <xsl:variable name="topM">
            <xsl:call-template name="ComputeMarginY">
              <xsl:with-param name="parent" select="ancestor::draw:frame"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:value-of select="$topM"/>
        </xsl:if>
      </xsl:variable>

      <xsl:if test="parent::draw:frame/@svg:x">
        <xsl:value-of select="concat('margin-left:',$posL,'pt;')"/>
      </xsl:if>
      <xsl:if test="parent::draw:frame/@svg:y">
        <xsl:value-of select="concat('margin-top:',$posT,'pt;')"/>
      </xsl:if>

      <!-- text-box relative position -->
      <xsl:if test="parent::draw:frame/@text:anchor-type = 'page'">
        <xsl:value-of
          select="concat('mso-position-horizontal-relative:',parent::draw:frame/@text:anchor-type,';')"/>
        <xsl:value-of
          select="concat('mso-position-vertical-relative:',parent::draw:frame/@text:anchor-type,';')"
        />
      </xsl:if>

      <!--horizontal position-->
      <!-- The same style defined in styles.xsl  TODO manage horizontal-rel-->
      <xsl:if test="$styleGraphicProperties/@style:horizontal-pos">
        <xsl:choose>
          <xsl:when test="$styleGraphicProperties/@style:horizontal-pos = 'center'">
            <xsl:value-of select="concat('mso-position-horizontal:', 'center',';')"/>
          </xsl:when>
          <xsl:when test="$styleGraphicProperties/@style:horizontal-pos='left'">
            <xsl:value-of select="concat('mso-position-horizontal:', 'left',';')"/>
          </xsl:when>
          <xsl:when test="$styleGraphicProperties/@style:horizontal-pos='right'">
            <xsl:value-of select="concat('mso-position-horizontal:', 'right',';')"/>
          </xsl:when>
          <!-- <xsl:otherwise><xsl:value-of select="concat('mso-position-horizontal:', 'center',';')"/></xsl:otherwise> -->
        </xsl:choose>
      </xsl:if>

      <!--text-box spacing/margins -->
      <xsl:variable name="marginL">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length" select="$styleGraphicProperties/@fo:margin-left"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="marginT">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length" select="$styleGraphicProperties/@fo:margin-top"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="marginR">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length" select="$styleGraphicProperties/@fo:margin-right"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:variable name="marginB">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length" select="$styleGraphicProperties/@fo:margin-bottom"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:if test="parent::draw:frame/@fo:min-width">
        <xsl:value-of select="'mso-wrap-style:none;'"/>
      </xsl:if>
      <xsl:if test="$styleGraphicProperties/@fo:margin-left">
        <xsl:value-of select="concat('mso-wrap-distance-left:', $marginL,'pt;')"/>
      </xsl:if>
      <xsl:if test="$styleGraphicProperties/@fo:margin-top">
        <xsl:value-of select="concat('mso-wrap-distance-top:', $marginT,'pt;')"/>
      </xsl:if>
      <xsl:if test="$styleGraphicProperties/@fo:margin-right">
        <xsl:value-of select="concat('mso-wrap-distance-right:', $marginR,'pt;')"/>
      </xsl:if>
      <xsl:if test="$styleGraphicProperties/@fo:margin-bottom">
        <xsl:value-of select="concat('mso-wrap-distance-bottom:', $marginB,'pt;')"/>
      </xsl:if>
    </xsl:attribute>

    <!--fill color-->
    <xsl:if test="$styleGraphicProperties/@fo:background-color">
      <xsl:attribute name="fillcolor">
        <xsl:value-of select="$styleGraphicProperties/@fo:background-color"/>
      </xsl:attribute>
    </xsl:if>


    <!--borders-->
    <xsl:if test="$styleGraphicProperties/@fo:border">
      <xsl:variable name="strokeColor"
        select="substring-after($styleGraphicProperties/@fo:border,'#')"/>

      <xsl:variable name="strokeWeight">
        <xsl:call-template name="point-measure">
          <xsl:with-param name="length"
            select="substring-before($styleGraphicProperties/@fo:border,' ')"/>
        </xsl:call-template>
      </xsl:variable>

      <xsl:if test="$strokeColor != '' ">
        <xsl:attribute name="strokecolor">
          <xsl:value-of select="concat('#', $strokeColor)"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:if test="$strokeWeight != '' ">
        <xsl:attribute name="strokeweight">
          <xsl:value-of select="concat($strokeWeight,'pt')"/>
        </xsl:attribute>
      </xsl:if>

    </xsl:if>

    <xsl:if
      test="substring-before(substring-after($styleGraphicProperties/@fo:border,' ' ),' ' ) != 'solid' ">
      <v:stroke>
        <xsl:attribute name="linestyle">
          <xsl:choose>
            <xsl:when test="$styleGraphicProperties/@style:border-line-width">

              <xsl:variable name="innerLineWidth">
                <xsl:call-template name="point-measure">
                  <xsl:with-param name="length"
                    select="substring-before($styleGraphicProperties/@style:border-line-width,' ' )"
                  />
                </xsl:call-template>
              </xsl:variable>

              <xsl:variable name="outerLineWidth">
                <xsl:call-template name="point-measure">
                  <xsl:with-param name="length"
                    select="substring-after(substring-after($styleGraphicProperties/@style:border-line-width,' ' ),' ' )"
                  />
                </xsl:call-template>
              </xsl:variable>

              <xsl:if test="$innerLineWidth = $outerLineWidth">thinThin</xsl:if>
              <xsl:if test="$innerLineWidth > $outerLineWidth">thinThick</xsl:if>
              <xsl:if test="$outerLineWidth > $innerLineWidth  ">thickThin</xsl:if>

            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </v:stroke>

    </xsl:if>

    <!--fill  transparency-->
    <xsl:variable name="opacity"
      select="100 - substring-before($styleGraphicProperties/@style:background-transparency,'%')"/>

    <xsl:if test="$styleGraphicProperties/@style:background-transparency">
      <v:fill>
        <xsl:attribute name="opacity">
          <xsl:value-of select="concat($opacity,'%')"/>
        </xsl:attribute>
      </v:fill>
    </xsl:if>

  </xsl:template>

  <!--inserts text-box into shape element -->
  <xsl:template name="InsertTextBox">
    <xsl:param name="styleGraphicProperties"/>

    <v:textbox>
      <xsl:attribute name="style">
        <xsl:if test="@fo:min-height">
          <xsl:value-of select="'mso-fit-shape-to-text:t'"/>
        </xsl:if>
      </xsl:attribute>

      <xsl:variable name="parentStyleName">
        <xsl:value-of select="$styleGraphicProperties/@style:parent-style-name"/>
      </xsl:variable>
      <xsl:variable name="parentStyleGraphicProperties"
        select="document('styles.xml')//office:document-styles/office:styles/style:style[@style:name = $parentStyleName]/style:graphic-properties"/>

      <xsl:call-template name="InsertTextBoxInset">
        <xsl:with-param name="styleGraphicProperties" select="$styleGraphicProperties"/>
        <xsl:with-param name="parentStyleGraphicProperties" select="$parentStyleGraphicProperties"/>
      </xsl:call-template>

      <w:txbxContent>
        <xsl:for-each select="child::node()">
          <xsl:apply-templates select="."/>
        </xsl:for-each>
      </w:txbxContent>

      <xsl:variable name="frameWrap" select="$styleGraphicProperties/@style:wrap"/>

      <!--frame wrap-->
      <xsl:choose>
        <xsl:when test="parent::draw:frame/@text:anchor-type = 'as-char' or $frameWrap = 'none' ">
          <w10:wrap type="none"/>
          <w10:anchorlock/>
        </xsl:when>
        <xsl:when test="$frameWrap = 'left' ">
          <w10:wrap type="square" side="left"/>
        </xsl:when>
        <xsl:when test="$frameWrap = 'right' ">
          <w10:wrap type="square" side="right"/>
        </xsl:when>
        <xsl:when test="not($frameWrap)">
          <w10:wrap type="square"/>
        </xsl:when>
        <xsl:when test="$frameWrap = 'parallel' ">
          <w10:wrap type="square"/>
        </xsl:when>
        <xsl:when test="$frameWrap = 'dynamic' ">
          <w10:wrap type="square" side="largest"/>
        </xsl:when>
      </xsl:choose>

    </v:textbox>
  </xsl:template>

  <!--converts oo frame padding into inset for text-box -->
  <xsl:template name="InsertTextBoxInset">
    <xsl:param name="styleGraphicProperties"/>
    <xsl:param name="parentStyleGraphicProperties"/>

    <xsl:attribute name="inset">
      <xsl:choose>
        <xsl:when
          test="$styleGraphicProperties/@fo:padding or $styleGraphicProperties/@fo:padding-top">
          <xsl:call-template name="CalculateTextBoxPadding">
            <xsl:with-param name="graphicProperties" select="$styleGraphicProperties"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when
          test="$parentStyleGraphicProperties/@fo:padding or $parentStyleGraphicProperties/@fo:padding-top">
          <xsl:call-template name="CalculateTextBoxPadding">
            <xsl:with-param name="graphicProperties" select="$parentStyleGraphicProperties"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="CalculateTextBoxPadding"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>


  <!--calculates textbox inset attribute  -->
  <xsl:template name="CalculateTextBoxPadding">
    <xsl:param name="graphicProperties"/>

    <xsl:choose>
      <xsl:when test="not($graphicProperties)">0mm,0mm,0mm,0mm</xsl:when>
      <xsl:when test="$graphicProperties/@fo:padding">
        <xsl:variable name="padding">
          <xsl:call-template name="milimeter-measure">
            <xsl:with-param name="length" select="$graphicProperties/@fo:padding"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat($padding,'mm,',$padding,'mm,',$padding,'mm,',$padding,'mm')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="padding-top">
          <xsl:if test="$graphicProperties/@fo:padding-top">
            <xsl:call-template name="milimeter-measure">
              <xsl:with-param name="length"
                select="key('automatic-styles', parent::draw:frame/@draw:style-name)/style:graphic-properties/@fo:padding-top"
              />
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="padding-right">
          <xsl:if test="$graphicProperties/@fo:padding-right">
            <xsl:call-template name="milimeter-measure">
              <xsl:with-param name="length" select="$graphicProperties/@fo:padding-right"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="padding-bottom">
          <xsl:if test="$graphicProperties/@fo:padding-bottom">
            <xsl:call-template name="milimeter-measure">
              <xsl:with-param name="length" select="$graphicProperties/@fo:padding-bottom"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="padding-left">
          <xsl:if test="$graphicProperties/@fo:padding-left">
            <xsl:call-template name="milimeter-measure">
              <xsl:with-param name="length" select="$graphicProperties/@fo:padding-left"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:variable>
        <xsl:if test="$graphicProperties/@fo:padding-top">
          <xsl:value-of
            select="concat($padding-left,'mm,',$padding-top,'mm,',$padding-right,'mm,',$padding-bottom,'mm')"
          />
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the style of a text box -->
  <xsl:template name="InsertTextBoxStyle">
    <xsl:variable name="prefixedStyleName">
      <xsl:call-template name="GetPrefixedStyleName">
        <xsl:with-param name="styleName" select="parent::draw:frame/@draw:style-name"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$prefixedStyleName!=''">
      <w:rStyle w:val="{$prefixedStyleName}"/>
    </xsl:if>
  </xsl:template>

  <!-- @TODO  positioning text-boxes -->
  <xsl:template match="draw:frame" mode="paragraph">
    <xsl:call-template name="InsertEmbeddedTextboxes"/>
  </xsl:template>

  <xsl:template match="draw:frame">
    <w:p>
      <xsl:call-template name="InsertEmbeddedTextboxes"/>
    </w:p>
  </xsl:template>

  <!-- inserts textboxes which are embedded in odf as one after another in word -->
  <xsl:template name="InsertEmbeddedTextboxes">
    <xsl:for-each select="descendant::draw:text-box">
      <xsl:apply-templates mode="paragraph" select="."/>
    </xsl:for-each>
  </xsl:template>

  <!-- lists -->
  <xsl:template match="text:list">
    <xsl:param name="level" select="-1"/>
    <xsl:apply-templates>
      <xsl:with-param name="level" select="$level+1"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- list headers -->
  <xsl:template match="text:list-header">
    <xsl:param name="level"/>
    <xsl:apply-templates>
      <xsl:with-param name="level" select="$level"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- list items -->
  <xsl:template match="text:list-item">
    <xsl:param name="level"/>
    <xsl:choose>
      <xsl:when test="*[1][self::text:p or self::text:h]">
        <w:p>
          <w:pPr>

            <!-- insert style -->
            <xsl:call-template name="InsertParagraphStyle">
              <xsl:with-param name="styleName" select="*[1]/@text:style-name"/>
            </xsl:call-template>

            <!-- insert number -->
            <xsl:call-template name="InsertListItemNumber">
              <xsl:with-param name="level" select="$level"/>
            </xsl:call-template>

            <!-- override abstract num indent and tab if paragraph has margin defined -->
            <xsl:call-template name="InsertIndent">
              <xsl:with-param name="level" select="$level"/>
            </xsl:call-template>

            <!-- insert heading outline level -->
            <xsl:call-template name="InsertOutlineLevel">
              <xsl:with-param name="node" select="*[1]"/>
            </xsl:call-template>

            <!-- insert page break before table when required -->
            <xsl:call-template name="InsertPageBreakBefore"/>
          </w:pPr>

          <!-- if we are in an annotation, we may have to insert annotation reference -->
          <xsl:call-template name="InsertAnnotationReference"/>

          <!-- footnote or endnote - Include the mark to the first paragraph only when first child of 
          text:note-body is not paragraph -->
          <xsl:if
            test="ancestor::text:note and not(ancestor::text:note-body/child::*[1][self::text:p | self::text:h]) and position() = 1">
            <xsl:apply-templates select="ancestor::text:note/text:note-citation" mode="note"/>
          </xsl:if>

          <!-- first paragraph -->
          <xsl:apply-templates select="*[1]" mode="paragraph"/>

        </w:p>

        <!-- others (text:p or text:list) -->
        <xsl:apply-templates select="*[position() != 1]">
          <xsl:with-param name="level" select="$level"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates>
          <xsl:with-param name="level" select="$level"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the number of a list item -->
  <xsl:template name="InsertListItemNumber">
    <xsl:param name="level"/>
    <w:numPr>
      <w:ilvl w:val="{$level}"/>
      <w:numId>
        <xsl:attribute name="w:val">
          <xsl:call-template name="numberingId">
            <xsl:with-param name="styleName" select="ancestor::text:list/@text:style-name"/>
          </xsl:call-template>
        </xsl:attribute>
      </w:numId>
    </w:numPr>
  </xsl:template>

  <!-- COMMENT: please be more explicit about the goal of this template and find a more explicit name -->
  <!-- table of contents -->
  <xsl:template name="tableContent">
    <xsl:param name="num"/>
    <!-- COMMENT: what is this "test" param for??? Please use more significant name -->
    <xsl:param name="test" select="0"/>
    <w:r>
      <xsl:choose>
        <xsl:when test="$test=1">
          <w:t>
            <xsl:for-each select="text:a/child::node()[position() &lt; last()]">
              <xsl:value-of select="."/>
            </xsl:for-each>
          </w:t>
        </xsl:when>
        <xsl:otherwise>
          <w:t>
            <xsl:for-each select="child::node()[position() &lt; last()]">
              <xsl:choose>
                <xsl:when test="self::text()">
                  <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="."/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </w:t>
          <!--<xsl:apply-templates select="child::text()[1]" mode="text"/>-->
        </xsl:otherwise>
      </xsl:choose>
    </w:r>
    <xsl:apply-templates select="text:tab|text:a/text:tab|text:span" mode="paragraph"/>
    <xsl:if test="not(ancestor::text:alphabetical-index)">
      <w:r>
        <w:rPr/>
        <w:fldChar w:fldCharType="begin">
          <w:fldData xml:space="preserve">CNDJ6nn5us4RjIIAqgBLqQsCAAAACAAAAA4AAABfAFQAbwBjADEANAAxADgAMwA5ADIANwA2AAAA</w:fldData>
        </w:fldChar>
      </w:r>
      <w:r>
        <w:rPr/>
        <w:instrText xml:space="preserve"><xsl:value-of select="concat('PAGEREF _Toc', $num, ' \h')"/></w:instrText>
      </w:r>
      <w:r>
        <w:rPr/>
        <w:fldChar w:fldCharType="separate"/>
      </w:r>
    </xsl:if>
    <w:r>
      <xsl:choose>
        <xsl:when test="$test=1">
          <xsl:apply-templates select="text:a/child::text()[last()]" mode="text"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="child::text()[last()]" mode="text"/>
          <!--<xsl:apply-templates select="child::text()[1]" mode="text"/>-->
        </xsl:otherwise>
      </xsl:choose>
    </w:r>
    <xsl:if test="not(ancestor::text:alphabetical-index)">
      <w:r>
        <w:rPr/>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
    </xsl:if>
  </xsl:template>

  <!-- indexes -->
  <xsl:template match="text:table-index|text:alphabetical-index|text:illustration-index">
    <xsl:if test="text:index-body/text:index-title/text:p">
      <xsl:apply-templates select="text:index-body/text:index-title/text:p"/>
    </xsl:if>

    <xsl:for-each select="text:index-body/child::text:p">
      <xsl:variable name="num">
        <xsl:value-of select="position()+count( key('headers',''))+1"/>
      </xsl:variable>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    <w:p>
      <w:r>
        <w:rPr/>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
    </w:p>
  </xsl:template>

  <!-- table of content -->
  <xsl:template match="text:table-of-content">
    <w:sdt>
      <w:sdtPr>
        <w:docPartObj>
          <w:docPartType w:val="'Table of Contents'"/>
        </w:docPartObj>
      </w:sdtPr>
      <w:sdtContent>
        <xsl:if test="text:index-body/text:index-title/text:p">
          <xsl:apply-templates select="text:index-body/text:index-title/text:p"/>
        </xsl:if>
        <xsl:for-each select="text:index-body/child::text:p">
          <xsl:variable name="num">
            <xsl:number/>
          </xsl:variable>
          <xsl:apply-templates select="."/>
        </xsl:for-each>
        <w:p>
          <w:r>
            <w:rPr/>
            <w:fldChar w:fldCharType="end"/>
          </w:r>
        </w:p>
      </w:sdtContent>
    </w:sdt>
  </xsl:template>

  <!-- text and spaces -->
  <xsl:template match="text()|text:s" mode="paragraph">
    <w:r>
      <xsl:call-template name="InsertRunProperties"/>
      <xsl:apply-templates select="." mode="text"/>
    </w:r>
  </xsl:template>

  <!-- Inserts the Run properties -->
  <xsl:template name="InsertRunProperties">
    <!-- apply text properties if needed -->
    <xsl:if test="ancestor::text:span|self::text:list-level-style-number">
      <w:rPr>
        <xsl:call-template name="InsertRunStyle">
          <xsl:with-param name="styleName">
            <xsl:call-template name="GetStyleName"/>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="OverrideToggleProperties">
          <xsl:with-param name="styleName">
            <xsl:call-template name="GetStyleName"/>
          </xsl:with-param>
        </xsl:call-template>
      </w:rPr>
    </xsl:if>
  </xsl:template>

  <!-- Inserts the style of a run -->
  <xsl:template name="InsertRunStyle">
    <xsl:param name="styleName"/>
    <xsl:variable name="prefixedStyleName">
      <xsl:call-template name="GetPrefixedStyleName">
        <xsl:with-param name="styleName" select="$styleName"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$prefixedStyleName!=''">
      <w:rStyle w:val="{$prefixedStyleName}"/>
    </xsl:if>
  </xsl:template>

  <!-- Overrides toggle properties -->
  <xsl:template name="OverrideToggleProperties">
    <xsl:param name="styleName"/>
    <xsl:variable name="onlyToggle">
      <xsl:choose>
        <xsl:when test="self::text:list-level-style-number">false</xsl:when>
        <xsl:otherwise>true</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="key('automatic-styles',$styleName)">
        <!-- recursive call on parent style (not very clean) -->
        <xsl:if test="key('automatic-styles',$styleName)/@style:parent-style-name">
          <xsl:call-template name="OverrideToggleProperties">
            <xsl:with-param name="styleName"
              select="key('automatic-styles',$styleName)/@style:parent-style-name"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:apply-templates select="key('automatic-styles',$styleName)/style:text-properties"
          mode="rPr">
          <xsl:with-param name="onlyToggle" select="'$onlyToggle'"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:for-each select="document('styles.xml')">
          <!-- recursive call on parent style (not very clean) -->
          <xsl:if test="key('styles',$styleName)/@style:parent-style-name">
            <xsl:call-template name="OverrideToggleProperties">
              <xsl:with-param name="styleName"
                select="key('styles',$styleName)/@style:parent-style-name"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:apply-templates select="key('styles',$styleName)/style:text-properties" mode="rPr">
            <xsl:with-param name="onlyToggle" select="'$onlyToggle'"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- spaces (within a text flow) -->
  <xsl:template match="text:s" mode="text">
    <w:t xml:space="preserve"><xsl:call-template name="extra-spaces"><xsl:with-param name="spaces" select="@text:c"/></xsl:call-template></w:t>
  </xsl:template>

  <!-- simple text (within a text flow) -->
  <xsl:template match="text()" mode="text">


    <xsl:choose>
      <xsl:when test="ancestor::text:index-body">
        <xsl:choose>
          <xsl:when test="preceding-sibling::text:tab">
            <w:t xml:space="preserve"><xsl:value-of select="."/></w:t>
          </xsl:when>
          <xsl:when test="not(following-sibling::text:tab)">
            <w:t xml:space="preserve"><xsl:value-of select="."/></w:t>
          </xsl:when>
          <xsl:otherwise> </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <w:t xml:space="preserve"><xsl:value-of select="."/></w:t>
      </xsl:otherwise>



    </xsl:choose>


  </xsl:template>

  <!-- tab stops -->
  <xsl:template match="text:tab-stop" mode="paragraph">
    <w:r>
      <w:tab/>
      <w:t/>
    </w:r>
  </xsl:template>

  <!-- tabs -->
  <xsl:template match="text:tab" mode="paragraph">
    <w:r>
      <w:tab/>
    </w:r>
  </xsl:template>

  <!-- line breaks -->
  <xsl:template match="text:line-break" mode="paragraph">
    <w:r>
      <w:br/>
      <w:t/>
    </w:r>
  </xsl:template>

  <!-- line breaks (within the text flow) -->
  <xsl:template match="text:line-break" mode="text">
    <w:br/>
  </xsl:template>

  <!-- notes (footnotes or endnotes) -->
  <xsl:template match="text:note" mode="paragraph">
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{concat(@text:note-class, 'Reference')}"/>
      </w:rPr>
      <xsl:apply-templates select="." mode="text"/>
    </w:r>
  </xsl:template>

  <!-- footnotes -->
  <xsl:template match="text:note[@text:note-class='footnote']" mode="text">
    <w:footnoteReference>
      <xsl:attribute name="w:id">
        <xsl:call-template name="GenerateId">
          <xsl:with-param name="node" select="."/>
          <xsl:with-param name="nodetype" select="@text:note-class"/>
        </xsl:call-template>
      </xsl:attribute>
    </w:footnoteReference>
    <xsl:if test="text:note-citation/@text:label">
      <w:t>
        <xsl:value-of select="text:note-citation"/>
      </w:t>
    </xsl:if>
  </xsl:template>

  <!-- endnotes -->
  <xsl:template match="text:note[@text:note-class='endnote']" mode="text">
    <w:endnoteReference>
      <xsl:attribute name="w:id">
        <xsl:call-template name="GenerateId">
          <xsl:with-param name="node" select="."/>
          <xsl:with-param name="nodetype" select="@text:note-class"/>
        </xsl:call-template>
      </xsl:attribute>
    </w:endnoteReference>
    <xsl:if test="text:note-citation/@text:label">
      <w:t>
        <xsl:value-of select="text:note-citation"/>
      </w:t>
    </xsl:if>
  </xsl:template>

  <!-- alphabetical indexes -->
  <xsl:template match="text:alphabetical-index-mark-end" mode="paragraph">
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve"> XE "</w:instrText>
    </w:r>
    <w:r>
      <w:instrText>
        <xsl:variable name="id" select="@text:id"/>
        <xsl:for-each select="preceding-sibling::node()">
          <xsl:if
            test="preceding-sibling::node()[name() = 'text:alphabetical-index-mark-start' and @text:id = $id]">
            <xsl:choose>
              <xsl:when test="self::text()">
                <xsl:value-of select="."/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:for-each>
      </w:instrText>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve">" </w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
    <!-- <xsl:apply-templates select="text:s" mode="text"></xsl:apply-templates> -->
  </xsl:template>

  <!-- spaces -->
  <xsl:template match="text:s">
    <xsl:call-template name="extra-spaces">
      <xsl:with-param name="spaces" select="@text:c"/>
    </xsl:call-template>
  </xsl:template>

  <!-- sequences -->
  <xsl:template match="text:sequence" mode="paragraph">
    <xsl:variable name="id">
      <xsl:value-of select="number(count(preceding::text:sequence)+count( key('headers','')))+1"/>
      <!--<xsl:value-of select="count( key('headers',''))"/>-->
    </xsl:variable>
    <w:fldSimple>
      <xsl:variable name="numType">
        <xsl:choose>
          <xsl:when test="@style:num-format = 'i'">\* roman</xsl:when>
          <xsl:when test="@style:num-format = 'I'">\* Roman</xsl:when>
          <xsl:when test="@style:num-format = 'a'">\* alphabetic</xsl:when>
          <xsl:when test="@style:num-format = 'A'">\* ALPHABETIC</xsl:when>
          <xsl:otherwise>\* arabic</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:attribute name="w:instr">
        <xsl:value-of select="concat('SEQ ', @text:name,' ', $numType)"/>
      </xsl:attribute>
      <w:bookmarkStart w:id="{$id}" w:name="{concat('_Toc',$id)}"/>
      <w:r>
        <w:t>
          <xsl:value-of select="."/>
        </w:t>
      </w:r>
      <w:bookmarkEnd w:id="{$id}"/>
    </w:fldSimple>
  </xsl:template>

  <!-- sections -->
  <xsl:template match="text:section">
    <xsl:choose>
      <xsl:when test="@text:display='none'"> </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Extra spaces management, courtesy of J. David Eisenberg -->
  <xsl:variable name="spaces" xml:space="preserve">                                       </xsl:variable>

  <xsl:template name="extra-spaces">
    <xsl:param name="spaces"/>
    <xsl:choose>
      <xsl:when test="$spaces">
        <xsl:call-template name="insert-spaces">
          <xsl:with-param name="n" select="$spaces"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="insert-spaces">
    <xsl:param name="n"/>
    <xsl:choose>
      <xsl:when test="$n &lt;= string-length($spaces)">
        <xsl:value-of select="substring($spaces, 1, $n)" xml:space="preserve"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$spaces"/>
        <xsl:call-template name="insert-spaces">
          <xsl:with-param name="n">
            <xsl:value-of select="$n - string-length($spaces)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ignored -->
  <xsl:template match="text()"/>
  <xsl:template match="text:tracked-changes"/>

</xsl:stylesheet>
