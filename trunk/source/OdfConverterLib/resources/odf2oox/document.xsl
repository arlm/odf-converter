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
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="office text table fo style draw xlink v svg number"
  xmlns:w10="urn:schemas-microsoft-com:office:word">

  <xsl:import href="tables.xsl"/>
  <xsl:import href="indexes.xsl"/>
  <xsl:import href="bookmarks.xsl"/>

  <xsl:strip-space elements="*"/>
  <xsl:preserve-space elements="text:p"/>
  <xsl:preserve-space elements="text:span"/>

  <xsl:key name="annotations" match="office:annotation" use="''"/>
  <xsl:key name="automatic-styles" match="office:automatic-styles/style:style" use="@style:name"/>
  <xsl:key name="hyperlinks" match="text:a" use="''"/>
  <xsl:key name="headers" match="text:h" use="''"/>
  <xsl:key name="Index" match="style:style" use="@style:name"/>
  <xsl:key name="restarting-lists" match="text:list[text:list-item/@text:start-value]" use="''"/>


  <!-- key to find mailto hyperlinks. -->
  <xsl:key name="mailto-hyperlinks" match="text:a[contains(@xlink:href,'mailto')]"
    use="text:span/@text:style-name"/>


  <xsl:variable name="body" select="document('content.xml')/office:document-content/office:body"/>
  <!-- table of content count -->
  <xsl:variable name="tocCount" select="count($body//text:table-of-content)"/>

  <!-- main document -->
  <xsl:template name="document">
    <w:document>
      <!-- Translate the default master page color as the document background color -->
      <xsl:for-each select="document('styles.xml')">
        <xsl:variable name="defaultBgColor"
          select="key('page-layouts', $default-master-style/@style:page-layout-name)[1]/style:page-layout-properties/@fo:background-color"/>
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
      <xsl:apply-templates/>
      <xsl:call-template name="InsertDocumentFinalSectionProperties"/>
    </w:body>
  </xsl:template>


  <!-- paragraphs and headings -->
  <xsl:template match="text:p | text:h">
    <xsl:param name="level" select="0"/>
    <xsl:message terminate="no">progress:text:p</xsl:message>
    <w:p>
      <xsl:call-template name="MarkMasterPage"/>
      <w:pPr>
        <xsl:call-template name="InsertParagraphProperties">
          <xsl:with-param name="level" select="$level"/>
        </xsl:call-template>
        <xsl:call-template name="InsertParagraphSectionProperties"/>
      </w:pPr>

      <!--   insert bookmark for element which is contained in TOC-->
      <xsl:if test="$tocCount &gt; 0">
        <xsl:call-template name="InsertTOCBookmark"/>
      </xsl:if>

      <!-- footnotes or endnotes: insert the mark in the first paragraph -->
      <xsl:if test="parent::text:note-body and position() = 1">
        <xsl:apply-templates select="../../text:note-citation" mode="note"/>
      </xsl:if>

      <!-- paragraph content-->
      <xsl:call-template name="InsertParagraphContent"/>

      <!-- If there is a page-break-after in the paragraph style -->
      <xsl:call-template name="InsertPageBreakAfter"/>
    </w:p>
  </xsl:template>


  <!-- conversion of paragraph content excluding not supported elements -->
  <xsl:template name="InsertParagraphContent">
    <xsl:choose>

      <!-- we are in table of contents -->
      <xsl:when test="parent::text:index-body">
        <xsl:call-template name="InsertIndexItem"/>
      </xsl:when>

      <!-- ignore draw:frame/draw:text-box if it's embedded in another draw:frame/draw:text-box becouse word doesn't support it -->
      <xsl:when test="self::node()[ancestor::draw:text-box and descendant::draw:text-box]">
        <xsl:message terminate="no">feedback:Nested frames</xsl:message>
      </xsl:when>

      <!-- drawing shapes -->
      <xsl:when
        test="child::draw:ellipse|child::draw:rect|child::draw:custom-shape|child::draw:frame">
        <xsl:if test="child::draw:frame">
          <xsl:apply-templates mode="paragraph"/>
        </xsl:if>
        <xsl:if test="child::draw:ellipse|child::draw:rect|child::draw:custom-shape">
          <xsl:apply-templates mode="shapes"/>
        </xsl:if>
      </xsl:when>

      <xsl:otherwise>
        <xsl:apply-templates mode="paragraph"/>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <!-- inserts page-break-after if defined for paragraph  -->
  <xsl:template name="InsertPageBreakAfter">
    <xsl:if
      test="key('automatic-styles',@text:style-name)/style:paragraph-properties/@fo:break-after='page'">
      <w:r>
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:rPr>
            <w:vanish/>
          </w:rPr>
        </xsl:if>
        <w:br w:type="page"/>
      </w:r>
    </xsl:if>
  </xsl:template>




  <!-- Inserts the paragraph properties -->
  <xsl:template name="InsertParagraphProperties">
    <xsl:param name="level"/>

    <!-- insert paragraph style -->
    <xsl:call-template name="InsertParagraphStyle">
      <xsl:with-param name="styleName">
        <xsl:value-of select="@text:style-name"/>
      </xsl:with-param>
    </xsl:call-template>

    <!-- insert page break before table when required -->
    <xsl:call-template name="InsertPageBreakBefore"/>

    <!-- insert numbering properties -->
    <xsl:call-template name="InsertNumbering">
      <xsl:with-param name="level" select="$level"/>
    </xsl:call-template>

    <!-- line numbering -->
    <xsl:call-template name="InsertSupressLineNumbers"/>

    <!-- override spacing before/after when required -->
    <xsl:call-template name="InsertParagraphSpacing"/>

    <!-- insert indentation if paragraph is in a list -->
    <xsl:call-template name="InsertIndent">
      <xsl:with-param name="level" select="$level"/>
    </xsl:call-template>

    <!-- insert heading outline level -->
    <xsl:call-template name="InsertOutlineLevel">
      <xsl:with-param name="node" select="."/>
    </xsl:call-template>


    <!-- if we are in an annotation, we may have to insert annotation reference -->
    <xsl:call-template name="InsertAnnotationReference"/>

    <!-- insert run properties -->
    <xsl:call-template name="InsertRunProperties"/>

    <!-- picture in a frame -->
    <xsl:call-template name="InsertPicturePropertiesInFrame"/>


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


  <!-- Insert spacing in paragraph properties if table before/after w:p element has spacing after/before -->
  <xsl:template name="InsertParagraphSpacing">
    <xsl:if
      test="following-sibling::node()[1][name()='table:table'] or preceding-sibling::node()[1][name()='table:table']">
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
      <xsl:if test="$spaceBefore &gt; 0 or $spaceAfter &gt; 0">
        <w:spacing>
          <xsl:if test="$spaceBefore &gt; 0">
            <xsl:attribute name="w:before">
              <xsl:value-of select="$spaceBefore"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="$spaceAfter &gt; 0">
            <xsl:attribute name="w:after">
              <xsl:value-of select="$spaceAfter"/>
            </xsl:attribute>
          </xsl:if>
        </w:spacing>
      </xsl:if>
    </xsl:if>
  </xsl:template>






  <!-- Computes the style name to be used be InsertIndent template -->
  <xsl:template name="GetStyleName">
    <xsl:choose>
      <xsl:when test="self::text:list-item|self::text:list-header">
        <xsl:value-of select="*[1][self::text:p]/@text:style-name"/>
      </xsl:when>
      <xsl:when
        test="parent::text:list-header|self::text:p|self::text:h|self::text:list-level-style-number|self::text:outline-level-style">
        <xsl:value-of select="@text:style-name"/>
      </xsl:when>
      <xsl:when test="parent::text:p|parent::text:h">
        <xsl:value-of select="parent::node()/@text:style-name"/>
      </xsl:when>
      <xsl:when test="ancestor::text:span">
        <xsl:value-of select="ancestor::text:span[1]/@text:style-name"/>
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
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:rPr>
            <w:vanish/>
          </w:rPr>
        </xsl:if>
        <w:annotationRef/>
      </w:r>
    </xsl:if>
  </xsl:template>

  <!-- note marks -->
  <xsl:template match="text:note-citation" mode="note">
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{concat(../@text:note-class, 'Reference')}"/>
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:vanish/>
        </xsl:if>
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
      <xsl:if test="ancestor::text:section/@text:display='none'">
        <w:rPr>
          <w:vanish/>
        </w:rPr>
      </xsl:if>
      <w:tab/>
    </w:r>
  </xsl:template>

  <!-- annotations -->
  <xsl:template match="office:annotation" mode="paragraph">
    <xsl:choose>

      <!--annotation embedded in text-box is not supported in Word-->
      <xsl:when test="ancestor::draw:text-box">
        <xsl:message terminate="no">feedback:Annotations in text-box</xsl:message>
      </xsl:when>
      <xsl:when
        test="ancestor::style:header or ancestor::style:header-left or ancestor::style:footer or ancestor::style:footer-left">
        <xsl:message terminate="no">feedback:Annotations in header or footer</xsl:message>
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
          <w:commentReference>
            <xsl:attribute name="w:id">
              <xsl:value-of select="$id"/>
            </xsl:attribute>
          </w:commentReference>
        </w:r>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- links -->
  <xsl:template match="text:a" mode="paragraph">
    <xsl:choose>
      <!-- TOC hyperlink -->
      <xsl:when test="ancestor::text:index-body and position() = 1">
        <xsl:variable name="tocId" select="count(../preceding-sibling::text:p)+1"/>
        <w:hyperlink w:history="1">
          <xsl:attribute name="w:anchor">
            <xsl:value-of
              select="concat('_Toc',$tocId,generate-id(ancestor::text:table-of-content))"/>
          </xsl:attribute>
          <xsl:call-template name="InsertIndexItemContent">
            <xsl:with-param name="tocId" select="$tocId"/>
          </xsl:call-template>
        </w:hyperlink>
      </xsl:when>

      <!--text body link-->
      <xsl:otherwise>
        <w:hyperlink r:id="{generate-id()}">
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
          <w:pPr>

            <!-- insert style -->
            <xsl:call-template name="InsertParagraphStyle">
              <xsl:with-param name="styleName" select="*[1]/@text:style-name"/>
            </xsl:call-template>

            <!-- insert number -->
            <xsl:call-template name="InsertNumbering">
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
    <xsl:if test="not(ancestor::draw:frame)">
      <xsl:apply-templates select="." mode="paragraph"/>
    </xsl:if>
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
    <xsl:choose>
      <xsl:when
        test="ancestor::text:span|ancestor::text:a|self::text:list-level-style-number|self::text:outline-level-style">
        <w:rPr>
          <xsl:call-template name="InsertRunStyle">
            <xsl:with-param name="styleName">
              <xsl:call-template name="GetStyleName"/>
            </xsl:with-param>
          </xsl:call-template>
          <xsl:if test="ancestor::text:section/@text:display='none'">
            <w:vanish/>
          </xsl:if>
        </w:rPr>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:rPr>
            <w:vanish/>
          </w:rPr>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Inserts the style of a run -->
  <xsl:template name="InsertRunStyle">
    <xsl:param name="styleName"/>
    <xsl:variable name="prefixedStyleName">
      <xsl:call-template name="GetPrefixedStyleName">
        <xsl:with-param name="styleName" select="$styleName"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$prefixedStyleName!=''">
        <w:rStyle w:val="{$prefixedStyleName}"/>
      </xsl:when>
      <xsl:when test="ancestor::text:a">
        <w:rStyle w:val="Hyperlink"/>
      </xsl:when>
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
            <xsl:choose>
              <xsl:when test="not(ancestor::text:a)">
                <w:t xml:space="preserve"><xsl:value-of select="."/></w:t>
              </xsl:when>
              <xsl:otherwise>
                <w:t>
                  <xsl:value-of select="ancestor::text:p/text()"/>
                </w:t>
              </xsl:otherwise>
            </xsl:choose>
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
      <xsl:if test="ancestor::text:section/@text:display='none'">
        <w:vanish/>
      </xsl:if>
      <w:tab/>
      <w:t/>
    </w:r>
  </xsl:template>

  <!-- tabs -->
  <xsl:template match="text:tab" mode="paragraph">
    <w:r>
      <w:rPr>
        <w:noProof/>
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:vanish/>
        </xsl:if>
        <w:webHidden/>
      </w:rPr>
      <w:tab/>
    </w:r>
  </xsl:template>

  <!-- line breaks -->
  <xsl:template match="text:line-break" mode="paragraph">
    <w:r>
      <xsl:if test="ancestor::text:section/@text:display='none'">
        <w:rPr>
          <w:vanish/>
        </w:rPr>
      </xsl:if>
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
        <!-- COMMENT : why this color as a direct formatting property here ? -->
        <xsl:variable name="fo:color"
          select="substring-after(key('automatic-styles', parent::text:span/@text:style-name)/style:text-properties/@fo:color,'#')"/>
        <xsl:if test="$fo:color">
          <w:color w:val="{$fo:color}"/>
        </xsl:if>
        <xsl:if test="ancestor::text:section/@text:display='none'">
          <w:vanish/>
        </xsl:if>
      </w:rPr>
      <xsl:apply-templates select="." mode="text"/>
    </w:r>
  </xsl:template>


  <!-- spaces -->
  <xsl:template match="text:s">
    <xsl:call-template name="extra-spaces">
      <xsl:with-param name="spaces" select="@text:c"/>
    </xsl:call-template>
  </xsl:template>

  <!-- sequences used for index of tables, index of illustrations -->
  <xsl:template match="text:sequence" mode="paragraph">
    <w:fldSimple>
      <xsl:call-template name="InsertSequenceFieldNumType"/>
      <xsl:call-template name="InsertIndexOfFiguresBookmark"/>
    </w:fldSimple>
  </xsl:template>


  <!-- sections -->
  <xsl:template match="text:section">
    <xsl:message terminate="no">progress:text:section</xsl:message>
    <xsl:if test="@text:display='none'">
      <xsl:message terminate="no">feedback:Hidden section</xsl:message>
    </xsl:if>
    <xsl:apply-templates/>
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
