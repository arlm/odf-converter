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
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ooc="urn:odf-converter"
  exclude-result-prefixes="config svg office number text table style fo draw xlink ooc">

  <xsl:import href="2oox-tables.xsl"/>
  <xsl:import href="2oox-indexes.xsl"/>
  <xsl:import href="2oox-bookmarks.xsl"/>

  <xsl:key name="annotations" match="office:annotation" use="''"/>
  <xsl:key name="automatic-styles" match="office:automatic-styles/style:style" use="@style:name"/>
  <xsl:key name="hyperlinks" match="text:a" use="''"/>
  <xsl:key name="headers" match="text:h" use="''"/>
  <!--<xsl:key name="restarting-lists" match="text:list[text:list-item/@text:start-value and @text:style-name]" use="''"/>-->
  <xsl:key name="restarting-lists" match="//text:list[text:list-item/@text:start-value]" use="''"/>

  <xsl:variable name="body" select="document('content.xml')/office:document-content/office:body"/>
  <!-- key to find hyperlinks with a particular style. -->
  <xsl:key name="style-modified-hyperlinks" match="text:a" use="text:span/@text:style-name"/>

  <!-- protected sections -->
  <xsl:variable name="protected-sections" select="document('content.xml')/office:document-content/office:body//text:section[@text:protected='true']"/>

  <!-- table of content count -->
  <xsl:variable name="tocCount">
    <xsl:for-each select="document('content.xml')">
      <xsl:value-of select="count(key('toc', ''))"/>
    </xsl:for-each>
  </xsl:variable>

  <!-- remember id of first paragraph -->
  <xsl:variable name="firstParaId" select="generate-id(($body/office:text/text:p | $body/office:text/text:h)[1])" />

  <!-- main document -->
  <xsl:template name="document">
    <w:document w:conformance="transitional">
      <!-- Translate the default master page color as the document background color -->
      <xsl:for-each select="document('styles.xml')">
        <xsl:variable name="defaultBgColor" select="key('page-layouts', $default-master-style/@style:page-layout-name)[1]/style:page-layout-properties/@fo:background-color"/>
        <xsl:if test="$defaultBgColor != 'transparent'">
          <w:background w:color="{translate(substring-after($defaultBgColor,'#'),'f','F')}"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates select="document('content.xml')/office:document-content"/>
    </w:document>
  </xsl:template>

  <!-- document body -->
  <xsl:template match="office:body">
    <w:body>
      <!-- read-write odf document with protected sections : 
        the whole openxml document is made readonly and permissions are granted everywhere,
        but on protected section -->
      <!-- read-only odf document : 
        the whole openxml document is made readonly and permissions are granted on editable sections -->
      <xsl:if test="not(boolean($load-readonly)) and $protected-sections[1]">
        <!-- permission range id's added in a post processing step -->
        <w:permStart w:edGrp="everyone"/>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:if test="not(boolean($load-readonly)) and $protected-sections[1]">
        <w:permEnd/>
      </xsl:if>
      <xsl:call-template name="InsertDocumentFinalSectionProperties"/>
    </w:body>
  </xsl:template>


  <!-- paragraphs and headings -->
  <xsl:template match="text:p | text:h">
    <xsl:param name="level" select="0"/>
    <xsl:param name="isFirstRow" select="'false'"/>

    <xsl:message terminate="no">progress:text:p</xsl:message>    
    <w:p>
      <xsl:if test="not(parent::table:table-cell)">
        <xsl:call-template name="InsertDropCap">
          <xsl:with-param name="styleName" select="@text:style-name"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:call-template name="MarkMasterPage"/>
      <w:pPr>
        <xsl:call-template name="InsertParagraphProperties">
          <xsl:with-param name="level" select="$level"/>
          <xsl:with-param name="isFirstRow" select="$isFirstRow"/>
        </xsl:call-template>
        <!--dialogika, clam: section breaks have their own paragraphs now (bug #1615686)-->
        <!--<xsl:call-template name="InsertParagraphSectionProperties"/>-->
        <xsl:if test="parent::text:index-body">
          <xsl:call-template name="InsertIndexTabs"/>
        </xsl:if>
      </w:pPr>
      <!-- if paragraph is the very first of the document, declare user variables -->
      <xsl:if test="$body/office:text/text:user-field-decls">
        <xsl:if test="generate-id(.) = $firstParaId">
          <xsl:call-template name="InsertUserFieldDeclaration"/>
        </xsl:if>
      </xsl:if>

      <!-- insert drawing objects that are preceding-sibling of current. -->
      <xsl:call-template name="InsertPrecedingDrawingObject"/>

      <!-- insert bookmark for element which is contained in TOC-->
      <xsl:if test="$tocCount &gt; 0">
        <xsl:call-template name="InsertTOCBookmark"/>
      </xsl:if>

      <!-- insert a page break if a table with break after is preceding -->
      <xsl:call-template name="InsertPageBreakAfterTable"/>

      <!-- footnotes or endnotes: insert the mark in the first paragraph -->
      <xsl:if test="parent::text:note-body and position() = 1">
        <xsl:apply-templates select="../../text:note-citation" mode="note"/>
      </xsl:if>

      <!-- paragraph content-->
      <xsl:call-template name="InsertParagraphContent"/>

      <!-- reference to user-defined-TOC if we are in first paragraph of a table -->
      <xsl:call-template name="InsertTCField"/>

      <!-- If there is a page-break-after in the paragraph style -->
      <xsl:call-template name="InsertPageBreakAfter"/>
    </w:p>
    <!--dialogika, clam: section breaks have their own paragraphs now (bug #1615686)-->
    <xsl:call-template name="InsertParagraphSectionProperties"/>
  </xsl:template>


  <!-- conversion of paragraph content excluding not supported elements -->
  <xsl:template name="InsertParagraphContent">
    <xsl:call-template name="InsertColumnBreakBefore"/>
    <xsl:choose>

      <!-- we are in table of contents -->
      <xsl:when test="parent::text:index-body">
        <xsl:call-template name="InsertIndexItem"/>
      </xsl:when>

      <!-- ignore draw:frame/draw:text-box if it's embedded in another draw:frame/draw:text-box because word doesn't support it -->
      <xsl:when test="self::node()[ancestor::draw:text-box and descendant::draw:text-box]">
        <xsl:message terminate="no">translation.odf2oox.nestedFrames</xsl:message>
        <xsl:apply-templates select="child::node()[not(descendant-or-self::draw:text-box)]" mode="paragraph"/>
      </xsl:when>

      <!-- frames -->
      <xsl:when test="child::draw:frame">
        <xsl:choose>
          <xsl:when test="ancestor::draw:text-box">
            <xsl:message terminate="no">translation.odf2oox.positionInsideTextbox</xsl:message>
            <xsl:variable name="wrapping">
              <xsl:call-template name="GetGraphicProperties">
                <xsl:with-param name="shapeStyle" select="key('styles', draw:frame/@draw:style-name)"/>
                <xsl:with-param name="attribName">style:wrap</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$wrapping = 'none' and not(draw:frame/@text:anchor-type='as-char')">
                <xsl:apply-templates select="node()[not(self::draw:frame)]" mode="paragraph"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates mode="paragraph"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates mode="paragraph"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- drawing shapes -->
      <xsl:when test="child::draw:ellipse|child::draw:rect|child::draw:custom-shape">
        <xsl:choose>
          <xsl:when test="ancestor::draw:text-box">
            <xsl:message terminate="no">translation.odf2oox.nestedFrames</xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <!-- Sona: 30-10-08- Commented the unwanted template call for defect #2207037-Single shape replaced with two shapes -->
            <!--<xsl:apply-templates mode="shapes"/>-->
            <!-- 2008-10-22/divo following line added to fix #2163354 ODT: Wrap around - tabs are lost-->
            <xsl:apply-templates mode="paragraph"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>

        <!-- this is the first paragraph after the TOC, insert the TOC end -->
        <!--<xsl:if test="preceding-sibling::node()[1][self::text:table-of-content]">
          <xsl:call-template name="InsertIndexFieldCodeEnd"/>
        </xsl:if>-->

        <xsl:apply-templates mode="paragraph"/>
      </xsl:otherwise>

    </xsl:choose>

    <xsl:call-template name="InsertColumnBreakAfter"/>
  </xsl:template>

  <!-- inserts page-break-after if defined for paragraph  -->
  <xsl:template name="InsertPageBreakAfter">
    <xsl:if test="key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='page' ">
      <w:r>
        <w:br w:type="page"/>
      </w:r>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="following-sibling::*[position()=1]//text:soft-page-break">
        <xsl:call-template name="SoftPageBreaks"></xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="not(following-sibling::*[position()=1])">
          <xsl:if test="../following-sibling::*[position()=1]//text:soft-page-break">
            <xsl:call-template name="SoftPageBreaks"></xsl:call-template>
          </xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    <!--<xsl:if test="following-sibling::*[position()=1]//text:soft-page-break">
      <xsl:call-template name="SoftPageBreaks"></xsl:call-template>
    </xsl:if>-->
  </xsl:template>

  <!-- inserts page-break-before if defined in preceding table -->
  <xsl:template name="InsertPageBreakAfterTable">
    <xsl:if test="preceding-sibling::node()[1][self::table:table]">
      <xsl:if test="key('automatic-styles', preceding-sibling::node()[1][self::table:table]/@table:style-name)/style:table-properties/@fo:break-after='page' ">
        <w:r>
          <w:br w:type="page"/>
        </w:r>
      </xsl:if>
    </xsl:if>
  </xsl:template>


  <!--
  Summary:  Inserts the direct formatting of a paragraph.
  Author:   CleverAge
  Modified: makz (DIaLOGIKa)
  Date:     30.09.2008
  Params:   level:
            isFirstRow:
  -->
  <xsl:template name="InsertParagraphProperties">
    <xsl:param name="level"/>
    <xsl:param name="isFirstRow"/>

    <xsl:variable name="styleName" select="@text:style-name" />
    
    <!-- 
    makz: Insert paragraph style reference.
          Do not add reference if the style is an automatic style.
          Convert the properties of the automatic style to direct formatting instead.
    -->
    <xsl:choose>
      <xsl:when test="key('automatic-styles', $styleName)">

        <!-- Reference the parent style of the automatic style... -->
        <xsl:if test="key('automatic-styles', $styleName)/@style:parent-style-name">
          <xsl:call-template name="InsertParagraphStyle">
            <xsl:with-param name="styleName" select="key('automatic-styles', $styleName)/@style:parent-style-name"/>
          </xsl:call-template>
        </xsl:if>

        <!-- ...and convert the automatic style -->
        <xsl:for-each select="key('automatic-styles', $styleName)">
          <xsl:apply-templates select="style:paragraph-properties" mode="pPr"/>
        </xsl:for-each>

      </xsl:when>
      <xsl:when test="$styleName">

        <!-- Reference the style defined in the style part -->
        <xsl:call-template name="InsertParagraphStyle">
          <xsl:with-param name="styleName" select="$styleName"/>
        </xsl:call-template>

      </xsl:when>
    </xsl:choose>

    <!--  indent  -->
    <xsl:if test="key('automatic-styles', $styleName)/style:paragraph-properties/@fo:margin-left">

      <!--math, dialogika: changed for correct indentation calculation of headings 
      that are not in an <text:list> element but have an outline level BEGIN -->

      <xsl:variable name="ParagraphProperties" select="key('automatic-styles', $styleName)/style:paragraph-properties" />

      <xsl:variable name="MarginLeft" select="$ParagraphProperties/@fo:margin-left" />
      
      <xsl:variable name="OutlineLvl">
        <xsl:choose>
          <xsl:when test="@text:outline-level">
            <xsl:value-of select="@text:outline-level"/>
          </xsl:when>
          <xsl:otherwise>NaN</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="OutlineLvlProperties" select="document('styles.xml')/office:document-styles/office:styles/text:outline-style/text:outline-level-style[@text:level = $OutlineLvl]/style:list-level-properties" />

      <xsl:variable name="SpaceBefore">
        <xsl:choose>
          <xsl:when test="$OutlineLvlProperties/@text:space-before" >
            <xsl:value-of select="$OutlineLvlProperties/@text:space-before" />
          </xsl:when>
          <xsl:otherwise>0cm</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="MinLabelWidth">
        <xsl:choose>
          <xsl:when test="$OutlineLvlProperties/@text:min-label-width" >
            <xsl:value-of select="$OutlineLvlProperties/@text:min-label-width" />
          </xsl:when>
          <xsl:otherwise>0cm</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="MinLabelDistance">
        <xsl:choose>
          <xsl:when test="$OutlineLvlProperties/@text:min-label-distance" >
            <xsl:value-of select="$OutlineLvlProperties/@text:min-label-distance" />
          </xsl:when>
          <xsl:otherwise>0cm</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="TextIndent">
        <xsl:choose>
          <xsl:when test="$ParagraphProperties/@fo:text-indent" >
            <xsl:value-of select="$ParagraphProperties/@fo:text-indent" />
          </xsl:when>
          <xsl:otherwise>0cm</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>


      <w:ind>

        <xsl:attribute name="w:left">
          <xsl:variable name="twipsMarginLeft" select="ooc:TwipsFromMeasuredUnit($MarginLeft)" />
          <xsl:variable name="twipsSpaceBefore" select="ooc:TwipsFromMeasuredUnit($SpaceBefore)" />
          <xsl:variable name="twipsMinLabelWidth" select="ooc:TwipsFromMeasuredUnit($MinLabelWidth)" />

          <xsl:value-of select="$twipsMarginLeft + $twipsSpaceBefore + $twipsMinLabelWidth"/>
          
        </xsl:attribute>

        <xsl:attribute name="w:right">
          <xsl:value-of select="ooc:TwipsFromMeasuredUnit($ParagraphProperties/@fo:margin-right)"/>
        </xsl:attribute>

        <xsl:variable name="FirstLineIndent">
          <xsl:variable name="twipsTextIndent" select="ooc:TwipsFromMeasuredUnit($TextIndent)" />
          <xsl:variable name="twipsMinLabelWidth" select="ooc:TwipsFromMeasuredUnit($MinLabelWidth)" />

          <!--<xsl:value-of select="substring-before($TextIndent, 'cm') - substring-before($MinLabelWidth, 'cm')" />-->
          <!--math, dialogika: Bugfix #2001515: if @text:is-list-header = 'true' list option min-label-width is ignored BEGIN-->
          <xsl:choose>
            <xsl:when test ="@text:is-list-header = 'true'">
              <xsl:value-of select="$twipsTextIndent"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$twipsTextIndent - $twipsMinLabelWidth"/>
            </xsl:otherwise>
          </xsl:choose>
          <!--math, dialogika: Bugfix #2001515: if @text:is-list-header = 'true' list option min-label-width is ignored END-->
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="$FirstLineIndent &gt; 0">
            <xsl:attribute name="w:firstLine">
              <xsl:value-of select="$FirstLineIndent" />
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="w:hanging">
              <xsl:value-of select="-$FirstLineIndent" />
            </xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>

      </w:ind>

      <w:tabs>

        <xsl:call-template name="InsertNumberingTab">
          <xsl:with-param name="tabVal">num</xsl:with-param>
          <xsl:with-param name="addLeftIndent" select="ooc:TwipsFromMeasuredUnit($MarginLeft)"/>
          <xsl:with-param name="firstLineIndent" select="ooc:TwipsFromMeasuredUnit($TextIndent)"/>
          <xsl:with-param name="minLabelDistanceTwip" select="ooc:TwipsFromMeasuredUnit($MinLabelDistance)"/>
          <xsl:with-param name="minLabelWidthTwip" select="ooc:TwipsFromMeasuredUnit($MinLabelWidth)"/>
          <xsl:with-param name="spaceBeforeTwip" select="ooc:TwipsFromMeasuredUnit($SpaceBefore)"/>
        </xsl:call-template>

        <!--math, dialogika bugfix #1834587 BEGIN-->
        <!-- add tabs of current paragraph so as not to lose them in post-processing -->
        <xsl:if test="key('styles', $styleName)//style:tab-stop">
          <xsl:for-each select="key('styles', $styleName)/style:paragraph-properties">
            <xsl:call-template name="ComputeParagraphTabs"/>
          </xsl:for-each>
        </xsl:if>
        <!--math, dialogika bugfix #1834587 END-->

      </w:tabs>

    </xsl:if>

    <!-- insert page break before table when required -->
	 <!--St_OnOff-->
    <xsl:choose>
      <xsl:when test="$isFirstRow = 'true' ">
        <w:pageBreakBefore w:val="1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="InsertPageBreakBefore"/>
      </xsl:otherwise>
    </xsl:choose>

    <!-- insert frame properties -->
    <xsl:call-template name="InsertFrameProperties"/>

    <!-- insert numbering properties -->
    <xsl:call-template name="InsertNumbering">
      <xsl:with-param name="level" select="$level"/>
    </xsl:call-template>


    <!-- line numbering -->
    <xsl:call-template name="InsertSupressLineNumbers"/>

    <!-- override spacing before/after when required -->
    <xsl:call-template name="InsertParagraphSpacing"/>

    <!-- insert tab stops if paragraph is in a list -->
    <xsl:call-template name="OverrideNumberingProperty">
      <xsl:with-param name="level" select="$level"/>
      <xsl:with-param name="property">tab</xsl:with-param>
    </xsl:call-template>

    <!-- insert bg color in case paragraph is in table-of-content -->
    <xsl:call-template name="InsertTOCBgColor"/>

    <!-- insert indentation if paragraph is in a list -->
    <xsl:call-template name="OverrideNumberingProperty">
      <xsl:with-param name="level" select="$level"/>
      <xsl:with-param name="property">indent</xsl:with-param>
    </xsl:call-template>

    <!-- insert heading outline level -->
    <xsl:call-template name="InsertOutlineLevel">
      <xsl:with-param name="node" select="."/>
    </xsl:call-template>

    <!-- if we are in an annotation, we may have to insert annotation reference -->
    <xsl:call-template name="InsertAnnotationReference"/>

    <!-- insert run properties -->
    <xsl:call-template name="InsertRunProperties"/>

  </xsl:template>

  <!-- Inserts the style of a paragraph -->
  <xsl:template name="InsertParagraphStyle">
    <xsl:param name="styleName"/>

    <xsl:choose>
      <xsl:when test="ancestor::text:table-of-content and not (ancestor::text:index-title)">
        <xsl:choose>
          <xsl:when test="key('automatic-styles', $styleName)/@style:parent-style-name">
            <xsl:variable name="level" select="ancestor::text:table-of-content/*/text:table-of-content-entry-template[@text:style-name = key('automatic-styles', $styleName)/@style:parent-style-name]/@text:outline-level " />
            
            <xsl:if test="number($level)">
              <w:pStyle w:val="{concat('TOC', $level)}"/>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <!--Sonata: Defect fix: 2684775 and 2684759 
                In SP2 converted odt file, sometimes Toc style is not created. So, commented test="key('styles', $styleName) condition -->
            <!--<xsl:if test="key('styles', $styleName)">-->
              <xsl:variable name="level" select="ancestor::text:table-of-content/*/text:table-of-content-entry-template[@text:style-name = $styleName]/@text:outline-level " />
              
              <xsl:if test="number($level)">
                <w:pStyle w:val="{concat('TOC', $level)}"/>
              </xsl:if>
            <!--</xsl:if>-->
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="prefixedStyleName">
          <xsl:call-template name="GetPrefixedStyleName">
            <xsl:with-param name="styleName" select="$styleName"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$prefixedStyleName != ''">
          <w:pStyle w:val="{$prefixedStyleName}"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- insert frame properties if paragraph is in a particular fame (eg envelope) -->
  <xsl:template name="InsertFrameProperties">
    <xsl:if test="(@text:style-name='Addressee' or @text:style-name='Sender') and ancestor::draw:frame">
      <xsl:variable name="framePr" select="ancestor::draw:frame[last()]"/>
      <w:framePr>
        <!-- width -->
        <xsl:if test="$framePr/@svg:width">
          <xsl:attribute name="w:w">
            <xsl:value-of select="ooc:TwipsFromMeasuredUnit($framePr/@svg:width)" />
          </xsl:attribute>
        </xsl:if>
        <!-- height -->
        <xsl:choose>
          <xsl:when test="ancestor::draw:text-box[last()]/@fo:min-height">
            <xsl:attribute name="w:h">
              <xsl:value-of select="ooc:TwipsFromMeasuredUnit(ancestor::draw:text-box[last()]/@fo:min-height)"/>
            </xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$framePr/@svg:height">
              <xsl:attribute name="w:h">
                <xsl:value-of select="ooc:TwipsFromMeasuredUnit($framePr/@svg:height)" />
              </xsl:attribute>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
        <!-- height rule -->
        <xsl:attribute name="w:hRule">
          <xsl:choose>
            <xsl:when test="$framePr/@fo:min-height">atLeast</xsl:when>
            <xsl:when test="$framePr/@svg:height">exact</xsl:when>
            <xsl:otherwise>auto</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <!-- position -->
        <xsl:if test="$framePr/@svg:x">
          <xsl:attribute name="w:x">
            <xsl:value-of select="ooc:TwipsFromMeasuredUnit($framePr/@svg:x)"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="$framePr/@svg:y">
          <xsl:attribute name="w:y">
            <xsl:value-of select="ooc:TwipsFromMeasuredUnit($framePr/@svg:y)" />
          </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="w:hAnchor">page</xsl:attribute>
        <xsl:attribute name="w:wrap">auto</xsl:attribute>
      </w:framePr>
    </xsl:if>
  </xsl:template>

  <!-- override spacing properties -->
  <xsl:template name="InsertParagraphSpacing">
    <xsl:choose>
      <xsl:when test="ancestor::table:table">
        <xsl:if
          test="document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaTableSpacingAtStart']/text()='false'
          or document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaSpacingToTableCells']/text()='false' ">
          <w:spacing>
            <!-- Suppress spacing before/after in tables if corresponding setting enabled -->
            <xsl:if
              test="document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaTableSpacingAtStart']/text()='false' ">
              <xsl:if test="not(preceding-sibling::node())">
                <xsl:attribute name="w:before">0</xsl:attribute>
              </xsl:if>
            </xsl:if>
            <xsl:if
              test="document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaSpacingToTableCells']/text()='false' ">
              <xsl:if test="not(following-sibling::node())">
                <xsl:attribute name="w:after">0</xsl:attribute>
              </xsl:if>
            </xsl:if>
          </w:spacing>
        </xsl:if>
      </xsl:when>
      <xsl:when test="ancestor::draw:frame">
        <xsl:if
          test="document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaTableSpacingAtStart']/text()='false' ">
          <w:spacing>
            <xsl:if test="not(preceding-sibling::node())">
              <xsl:attribute name="w:before">0</xsl:attribute>
            </xsl:if>
          </w:spacing>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <!-- check if para is first of page -->
        <xsl:variable name="isFirstOfPage">
          <xsl:call-template name="GetBreakBeforeProperty">
            <xsl:with-param name="style-name" select="@text:style-name"/>
          </xsl:call-template>
        </xsl:variable>
        <!-- override space before to 0 if required -->
        <xsl:variable name="OverrideSpaceBefore">
          <xsl:if
            test="document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaTableSpacingAtStart']/text()='false' ">
            <xsl:if test="$isFirstOfPage = 'true' ">0</xsl:if>
          </xsl:if>
        </xsl:variable>
        <!-- Insert spacing in paragraph properties if table before/after w:p element has spacing after/before -->
        <xsl:if
          test="($isFirstOfPage and document('settings.xml')/office:document-settings/office:settings/config:config-item-set[@config:name='ooo:configuration-settings']/config:config-item[@config:name='AddParaTableSpacingAtStart']/text()='false' )
          or following-sibling::node()[1][name()='table:table'] or preceding-sibling::node()[1][name()='table:table']">
          <!-- Compute space after -->
          <xsl:variable name="spaceAfter">
            <xsl:call-template name="CompareSpacingValues">
              <xsl:with-param name="tableSide" select="'top'"/>
              <xsl:with-param name="paraSide" select="'bottom'"/>
            </xsl:call-template>
          </xsl:variable>
          <!-- Compute space before -->
          <xsl:variable name="spaceBefore">
            <xsl:call-template name="CompareSpacingValues">
              <xsl:with-param name="tableSide" select="'bottom'"/>
              <xsl:with-param name="paraSide" select="'top'"/>
            </xsl:call-template>
          </xsl:variable>
          <!-- override if needed -->
          <xsl:if
            test="$OverrideSpaceBefore = 0 or $spaceBefore &gt; 0 or $spaceAfter &gt; 0">
            <w:spacing>
              <xsl:choose>
                <xsl:when test="$OverrideSpaceBefore = 0">
                  <xsl:attribute name="w:before">0</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:if test="$spaceBefore &gt; 0">
                    <xsl:attribute name="w:before">
                      <xsl:value-of select="$spaceBefore"/>
                    </xsl:attribute>
                  </xsl:if>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="$spaceAfter &gt; 0">
                <xsl:attribute name="w:after">
                  <xsl:value-of select="$spaceAfter"/>
                </xsl:attribute>
              </xsl:if>
            </w:spacing>
          </xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Climb style hierarchy for a property -->
  <xsl:template name="GetBreakBeforeProperty">
    <xsl:param name="style-name"/>
    <xsl:param name="context">content.xml</xsl:param>

    <xsl:variable name="exists">
      <xsl:for-each select="document($context)">
        <xsl:value-of select="boolean(key('styles', $style-name))"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$exists = 'true' ">
        <xsl:for-each select="document($context)">
          <xsl:variable name="style" select="key('styles', $style-name)[1]"/>
          <xsl:choose>
            <xsl:when test="$style/style:paragraph-properties/@fo:break-before = 'page' ">true</xsl:when>
            <xsl:when test="$style/@style:master-page-name != '' ">true</xsl:when>
            <xsl:when test="$style/@style:parent-style-name">
              <xsl:if test="$style/@style:parent-style-name != $style-name">
                <xsl:call-template name="GetBreakBeforeProperty">
                  <xsl:with-param name="style-name" select="$style/@style:parent-style-name"/>
                  <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>false</xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <!-- switch the context, let's look into styles.xml -->
      <xsl:when test="$context != 'styles.xml'">
        <xsl:call-template name="GetBreakBeforeProperty">
          <xsl:with-param name="style-name" select="$style-name"/>
          <xsl:with-param name="context" select="'styles.xml'"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>



  <!-- Computes the style name in a given situation -->
  <xsl:template name="GetStyleName">
    <xsl:choose>
      <xsl:when test="parent::style:style/@style:name">
        <xsl:value-of select="parent::style:style/@style:name"/>
      </xsl:when>
      <xsl:when test="self::text:list-item|self::text:list-header">
        <xsl:value-of select="*[1][self::text:p or self::text:h]/@text:style-name"/>
      </xsl:when>
      <xsl:when
        test="parent::text:list-header|self::text:p|self::text:h|self::text:list-level-style-number|self::text:outline-level-style">
        <xsl:value-of select="@text:style-name"/>
      </xsl:when>
      <xsl:when test="parent::text:p|parent::text:h">
        <xsl:value-of select="parent::node()/@text:style-name"/>
      </xsl:when>
      <xsl:when test="ancestor::node()[(self::text:a or self::text:span) and @text:style-name]">
        <xsl:value-of select="ancestor::node()[(self::text:a or self::text:span) and @text:style-name][1]/@text:style-name" />
        <!--2008-10-22/divo: This bugfix did not seem to make any sense to me, in fact it introduced 
            regression #2171776 DOCX>ODT:Roundtrip: Different fontsizes within textbox -->
        <!--<xsl:variable name="myStyles" select="ancestor::node()[(self::text:a or self::text:span) and @text:style-name]/@text:style-name"></xsl:variable>
        <xsl:variable name="firstStyle" select="ancestor::node()[(self::text:a or self::text:span) and @text:style-name][1]/@text:style-name"></xsl:variable>
        <xsl:variable name="IsAutomaticStyle" select="document('content.xml')//office:document-content/office:automatic-styles/style:style[@style:name=$firstStyle]">
        </xsl:variable> 
        <xsl:choose>
          -->
        <!--clam, dialogika: bugfix 1947633-->
        <!--
          <xsl:when test="count($myStyles) > 1 and $IsAutomaticStyle">
            <xsl:value-of
              select="ancestor::node()[(self::text:a or self::text:span) and @text:style-name][2]/@text:style-name"
            />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of
              select="ancestor::node()[(self::text:a or self::text:span) and @text:style-name][1]/@text:style-name"
            />
          </xsl:otherwise>
        </xsl:choose>-->
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@text:style-name"/>
      </xsl:otherwise>
    </xsl:choose>
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
    <xsl:variable name="textIndent">
      <xsl:if test=" following-sibling::text:note-body/text:p[1]/@text:style-name">
        <xsl:choose>
          <xsl:when
            test="key('styles', following-sibling::text:note-body/text:p[1]/@text:style-name)">
            <xsl:call-template name="GetFirstLineIndent">
              <xsl:with-param name="style"
                select="key('styles', following-sibling::text:note-body/text:p[1]/@text:style-name)"
              />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="noteStyle"
              select="following-sibling::text:note-body/text:p[1]/@text:style-name"/>
            <xsl:for-each select="document('styles.xml')">
              <xsl:call-template name="GetFirstLineIndent">
                <xsl:with-param name="style" select="key('styles', $noteStyle)"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="not($textIndent = 0)">
      <w:r>
        <w:tab/>
      </w:r>
    </xsl:if>
  </xsl:template>

  <!-- annotations -->
  <xsl:template match="office:annotation" mode="paragraph">
    <xsl:choose>

      <!--annotation embedded in text-box is not supported in Word-->
      <xsl:when test="ancestor::draw:text-box">
        <xsl:message terminate="no">translation.odf2oox.annotationsInsideTextbox</xsl:message>
      </xsl:when>
      <xsl:when
        test="ancestor::style:header or ancestor::style:header-left or ancestor::style:footer or ancestor::style:footer-left">
        <xsl:message terminate="no">translation.odf2oox.annotationsInsideHeaderFooter</xsl:message>
      </xsl:when>
      <!--default scenario-->
      <xsl:otherwise>
        <xsl:variable name="id">
          <xsl:call-template name="GenerateId">
            <xsl:with-param name="node" select="."/>
            <xsl:with-param name="nodetype" select="'annotation'"/>
          </xsl:call-template>
        </xsl:variable>
        <w:r>
          <xsl:call-template name="InsertRunProperties"/>
          <w:commentReference w:id="{$id}" />
        </w:r>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>


  <!-- links -->
  <xsl:template match="text:a" mode="paragraph">
    <xsl:choose>

      <!-- TOC hyperlink -->
      <xsl:when test="name(../..) = 'text:index-body'">

        <!--
        makz: new TOC Hyperlink Conversion
        -->
        <xsl:variable name="linkNr" select="count(../preceding-sibling::text:p) + 1"/>
        <w:hyperlink w:history="1" 
                     w:tooltip="{@office:title}"
                     w:anchor="{concat('Toc_', generate-id(ancestor::text:table-of-content), '_', $linkNr)}">
          <xsl:apply-templates mode="paragraph"/>
        </w:hyperlink>

      </xsl:when>

      <!--text body link-->
      <xsl:otherwise>
        <w:hyperlink r:id="{generate-id()}" w:history="1" w:tooltip="{@office:title}">
          <!-- warn loss of hyperlink properties -->
          <xsl:if test="@office:name">
            <xsl:message terminate="no">translation.odf2oox.hyperlinkName</xsl:message>
          </xsl:if>
          <xsl:if test="@text:visited-style-name">
            <xsl:message terminate="no">translation.odf2oox.visitedLinkStyle</xsl:message>
          </xsl:if>
          <xsl:if test="@office:target-frame-name">
            <xsl:attribute name="w:tgtFrame">
              <xsl:value-of select="@office:target-frame-name"/>
            </xsl:attribute>
          </xsl:if>

          <xsl:apply-templates mode="paragraph"/>
        </w:hyperlink>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <!-- lists -->
  <xsl:template match="text:list">
    <xsl:param name="level" select="-1"/>
    <xsl:apply-templates>
      <xsl:with-param name="level" select="$level+1"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- list items -->
  <xsl:template match="text:list-item|text:list-header">
    <xsl:param name="level"/>
    <xsl:choose>
      <xsl:when test="*[1][self::text:p or self::text:h]">
        <w:p>
          <xsl:call-template name="MarkMasterPage"/>
          <w:pPr>

            <!--
            makz: Do no longer insert the style name because the automatic style will 
                  be converted to paragraph properties.
            
            <xsl:call-template name="InsertParagraphStyle">
              <xsl:with-param name="styleName" select="*[1]/@text:style-name"/>
            </xsl:call-template>
            -->

            <!-- insert number -->
            <xsl:call-template name="InsertNumbering">
              <xsl:with-param name="level" select="$level"/>
            </xsl:call-template>

            <!-- insert bg color in case paragraph is in table-of-content -->
            <xsl:call-template name="InsertTOCBgColor"/>

            <!-- override abstract num indent and tab if paragraph has margin defined -->
            <xsl:call-template name="OverrideNumberingProperty">
              <xsl:with-param name="level" select="$level"/>
              <xsl:with-param name="property">indent</xsl:with-param>
            </xsl:call-template>

            <!-- insert heading outline level -->
            <xsl:call-template name="InsertOutlineLevel">
              <xsl:with-param name="node" select="*[1]"/>
            </xsl:call-template>

            <!-- insert page break before table when required -->
            <xsl:call-template name="InsertPageBreakBefore"/>

            <!--
            makz: context switch for-each to insert the paragraph properties
            divo: This must be the last properties defined. We ahve to define all overriden properties for lists first
                because OoxParagraphsPostProcessor only taks the first occurrence of a property into account. 
                Example: List formatting such as indent is defined by the templates above. Template InsertParagraphProperties also sets the list
                  indent, but this definition will be ignored in the postprocessor. What an awful design. But it wasnt me...
            -->
            <xsl:for-each select="*[1][self::text:p or self::text:h]">
              <xsl:call-template name="InsertParagraphProperties" />
            </xsl:for-each>

            <!-- 20081014/divo: Tab definitions and must follow last... -->
            <!-- insert tab stops if paragraph is in a list -->
            <xsl:call-template name="OverrideNumberingProperty">
              <xsl:with-param name="level" select="$level"/>
              <xsl:with-param name="property">tab</xsl:with-param>
            </xsl:call-template>

          </w:pPr>

          <!--TOC  -->
          <xsl:if test="$tocCount &gt; 0">
            <xsl:call-template name="InsertTOCBookmark">
              <xsl:with-param name="styleName" select="child::*[1]/@text:style-name"/>
            </xsl:call-template>
          </xsl:if>

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




  <!-- dealing with text next to shapes -->

  <xsl:template match="text()|text:s" mode="shapes">
    <!-- 2008-10-22/divo do nothing here to fix #2163354 ODT: Wrap around - tabs are lost-->
    <!--<xsl:if test="not(ancestor::draw:frame)">
      <xsl:apply-templates select="." mode="paragraph"/>
    </xsl:if>-->
  </xsl:template>

  <!-- text and spaces -->

  <xsl:template match="text()|text:s" mode="paragraph">
    <w:r>
      <xsl:call-template name="InsertRunProperties"/>
      <xsl:apply-templates select="." mode="text"/>
    </w:r>
  </xsl:template>


  <!--
  Summary:  Inserts the direct formatting of a run.
  Author:   CleverAge
  Modified: makz (DIaLOGIKa)
  Date:     30.09.2008
  -->
  <xsl:template name="InsertRunProperties">
    <w:rPr>
      <xsl:variable name="styleName">
        <xsl:call-template name="GetStyleName"/>
      </xsl:variable>
      <xsl:variable name="paraStyleName" select="ancestor-or-self::text:p[1]/@text:style-name" />
      <xsl:choose>
				<xsl:when test ="$styleName!=$paraStyleName or not($paraStyleName) ">
				<!--<xsl:when test ="$styleName!=''">-->
      <xsl:choose>
        <xsl:when test="key('automatic-styles', $styleName)">
          <!-- 
          makz: Add the parent style of the automatic style as style ref 
          -->
          <xsl:if test="key('automatic-styles', $styleName)/@style:parent-style-name">
            <w:rStyle w:val="{key('automatic-styles', $styleName)/@style:parent-style-name}" />
								<xsl:call-template name="InsertParagraphStyle">
              <xsl:with-param name="styleName">
                <xsl:value-of select="key('automatic-styles', $styleName)/@style:parent-style-name"/>
              </xsl:with-param>
								</xsl:call-template>
          </xsl:if>
          <!-- 
          makz: Convert the automatic style 
          -->
          <xsl:for-each select="key('automatic-styles', $styleName)">
                <xsl:apply-templates select="style:text-properties" mode="rPr">
                  <xsl:with-param name ="paraStylName">
                    <xsl:value-of select ="$paraStyleName"/>
                  </xsl:with-param>
                </xsl:apply-templates>
          </xsl:for-each>
							<xsl:if test="$styleName">
								<!-- normal style -->
								<xsl:call-template name="InsertRunStyle">
									<xsl:with-param name="styleName" select="$styleName" />
								</xsl:call-template>
							</xsl:if>
        </xsl:when>
        <xsl:when test="$styleName">
          <!-- normal style -->
          <xsl:call-template name="InsertRunStyle">
            <xsl:with-param name="styleName" select="$styleName" />
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
        </xsl:when>
				<xsl:when test ="$styleName = $paraStyleName">
					<xsl:choose>
						<xsl:when test ="(self::text:s or self::text:span or self::text:a or self::text:h or self::text:p)">
							<xsl:if test ="@text:style-name or (not(@text:style-name) and @text:c)">
							<!--<xsl:if test ="@text:style-name">-->
          <xsl:if test="key('automatic-styles', $paraStyleName)">
            <!-- context switch -->
            <xsl:for-each select="key('automatic-styles', $paraStyleName)">
              <xsl:apply-templates select="style:text-properties" mode="rPr"/>
            </xsl:for-each>
          </xsl:if>
					<xsl:choose>
						<xsl:when test="key('automatic-styles', $styleName)">
							<xsl:if test="key('automatic-styles', $styleName)/@style:parent-style-name">
								<w:rStyle w:val="{key('automatic-styles', $styleName)/@style:parent-style-name}" />
							</xsl:if>
										<!--<xsl:for-each select="key('automatic-styles', $styleName)">
											<xsl:apply-templates select="style:text-properties" mode="rPr"/>
										</xsl:for-each>-->
									</xsl:when>
									<xsl:when test="$styleName">
										<xsl:call-template name="InsertRunStyle">
											<xsl:with-param name="styleName" select="$styleName" />
										</xsl:call-template>
									</xsl:when>
								</xsl:choose>
							</xsl:if>
						</xsl:when>
						<xsl:when test =".!='' and 
								         not(self::text:s or self::text:span or self::text:a or self::text:h or self::text:p)">
							<xsl:if test="key('automatic-styles', $paraStyleName)">
								<!-- context switch -->
								<xsl:for-each select="key('automatic-styles', $paraStyleName)">
								<xsl:apply-templates select="style:text-properties" mode="rPr"/>
							</xsl:for-each>
							</xsl:if>
							<xsl:choose>
								<xsl:when test="key('automatic-styles', $styleName)">
									<xsl:if test="key('automatic-styles', $styleName)/@style:parent-style-name">
										<w:rStyle w:val="{key('automatic-styles', $styleName)/@style:parent-style-name}" />
									</xsl:if>
									<!--<xsl:for-each select="key('automatic-styles', $styleName)">
										<xsl:apply-templates select="style:text-properties" mode="rPr"/>
									</xsl:for-each>-->
						</xsl:when>
						<xsl:when test="$styleName">
							<xsl:call-template name="InsertRunStyle">
								<xsl:with-param name="styleName" select="$styleName" />
							</xsl:call-template>
						</xsl:when>
					</xsl:choose>
        </xsl:when>
      </xsl:choose>
				</xsl:when>
			</xsl:choose>
      <!--
        makz: If the parent paragraph has an automatic style we must convert it's text formatting.
        This must be done before converting the properties of the run's automatic style due to the priority
      -->
     

      <!-- 
      makz: Convert the automatic style of the run to direct formatting.
            If the run's referenced style is no automatic style, 
            it is a normal style, so we need to reference it.
      -->
     

      <!-- apply text properties if needed -->
      <!-- test description : if there is an ancestor text:span or text:a,
      and that the first ancestor to come is not a text:p or text:h
    or if we are in a list-->
      <xsl:if
        test="ancestor-or-self::*[self::text:span or self::text:a or self::text:p or self::text:h][1][self::text:span or self::text:a]
      or self::text:list-level-style-number|self::text:outline-level-style">
        <!-- override text properties of link -->
        <xsl:if test="ancestor::text:a/@text:style-name">
          <xsl:variable name="linkStyleName" select="parent::text:a/@text:style-name"/>
          <xsl:for-each select="document('styles.xml')">
            <xsl:apply-templates select="key('styles', $linkStyleName)/style:text-properties"
              mode="rPr"/>
          </xsl:for-each>
        </xsl:if>

      </xsl:if>
    </w:rPr>
  </xsl:template>

  <!-- Inserts the style of a run -->
  <xsl:template name="InsertRunStyle">
    <xsl:param name="styleName"/>
    <xsl:variable name="prefixedStyleName">
      <xsl:call-template name="GetPrefixedStyleName">
        <xsl:with-param name="styleName" select="$styleName"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="myStyle" select="key('automatic-styles', $styleName)" />

    <xsl:choose>
      <xsl:when test="$myStyle[1]/style:text-properties/@style:use-window-font-color = 'true' and $myStyle[1]/style:text-properties/@style:text-underline-type = 'none'">
        <!--dialogika, clam bugfix #1806204: don't set a style-->
      </xsl:when>
      <xsl:when test="$prefixedStyleName!='' and not(parent::text:a/@text:style-name)">
        <w:rStyle w:val="{$prefixedStyleName}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="ancestor::text:a">
          <w:rStyle w:val="Hyperlink"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- spaces (within a text flow) -->
  <xsl:template match="text:s" mode="text">
    <w:t>
      <pxs:s xmlns:pxs="urn:cleverage:xmlns:post-processings:extra-spaces">
        <xsl:if test="@text:c">
          <xsl:attribute name="pxs:c">
            <xsl:value-of select="@text:c"/>
          </xsl:attribute>
        </xsl:if>
      </pxs:s>
    </w:t>
  </xsl:template>

  <!-- simple text (within a text flow) -->
  <xsl:template match="text()" mode="text">
    <xsl:choose>
      <xsl:when test="ancestor::text:index-body">
        <xsl:apply-templates select="." mode="indexes"/>
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
    <xsl:choose>
      <xsl:when test="ancestor::text:index-body and ((preceding-sibling::text:a or parent::text:a) and preceding-sibling::text:tab)">
        <!-- do nothing : only one tab-stop converted in indexes -->
      </xsl:when>
      <xsl:when test="../../@text:style-name = 'X3AS7TABSTYLE'">
        <w:rPr>
          <w:noProof />
          <w:webHidden />
        </w:rPr>
        <w:ptab w:relativeTo="margin" w:alignment="right" w:leader="none"/>
      </xsl:when>
      <xsl:otherwise>
        <w:r>
          <w:rPr>
            <w:noProof/>
            <w:webHidden/>
          </w:rPr>
          <w:tab/>
        </w:r>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- line breaks -->
  <xsl:template match="text:line-break" mode="paragraph">
    <w:r>
      <xsl:call-template name="InsertRunProperties"/>
      <w:br/>
      <w:t/>
    </w:r>
  </xsl:template>

  <!-- line breaks (within the text flow) -->
  <xsl:template match="text:line-break" mode="text">
    <w:br/>
  </xsl:template>

  <!-- column break before -->
  <!-- context must be text:p; break if preceding paragraph or table has break-before, and no break before if first paragraph -->
  <xsl:template name="InsertColumnBreakBefore">
    <xsl:if test="preceding-sibling::text:p">
      <xsl:choose>
        <!-- if break-before property -->
        <xsl:when
          test="key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-before='column' ">
          <w:r>
            <w:br w:type="column"/>
          </w:r>
        </xsl:when>
        <!-- if preceding is a list whose last element has break-after -->
        <xsl:when
          test="preceding-sibling::node()[1][self::text:list and descendant::node()[last()][(self::text:p or self::text:h) and key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='column' ]]">
          <w:r>
            <w:br w:type="column"/>
          </w:r>
        </xsl:when>
        <!-- if preceding is a table with break-after property -->
        <xsl:when
          test="preceding-sibling::node()[1][self::table:table and key('automatic-styles',@table:name)/style:table-properties/@fo:break-after='column' ]">
          <w:r>
            <w:br w:type="column"/>
          </w:r>
        </xsl:when>
        <!-- if preceding paragraph has break-after property -->
        <xsl:when
          test="preceding-sibling::node()[1][(self::text:p or self::text:h) and key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='column' ]">
          <w:r>
            <w:br w:type="column"/>
          </w:r>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="styleName" select="@text:style-name"/>
          <xsl:variable name="precStyleName" select="preceding-sibling::node()[1][self::text:p or self::text:h]/@text:style-name"/>
          
          <xsl:for-each select="document('styles.xml')">
            <xsl:if test="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:break-before='column' 
                       or key('automatic-styles',$precStyleName)/style:paragraph-properties/@fo:break-after='column' ">
              <w:r>
                <w:br w:type="column"/>
              </w:r>
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- column break after -->
  <!-- context must be text:p -->
  <xsl:template name="InsertColumnBreakAfter">
    <xsl:choose>
      <!-- if following is a list whose first element has break-before -->
      <xsl:when
        test="following-sibling::node()[1][self::text:list and descendant::node()[1][(self::text:p or self::text:h) and key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-before='column' ]]">
        <w:r>
          <w:br w:type="column"/>
        </w:r>
      </xsl:when>
      <!-- if following is a table with break-before property -->
      <xsl:when
        test="following-sibling::node()[1][self::table:table and key('automatic-styles',@table:name)/style:table-properties/@fo:break-before='column' ]">
        <w:r>
          <w:br w:type="column"/>
        </w:r>
      </xsl:when>
      <xsl:otherwise>
        <!-- if not last paragraph -->
        <xsl:if test="following-sibling::node()[1][not(self::text:p or self::text:h)]">
          <xsl:choose>
            <xsl:when
              test="key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='column' ">
              <w:r>
                <w:br w:type="column"/>
              </w:r>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="styleName" select="@text:style-name"/>
              <xsl:for-each select="document('styles.xml')">
                <xsl:if
                  test="key('automatic-styles',$styleName)/style:paragraph-properties/@fo:break-after='column' ">
                  <w:r>
                    <w:br w:type="column"/>
                  </w:r>
                </xsl:if>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- notes (footnotes or endnotes) -->
  <xsl:template match="text:note" mode="paragraph">
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{concat(@text:note-class, 'Reference')}"/>
        <!-- COMMENT : why this color as a direct formatting property here ? -->
        <xsl:variable name="fo:color" select="substring-after(key('automatic-styles', parent::text:span/@text:style-name)/style:text-properties/@fo:color,'#')"/>
        <xsl:if test="$fo:color">
          <w:color w:val="{$fo:color}"/>
        </xsl:if>
      </w:rPr>
      <xsl:apply-templates select="." mode="text"/>
    </w:r>
  </xsl:template>


  <!-- spaces -->
  <!--xsl:template match="text:s">
    <xsl:call-template name="extra-spaces">
      <xsl:with-param name="spaces" select="@text:c"/>
    </xsl:call-template>
  </xsl:template-->

  <!-- sequences used for index of tables, index of illustrations -->
  <xsl:template match="text:sequence" mode="paragraph">
    <xsl:variable name="numType">
      <xsl:call-template name="GetNumberFormattingSwitch"/>
    </xsl:variable>

    <w:fldSimple w:instr="{concat('SEQ ', @text:name,' ', $numType)}">
      <xsl:call-template name="InsertIndexOfFiguresBookmark"/>
    </w:fldSimple>
  </xsl:template>

  <!-- Sections -->
  <!-- Hidden sections -->
  <xsl:template match="text:section[@text:display = 'none' ]" priority="3">
    <xsl:message terminate="no">translation.odf2oox.hiddenSection</xsl:message>
  </xsl:template>

  <!-- Conditional hidden sections -->
  <xsl:template match="text:section[@text:is-hidden = 'true' ]" priority="3">
    <xsl:message terminate="no">translation.odf2oox.conditionalHiddenSection</xsl:message>
  </xsl:template>

  <!-- Protected sections -->
  <xsl:template match="text:section[@text:protected = 'true' ]" priority="2">
    <xsl:if test="@text:protection-key">
      <xsl:message terminate="no">
        translation.odf2oox.protectionKey%<xsl:value-of
          select="@text:name"/>
      </xsl:message>
    </xsl:if>
    <xsl:choose>
      <!-- in a read-only odf document : grant permission not needed -->
      <xsl:when test="boolean($load-readonly)">
        <xsl:apply-templates/>
      </xsl:when>
      <!-- in a read-write odf document -->
      <xsl:otherwise>
        <!-- permission range id's added in a post processing step -->
        <w:permEnd/>
        <xsl:apply-templates/>
        <w:permStart w:edGrp="everyone"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Editable sections -->
  <xsl:template match="text:section[key('automatic-styles', @text:style-name)[1]/style:section-properties/@style:editable = 'true']" priority="1">
    <!--  in a read-only document : grant permission -->
    <xsl:choose>
      <xsl:when test="boolean($load-readonly)">
        <!-- permission range id's added in a post processing step -->
        <w:permStart w:edGrp="everyone"/>
        <xsl:apply-templates/>
        <w:permEnd/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Basic sections -->
  <xsl:template match="text:section">
    <xsl:choose>
      <xsl:when test="$protected-sections[1] and not(boolean($load-readonly))">
        <w:permStart w:edGrp="everyone"/>
        <xsl:apply-templates/>
        <w:permEnd/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <!-- Find potential drop cap properties into this element's style hierarchy  -->
  <xsl:template name="InsertDropCap">
    <xsl:param name="styleName"/>
    <xsl:param name="context">
      <xsl:choose>
        <xsl:when test="/office:document-styles">styles.xml</xsl:when>
        <xsl:otherwise>content.xml</xsl:otherwise>
      </xsl:choose>
    </xsl:param>

    <xsl:variable name="exists">
      <xsl:for-each select="document($context)">
        <xsl:value-of select="boolean(key('styles', $styleName))"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$exists = 'true' ">
        <xsl:for-each select="document($context)">
          <xsl:choose>
            <xsl:when test="key('styles', $styleName)[1]/style:paragraph-properties/style:drop-cap">
              <xsl:call-template name="InsertDropCapAttributes">
                <xsl:with-param name="dropcap"
                  select="key('styles', $styleName)[1]/style:paragraph-properties/style:drop-cap"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="key('styles', $styleName)[1]/@style:parent-style-name">
              <xsl:if test="key('styles', $styleName)[1]/@style:parent-style-name != $styleName">
                <xsl:call-template name="InsertDropCap">
                  <xsl:with-param name="styleName"
                    select="key('styles', $styleName)[1]/@style:parent-style-name"/>
                  <xsl:with-param name="context" select="$context"/>
                </xsl:call-template>
              </xsl:if>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$context != 'styles.xml'">
        <xsl:call-template name="InsertDropCap">
          <xsl:with-param name="styleName" select="$styleName"/>
          <xsl:with-param name="context" select="'styles.xml'"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>



  <xsl:template name="InsertDropCapAttributes">
    <xsl:param name="dropcap"/>
    <xsl:message terminate="no">translation.odf2oox.dropcapSize</xsl:message>

    <!-- if @style:lines is 0 or 1 dropcap is disabled -->
    <xsl:if test="$dropcap[@style:lines &gt; 1]">
      <xsl:attribute name="dropcap:lines" namespace="urn:cleverage:xmlns:post-processings:dropcap">
        <xsl:value-of select="$dropcap/@style:lines"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="number($dropcap/@style:length)">
          <xsl:attribute name="dropcap:length"
            namespace="urn:cleverage:xmlns:post-processings:dropcap">
            <xsl:value-of select="$dropcap/@style:length"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$dropcap/@style:length = 'word' ">
          <xsl:attribute name="dropcap:word"
            namespace="urn:cleverage:xmlns:post-processings:dropcap">true</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="dropcap:length"
            namespace="urn:cleverage:xmlns:post-processings:dropcap">1</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="$dropcap/@style:distance">
        <xsl:attribute name="dropcap:distance" namespace="urn:cleverage:xmlns:post-processings:dropcap">
          <xsl:value-of select="ooc:TwipsFromMeasuredUnit($dropcap/@style:distance)" />
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$dropcap/@style:style-name">
        <xsl:attribute name="dropcap:style-name" namespace="urn:cleverage:xmlns:post-processings:dropcap">
          <xsl:value-of select="$dropcap/@style:style-name"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:if>
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
  <xsl:template match="office:change-info"/>


</xsl:stylesheet>
