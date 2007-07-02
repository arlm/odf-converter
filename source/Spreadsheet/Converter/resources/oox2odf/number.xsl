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
  xmlns:e="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" exclude-result-prefixes="e">
  
  <xsl:template match="e:numFmt" mode="automaticstyles">
    
    <!-- @Descripition: inserts number format style -->
    <!-- @Context: None -->
    
    <xsl:variable name="formatingMarks">
      <xsl:call-template name="StripText">
        <xsl:with-param name="formatCode" select="@formatCode"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
      
      <!-- date style -->
      <xsl:when
        test="(contains($formatingMarks,'y') or (contains($formatingMarks,'m') and not(contains($formatingMarks,'h') or contains($formatingMarks,'s')))or (contains($formatingMarks,'d') and not(contains($formatingMarks,'Red'))))">
        <number:date-style style:name="{generate-id(.)}">
          <xsl:call-template name="ProcessFormat">
            <xsl:with-param name="format">
              <xsl:choose>
                <xsl:when test="contains(@formatCode,']')">
                  <xsl:value-of select="substring-after(@formatCode,']')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@formatCode"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="processedFormat">
              <xsl:choose>
                <xsl:when test="contains(@formatCode,']')">
                  <xsl:value-of select="substring-after(@formatCode,']')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@formatCode"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </number:date-style>
      </xsl:when>
      
      <!-- time style -->
      <!-- 'and' at the end is for latvian currency -->
      <xsl:when test="contains($formatingMarks,'h') or contains($formatingMarks,'s') and not(contains($formatingMarks, '$Ls-426' ))">
        <number:time-style style:name="{generate-id(.)}">
          <xsl:if test="contains($formatingMarks,'[h')">
            <xsl:attribute name="number:truncate-on-overflow">false</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="ProcessFormat">
            <xsl:with-param name="format">
              <xsl:choose>
                <xsl:when test="contains(@formatCode,'[h')">
                  <xsl:value-of select="translate(translate(@formatCode,'[h','h'),']','')"/>
                </xsl:when>
                <xsl:when test="contains(@formatCode,']')">
                  <xsl:value-of select="substring-after(@formatCode,']')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@formatCode"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="processedFormat">
              <xsl:choose>
                <xsl:when test="contains(@formatCode,'[h')">
                  <xsl:value-of select="translate(translate(@formatCode,'[h','h'),']','')"/>
                </xsl:when>
                <xsl:when test="contains(@formatCode,']')">
                  <xsl:value-of select="substring-after(@formatCode,']')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="@formatCode"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
          </xsl:call-template>
        </number:time-style>
      </xsl:when>
      
      <!-- when there are different formats for positive and negative numbers -->
      <xsl:when
        test="contains(@formatCode,';') and not(contains(substring-after(@formatCode,';'),';'))">
        <xsl:choose>

          <!-- currency style -->
          <xsl:when
            test="contains(substring-before(@formatCode,';'),'$') or contains(substring-before(@formatCode,';'),'zł') or contains(substring-before(@formatCode,';'),'€') or contains(substring-before(@formatCode,';'),'£')">
            <number:currency-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:currency-style>
            <number:currency-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-after(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
              <style:map style:condition="value()&gt;=0"
                style:apply-style-name="{concat(generate-id(.),'P0')}"/>
            </number:currency-style>
          </xsl:when>

          <!--percentage style -->
          <xsl:when test="contains(substring-before(@formatCode,';'),'%')">
            <number:percentage-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
              <number:text>%</number:text>
            </number:percentage-style>
            <number:percentage-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-after(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
              <number:text>%</number:text>
              <style:map style:condition="value()&gt;=0"
                style:apply-style-name="{concat(generate-id(.),'P0')}"/>
            </number:percentage-style>
          </xsl:when>

          <!-- number style -->
          <xsl:otherwise>
            <number:number-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:number-style>
            <number:number-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-after(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
              <style:map style:condition="value()&gt;=0"
                style:apply-style-name="{concat(generate-id(.),'P0')}"/>
            </number:number-style>
          </xsl:otherwise>

        </xsl:choose>
      </xsl:when>

      <!-- when there are separate formats for positive numbers, negative numbers and zeros -->
      <xsl:when test="contains(@formatCode,';') and contains(substring-after(@formatCode,';'),';')">
        <xsl:choose>

          <!-- currency style -->
          <xsl:when
            test="contains(substring-before(@formatCode,';'),'$') or contains(substring-before(@formatCode,';'),'zł') or contains(substring-before(@formatCode,';'),'€') or contains(substring-before(@formatCode,';'),'£')">
            <number:currency-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:currency-style>
            <number:currency-style style:name="{concat(generate-id(.),'P1')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(substring-after(@formatCode,';'),';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:currency-style>

            <xsl:choose>
              <xsl:when test="contains(substring-after(substring-after(@formatCode,';'),';'),';')">
                <number:currency-style style:name="{concat(generate-id(.),'P2')}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of
                        select="substring-before(substring-after(substring-after(@formatCode,';'),';'),';')"
                      />
                    </xsl:with-param>
                  </xsl:call-template>
                </number:currency-style>
                <number:text-style style:name="{generate-id(.)}">
                  <xsl:variable name="text">
                    <xsl:value-of
                      select="substring-after(substring-after(substring-after(@formatCode,';'),';'),';')"
                    />
                  </xsl:variable>
                  <xsl:choose>

                    <!-- text content -->
                    <xsl:when test="contains($text,'@')">
                      <number:text>
                        <xsl:value-of select="translate(substring-before($text,'@'),'_-',' ')"/>
                      </number:text>
                      <number:text-content/>
                      <number:text>
                        <xsl:value-of select="translate(substring-after($text,'@'),'_-',' ')"/>
                      </number:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="translate($text,'_-',' ')"/>
                    </xsl:otherwise>
                  </xsl:choose>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                  <style:map style:condition="value()=0"
                    style:apply-style-name="{concat(generate-id(.),'P2')}"/>
                </number:text-style>
              </xsl:when>
              <xsl:otherwise>
                <number:currency-style style:name="{generate-id(.)}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of select="substring-after(substring-after(@formatCode,';'),';')"/>
                    </xsl:with-param>
                  </xsl:call-template>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                </number:currency-style>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <!-- percentage style -->
          <xsl:when test="contains(substring-before(@formatCode,';'),'%')">
            <number:percentage-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:percentage-style>
            <number:percentage-style style:name="{concat(generate-id(.),'P1')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(substring-after(@formatCode,';'),';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:percentage-style>

            <xsl:choose>
              <xsl:when test="contains(substring-after(substring-after(@formatCode,';'),';'),';')">
                <number:percentage-style style:name="{concat(generate-id(.),'P2')}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of
                        select="substring-before(substring-after(substring-after(@formatCode,';'),';'),';')"
                      />
                    </xsl:with-param>
                  </xsl:call-template>
                </number:percentage-style>
                <number:text-style style:name="{generate-id(.)}">
                  <xsl:variable name="text">
                    <xsl:value-of
                      select="substring-after(substring-after(substring-after(@formatCode,';'),';'),';')"
                    />
                  </xsl:variable>
                  <xsl:choose>

                    <!-- text content -->
                    <xsl:when test="contains($text,'@')">
                      <number:text>
                        <xsl:value-of select="translate(substring-before($text,'@'),'_-',' ')"/>
                      </number:text>
                      <number:text-content/>
                      <number:text>
                        <xsl:value-of select="translate(substring-after($text,'@'),'_-',' ')"/>
                      </number:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="translate($text,'_-',' ')"/>
                    </xsl:otherwise>
                  </xsl:choose>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                  <style:map style:condition="value()=0"
                    style:apply-style-name="{concat(generate-id(.),'P2')}"/>
                </number:text-style>
              </xsl:when>
              <xsl:otherwise>
                <number:percentage-style style:name="{generate-id(.)}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of select="substring-after(substring-after(@formatCode,';'),';')"/>
                    </xsl:with-param>
                  </xsl:call-template>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                </number:percentage-style>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <!-- number style -->
          <xsl:otherwise>
            <number:number-style style:name="{concat(generate-id(.),'P0')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(@formatCode,';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:number-style>
            <number:number-style style:name="{concat(generate-id(.),'P1')}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="substring-before(substring-after(@formatCode,';'),';')"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:number-style>

            <xsl:choose>
              <xsl:when test="contains(substring-after(substring-after(@formatCode,';'),';'),';')">
                <number:number-style style:name="{concat(generate-id(.),'P2')}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of
                        select="substring-before(substring-after(substring-after(@formatCode,';'),';'),';')"
                      />
                    </xsl:with-param>
                  </xsl:call-template>
                </number:number-style>
                <number:text-style style:name="{generate-id(.)}">
                  <xsl:variable name="text">
                    <xsl:value-of
                      select="substring-after(substring-after(substring-after(@formatCode,';'),';'),';')"
                    />
                  </xsl:variable>
                  <xsl:choose>

                    <!-- text content -->
                    <xsl:when test="contains($text,'@')">
                      <number:text>
                        <xsl:value-of select="translate(substring-before($text,'@'),'_-',' ')"/>
                      </number:text>
                      <number:text-content/>
                      <number:text>
                        <xsl:value-of select="translate(substring-after($text,'@'),'_-',' ')"/>
                      </number:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="translate($text,'_-',' ')"/>
                    </xsl:otherwise>
                  </xsl:choose>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                  <style:map style:condition="value()=0"
                    style:apply-style-name="{concat(generate-id(.),'P2')}"/>
                </number:text-style>
              </xsl:when>
              <xsl:otherwise>
                <number:number-style style:name="{generate-id(.)}">
                  <xsl:call-template name="InsertNumberFormatting">
                    <xsl:with-param name="formatCode">
                      <xsl:value-of select="substring-after(substring-after(@formatCode,';'),';')"/>
                    </xsl:with-param>
                  </xsl:call-template>
                  <style:map style:condition="value()&gt;0"
                    style:apply-style-name="{concat(generate-id(.),'P0')}"/>
                  <style:map style:condition="value()&lt;0"
                    style:apply-style-name="{concat(generate-id(.),'P1')}"/>
                </number:number-style>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>

          <!-- currency style -->
          <xsl:when
            test="contains(@formatCode,'$') or contains(@formatCode,'zł') or contains(@formatCode,'€') or contains(@formatCode,'£')">
            <number:currency-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="@formatCode"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:currency-style>
          </xsl:when>

          <!--percentage style -->
          <xsl:when test="contains(@formatCode,'%')">
            <number:percentage-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="@formatCode"/>
                </xsl:with-param>
              </xsl:call-template>
              <number:text>%</number:text>
            </number:percentage-style>
          </xsl:when>

          <!-- number style -->
          <xsl:otherwise>
            <number:number-style style:name="{generate-id(.)}">
              <xsl:call-template name="InsertNumberFormatting">
                <xsl:with-param name="formatCode">
                  <xsl:value-of select="@formatCode"/>
                </xsl:with-param>
              </xsl:call-template>
            </number:number-style>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>
  
  <xsl:template name="InsertNumberFormatting">
    
    <!-- @Descripition: creates number format  -->
    <!-- @Context: None -->
    
    <xsl:param name="formatCode"/><!-- (string) The format code which is converted  -->

    <!-- '*' is not converted -->
    <xsl:variable name="realFormatCode">
      <xsl:choose>
        <xsl:when test="contains($formatCode,'*')">
          <xsl:value-of select="substring-after($formatCode,'*')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$formatCode"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- adding '\' -->
    <xsl:if test="starts-with($realFormatCode,'\') and not(starts-with($realFormatCode,'\ '))">
      <xsl:call-template name="AddNumberText">
        <xsl:with-param name="format">
          <xsl:value-of select="$realFormatCode"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- handle red negative numbers -->
    <xsl:if test="contains($formatCode,'Red')">
      <style:text-properties fo:color="#ff0000"/>
    </xsl:if>

    <xsl:variable name="currencyFormat">
      <xsl:choose>
        <xsl:when test="contains($realFormatCode,'zł')">zł</xsl:when>
        <xsl:when test="contains($realFormatCode,'Red')">
          <xsl:value-of
            select="substring-after(substring-before(substring-after($realFormatCode,'Red]'),']'),'[')"
          />
        </xsl:when>
        <xsl:when test="contains($realFormatCode,'[$')">
          <xsl:value-of select="substring-after(substring-before($realFormatCode,']'),'[')"/>
        </xsl:when>
        <xsl:when test="contains($realFormatCode,'$')">$</xsl:when>
        <xsl:when test="contains($realFormatCode,'€')">€</xsl:when>
        <xsl:when test="contains($realFormatCode,'£')">£</xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- add text at the beginning -->
    <xsl:if
      test="contains(substring-before(translate($realFormatCode,'0','#'),'#'),'&quot;') and not($currencyFormat and $currencyFormat != '' and contains(substring-before(substring-after(substring-before(translate($realFormatCode,'0','#'),'#'),'&quot;'),'&quot;'),$currencyFormat))">
      <number:text>
        <xsl:value-of
          select="substring-before(substring-after(substring-before(translate($realFormatCode,'0','#'),'#'),'&quot;'),'&quot;')"
        />
      </number:text>
    </xsl:if>
    
    <!-- add space at the beginning -->
    <xsl:if
      test="starts-with($realFormatCode,'_') and not(contains($realFormatCode,'(-') or contains($realFormatCode,'(#') or contains($realFormatCode,'(0'))">
      <number:text>
        <xsl:value-of xml:space="preserve" select="' '"/>
      </number:text>
    </xsl:if>

    <!-- add brackets -->
    <xsl:if
      test="contains($realFormatCode,'(-') or contains($realFormatCode,'(#') or contains($realFormatCode,'(0')">
      <xsl:choose>
        <xsl:when test="starts-with($formatCode,'_')">
          <number:text>
            <xsl:value-of xml:space="preserve" select="' ('"/>
          </number:text>
        </xsl:when>
        <xsl:otherwise>
          <number:text>(</number:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- add '-' at the beginning -->
    <xsl:if
      test="contains($realFormatCode,'-') and not($currencyFormat and $currencyFormat!='') and not(contains(substring-after($realFormatCode,'#'),'-') or contains(substring-after($realFormatCode,'0'),'-'))">
      <number:text>-</number:text>
    </xsl:if>

    <!-- add currency symbol at the beginning -->
    <xsl:if
      test="$currencyFormat and $currencyFormat!='' and not(contains(substring-before($realFormatCode,$currencyFormat),'0') or contains(substring-before($realFormatCode,$currencyFormat),'#'))">

      <!-- add '-' at the beginning -->
      <!-- last 'and' test if at the end is '_-' -->
      <xsl:if
        test="contains(substring-after($realFormatCode,$currencyFormat),'-') and not( substring(substring-after($realFormatCode,$currencyFormat), string-length(substring-after($realFormatCode,$currencyFormat)) - 1) = '_-' )">
        <number:text>-</number:text>
      </xsl:if>
      
        <xsl:call-template name="InsertCurrencySymbol">
          <xsl:with-param name="value" select="$currencyFormat"/>
        </xsl:call-template>

      <!-- add space after currency symbol -->
      <xsl:if
        test="contains(substring-after($realFormatCode,$currencyFormat),'\ ') and (contains(substring-after(substring-after($realFormatCode,$currencyFormat),'\ '),'0') or contains(substring-after(substring-after($realFormatCode,$currencyFormat),'\ '),'#'))">
        <number:text>
          <xsl:value-of xml:space="preserve" select="' '"/>
        </number:text>
      </xsl:if>

    </xsl:if>

    <!-- add '-' at the beginning -->
    <xsl:if
      test="$currencyFormat and $currencyFormat!='' and (contains(substring-before($realFormatCode,$currencyFormat),'0') or contains(substring-before($realFormatCode,$currencyFormat),'#')) and contains(substring-before($realFormatCode,$currencyFormat),'-')">
      <number:text>-</number:text>
    </xsl:if>

    <xsl:choose>
      <xsl:when test="contains($realFormatCode,'E+0')">
        <number:scientific-number>
          <xsl:call-template name="InsertNumberFormattingContent">
            <xsl:with-param name="formatCode" select="$formatCode"/>
            <xsl:with-param name="realFormatCode" select="$realFormatCode"/>
            <xsl:with-param name="currencyFormat" select="$currencyFormat"/>
            <xsl:with-param name="isFraction">false</xsl:with-param>
          </xsl:call-template>
        </number:scientific-number>
      </xsl:when>
      <xsl:when test="contains($realFormatCode,'?/') or contains($realFormatCode,'/?') or contains($realFormatCode,'0/') or contains($realFormatCode,'/0') or contains($realFormatCode,'1/') or contains($realFormatCode,'/1') or contains($realFormatCode,'2/') or contains($realFormatCode,'/2') or contains($realFormatCode,'3/') or contains($realFormatCode,'/3') or contains($realFormatCode,'4/') or contains($realFormatCode,'/4') or contains($realFormatCode,'5/') or contains($realFormatCode,'/5') or contains($realFormatCode,'6/') or contains($realFormatCode,'/6') or contains($realFormatCode,'7/') or contains($realFormatCode,'/7') or contains($realFormatCode,'8/') or contains($realFormatCode,'/8') or contains($realFormatCode,'9/') or contains($realFormatCode,'9/')">
        <number:fraction>
          <xsl:call-template name="InsertNumberFormattingContent">
            <xsl:with-param name="formatCode" select="$formatCode"/>
            <xsl:with-param name="realFormatCode" select="$realFormatCode"/>
            <xsl:with-param name="currencyFormat" select="$currencyFormat"/>
            <xsl:with-param name="isFraction">true</xsl:with-param>
          </xsl:call-template>
        </number:fraction>
      </xsl:when>
      <xsl:otherwise>
        <number:number>
          <xsl:call-template name="InsertNumberFormattingContent">
            <xsl:with-param name="formatCode" select="$formatCode"/>
            <xsl:with-param name="realFormatCode" select="$realFormatCode"/>
            <xsl:with-param name="currencyFormat" select="$currencyFormat"/>
            <xsl:with-param name="isFraction">false</xsl:with-param>
          </xsl:call-template>
        </number:number>
      </xsl:otherwise>
    </xsl:choose>
    
    <!-- add currency symbol at the end -->
    <xsl:if
      test="$currencyFormat and $currencyFormat!='' and (contains(substring-before($realFormatCode,$currencyFormat),'0') or contains(substring-before($realFormatCode,$currencyFormat),'#'))">

      <!-- add space before currency symbol -->
      <xsl:if test="contains(substring-before($realFormatCode,$currencyFormat),'\ ')">
        <number:text>
          <xsl:value-of xml:space="preserve" select="' '"/>
        </number:text>
      </xsl:if>
      
        <xsl:call-template name="InsertCurrencySymbol">
          <xsl:with-param name="value" select="$currencyFormat"/>
        </xsl:call-template>
      
    </xsl:if>

    <!-- add brackets -->
    <xsl:if
      test="contains($realFormatCode,'(-') or contains($realFormatCode,'(#') or contains($realFormatCode,'(0')">
      <number:text>)</number:text>
    </xsl:if>

    <!-- add space at the end -->
    <xsl:if
      test="(contains($realFormatCode,'\ ') and (not($currencyFormat and $currencyFormat!='' and (contains(substring-before($realFormatCode,$currencyFormat),'0') or contains(substring-before($realFormatCode,$currencyFormat),'#'))) and not(contains(substring-after($realFormatCode,'\ '),'0') or contains(substring-after($realFormatCode,'\ '),'#'))) or (contains(substring-after($realFormatCode,$currencyFormat),'\ '))and not(contains(substring-after($realFormatCode,'\ '),'0') or contains(substring-after($realFormatCode,'\ '),'#'))) or (contains($realFormatCode,'_') and (not($currencyFormat and $currencyFormat!='' and (contains(substring-before($realFormatCode,$currencyFormat),'0') or contains(substring-before($realFormatCode,$currencyFormat),'#'))) and not(contains(substring-after($realFormatCode,'_'),'0') or contains(substring-after($realFormatCode,'_'),'#'))) or (contains(substring-after($realFormatCode,$currencyFormat),'_')and not(contains(substring-after($realFormatCode,'_'),'0') or contains(substring-after($realFormatCode,'_'),'#'))))">
      <number:text>
        <xsl:choose>
          <xsl:when test="contains($realFormatCode,'\ \')">
            <xsl:value-of xml:space="preserve" select="translate(concat('\',substring-after($realFormatCode,'\ \')),'\ ',' ')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of xml:space="preserve" select="' '"/>
          </xsl:otherwise>
        </xsl:choose>
      </number:text>
    </xsl:if>

    <!-- add text at the end -->
    <xsl:if
      test="contains(substring-after(translate($realFormatCode,'0','#'),'#'),'&quot;') and not($currencyFormat and $currencyFormat != '' and contains(substring-before(substring-after(substring-after(translate($realFormatCode,'0','#'),'#'),'&quot;'),'&quot;'),$currencyFormat))">
      <number:text>
        <xsl:value-of
          select="substring-before(substring-after(substring-after(translate($realFormatCode,'0','#'),'#'),'&quot;'),'&quot;')"
        />
      </number:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="InsertNumberFormattingContent">
    
    <!-- @Description: inserts content of number formatting -->
    <!-- @Context: none -->
    
    <xsl:param name="formatCode"/><!-- (string) input format code -->
    <xsl:param name="realFormatCode"/><!-- (string) format code modified for conversion --> 
    <xsl:param name="currencyFormat"/><!-- (string) currency format -->
    <xsl:param name="isFraction"/><!-- (bool) check if it's a fraction format -->
    
    <xsl:variable name="formatCodeWithoutComma">
      <xsl:choose>
        <xsl:when test="contains($realFormatCode,'.')">
          <xsl:value-of select="substring-before($realFormatCode,'.')"/>
        </xsl:when>
        <xsl:when test="contains(translate($realFormatCode,'\','?'),'&quot; &quot;?')">
          <xsl:value-of select="substring-before($realFormatCode,'&quot; &quot;')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$realFormatCode"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="formatingMarks">
      <xsl:call-template name="StripText">
        <xsl:with-param name="formatCode" select="$realFormatCode"/>
      </xsl:call-template>      
    </xsl:variable>
    
    <xsl:choose>
      
    <!-- decimal places -->
    <xsl:when test="$isFraction = 'false'">
    <xsl:attribute name="number:decimal-places">
      <xsl:choose>
        <!-- when currency format contains '.' and there is another '.' after -->
        <xsl:when
          test="contains(substring-after($realFormatCode,$currencyFormat),'.' ) and contains($currencyFormat,'.' )">
          <xsl:call-template name="InsertDecimalPlaces">
            <xsl:with-param name="code">
              <xsl:value-of select="substring-after(substring-after($realFormatCode,'.'),'.' )"/>
            </xsl:with-param>
            <xsl:with-param name="value">0</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="contains($formatingMarks,'.')">
          <xsl:call-template name="InsertDecimalPlaces">
            <xsl:with-param name="code">
              <xsl:value-of select="substring-after($formatingMarks,'.')"/>
            </xsl:with-param>
            <xsl:with-param name="value">0</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
    </xsl:when>
      
      <!-- fraction format -->
      <xsl:otherwise>
        
        <xsl:variable name="plainFormat">
          <xsl:choose>
            <xsl:when test="not(contains($realFormatCode,'?/'))">
              <xsl:call-template name="StripText">
                <xsl:with-param name="formatCode">
                  <xsl:call-template name="HandleFixedFractionFormat">
                    <xsl:with-param name="formatCode" select="$realFormatCode"/>
                  </xsl:call-template>
                </xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
          <xsl:call-template name="StripText">
            <xsl:with-param name="formatCode" select="$realFormatCode"/>
          </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="fractionFormat">
          <xsl:choose>
            <xsl:when test="contains(substring-after(translate($plainFormat,'\ ','['),'?'),'[')">
              <xsl:value-of select="concat('?',substring-before(substring-after(translate($plainFormat,'\ ','['),'?'),'['))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('?',substring-after($plainFormat,'?'))"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="number:min-numerator-digits">
          <xsl:value-of select="string-length(substring-before($fractionFormat,'/'))"/>
        </xsl:attribute>
        <xsl:attribute name="number:min-denominator-digits">
          <xsl:value-of select="string-length(substring-after(translate($fractionFormat,'%',''),'/'))"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
      
    <!-- min integer digits -->
    
      <xsl:choose>
        <xsl:when
          test="substring($formatCodeWithoutComma,string-length($formatCodeWithoutComma))='0'">
          <xsl:attribute name="number:min-integer-digits">
          <xsl:call-template name="InsertMinIntegerDigits">
            <xsl:with-param name="code">
              <xsl:value-of
                select="substring($formatCodeWithoutComma,0,string-length($formatCodeWithoutComma))"
              />
            </xsl:with-param>
            <xsl:with-param name="value">1</xsl:with-param>
          </xsl:call-template>
            </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$isFraction = 'false'">
              <xsl:attribute name="number:min-integer-digits">0</xsl:attribute>
            </xsl:when>
            <xsl:when test="substring($formatCodeWithoutComma,string-length($formatCodeWithoutComma))='#'">
              <xsl:attribute name="number:min-integer-digits">0</xsl:attribute>
            </xsl:when>
          </xsl:choose>
          </xsl:otherwise>
      </xsl:choose>
    
    <xsl:if test="not(contains(substring-after(@formatCode, '.'), '0')) and $isFraction = 'false'">
      <xsl:attribute name="number:decimal-replacement"/>
    </xsl:if>
    
    
    <!-- grouping -->
    <xsl:if test="contains($realFormatCode,',')">
      <xsl:choose>
        <xsl:when
          test="contains(substring-after($realFormatCode,','),'0') or contains(substring-after($realFormatCode,','),'#')">
          <xsl:attribute name="number:grouping">true</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="number:display-factor">
            <xsl:call-template name="UseDisplayFactor">
              <xsl:with-param name="formatBeforeSeparator">
                <xsl:value-of select="substring-before($realFormatCode,',')"/>
              </xsl:with-param>
              <xsl:with-param name="formatAfterSeparator">
                <xsl:value-of select="substring-after($realFormatCode,',')"/>
              </xsl:with-param>
              <xsl:with-param name="value">1000</xsl:with-param>
            </xsl:call-template>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    
    <!-- add scientific format -->
    
    <xsl:if test="contains($realFormatCode,'E+0')">
      <xsl:attribute name="number:min-exponent-digits">
        <xsl:call-template name="AddMinExponentDigits">
          <xsl:with-param name="format">
            <xsl:value-of select="substring-after($realFormatCode,'E+')"/>
          </xsl:with-param>
          <xsl:with-param name="number">0</xsl:with-param>
        </xsl:call-template>
      </xsl:attribute>
    </xsl:if>
    
    <!-- '-' embedded in number format -->
    <xsl:if
      test="($isFraction = 'false') and (contains(substring-after(substring-before($formatCode,'.'),'#'),'-') or (not(contains($formatCode,'.')) and contains(substring-after($formatCode,'#'),'-') and string-length(translate(substring-after(substring-after($formatCode,'#'),'-'),'-','')) &gt; 0) or contains(substring-after(substring-before($formatCode,'.'),'0'),'-')  or (not(contains($formatCode,'.')) and contains(substring-after($formatCode,'0'),'-') and string-length(translate(substring-after(substring-after($formatCode,'0'),'-'),'-','')) &gt; 0))">
      <xsl:call-template name="FindTextNumberFormat">
        <xsl:with-param name="format">
          <xsl:choose>
            <xsl:when test="contains(substring-after(substring-before($formatCode,'.'),'#'),'-')">
              <xsl:value-of
                select="concat('#',substring-after(substring-before($formatCode,'.'),'#'))"/>
            </xsl:when>
            <xsl:when test="contains(substring-after(substring-before($formatCode,'.'),'0'),'-')">
              <xsl:value-of
                select="concat('0',substring-after(substring-before($formatCode,'.'),'0'))"/>
            </xsl:when>
            <xsl:when
              test="not(contains($formatCode,'.')) and contains(substring-after($formatCode,'#'),'-')">
              <xsl:value-of select="concat('#',substring-after($formatCode,'#'))"/>
            </xsl:when>
            <xsl:when
              test="not(contains($formatCode,'.')) and contains(substring-after($formatCode,'0'),'-')">
              <xsl:value-of select="concat('0',substring-after($formatCode,'0'))"/>
            </xsl:when>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="embeddedText">-</xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    
    <!-- '\ ' embedded in number format -->
    <xsl:if
      test="($isFraction = 'false') and (contains(substring-after(substring-before($formatCode,'.'),'#'),'\ ') or (not(contains($formatCode,'.')) and contains(substring-after($formatCode,'#'),'\ ') and string-length(translate(substring-after(substring-after($formatCode,'#'),'\ '),'\ ','')) &gt; 0) or contains(substring-after(substring-before($formatCode,'.'),'0'),'\ ')  or (not(contains($formatCode,'.')) and contains(substring-after($formatCode,'0'),'\ ') and string-length(translate(substring-after(substring-after($formatCode,'0'),'\ '),'\ ','')) &gt; 0))">
      <xsl:call-template name="FindTextNumberFormat">
        <xsl:with-param name="format">
          <xsl:choose>
            <xsl:when test="contains(substring-after(substring-before($formatCode,'.'),'#'),'\ ')">
              <xsl:value-of
                select="concat('#',substring-after(substring-before($formatCode,'.'),'#'))"/>
            </xsl:when>
            <xsl:when test="contains(substring-after(substring-before($formatCode,'.'),'0'),'\ ')">
              <xsl:value-of
                select="concat('0',substring-after(substring-before($formatCode,'.'),'0'))"/>
            </xsl:when>
            <xsl:when
              test="not(contains($formatCode,'.')) and contains(substring-after($formatCode,'#'),'\ ')">
              <xsl:value-of select="concat('#',substring-after($formatCode,'#'))"/>
            </xsl:when>
            <xsl:when
              test="not(contains($formatCode,'.')) and contains(substring-after($formatCode,'0'),'\ ')">
              <xsl:value-of select="concat('0',substring-after($formatCode,'0'))"/>
            </xsl:when>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="embeddedText">
          <xsl:value-of xml:space="preserve" select="'\ '"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="UseDisplayFactor">
    
    <!-- @Descripition: inserts display factor -->
    <!-- @Context: None -->
    
    <xsl:param name="formatBeforeSeparator"/><!-- (string) format code before ',' separator -->
    <xsl:param name="formatAfterSeparator"/><!-- (string) format code after ',' separator -->
    <xsl:param name="value"/><!-- (int) display factor to return -->
    <xsl:choose>
      <xsl:when test="$formatAfterSeparator and starts-with($formatAfterSeparator,',')">
        <xsl:call-template name="UseDisplayFactor">
          <xsl:with-param name="formatBeforeSeparator" select="$formatBeforeSeparator"/>
          <xsl:with-param name="formatAfterSeparator">
            <xsl:value-of select="substring($formatAfterSeparator,2)"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="number($value)*1000"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertMinIntegerDigits">
    
    <!-- @Descripition: inserts min integer digits -->
    <!-- @Context: None -->
    
    <xsl:param name="code"/><!-- (string) processed format code -->
    <xsl:param name="value"/><!-- (int) number of min integer digits to return -->
    <xsl:choose>
      <xsl:when test="substring($code,string-length($code)) = '0' ">
        <xsl:call-template name="InsertMinIntegerDigits">
          <xsl:with-param name="code">
            <xsl:value-of select="substring($code,0,string-length($code))"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="$value+1"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertDecimalPlaces">
    
    <!-- @Descripition: inserts decimal places -->
    <!-- @Context: None -->
    
    <xsl:param name="code"/><!-- (string) processed format code -->
    <xsl:param name="value"/><!-- (int) number of min decimal places to return -->
    <xsl:choose>
      <xsl:when test="substring($code,1,1) = '0' or substring($code,1,1) = '#' ">
        <xsl:call-template name="InsertDecimalPlaces">
          <xsl:with-param name="code">
            <xsl:value-of select="substring($code,2)"/>
          </xsl:with-param>
          <xsl:with-param name="value">
            <xsl:value-of select="$value+1"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- template which adds number text -->

  <xsl:template name="AddNumberText">
    
    <!-- @Descripition: adds number text -->
    <!-- @Context: None -->
    
    <xsl:param name="format"/><!-- (string) format code -->
    <xsl:choose>
      <xsl:when test="starts-with($format,'\') and not(starts-with($format,'\ '))">
        <number:text>
          <xsl:value-of select="substring($format,2,1)"/>
        </number:text>
        <xsl:call-template name="AddNumberText">
          <xsl:with-param name="format">
            <xsl:value-of select="substring($format,3)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="starts-with($format,'\ ')">
        <number:text>
          <xsl:value-of xml:space="preserve" select="' '"/>
        </number:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="e:xf" mode="fixedNumFormat">
    
    <!-- @Descripition: adds number style with fixed number format -->
    <!-- @Context: None -->
    
    <xsl:if test="@numFmtId and @numFmtId &gt; 0 and not(key('numFmtId',@numFmtId))">
      <xsl:choose>

        <!-- time style -->
        <xsl:when test="(@numFmtId &gt; 17 and @numFmtId &lt; 22) or (@numFmtId &gt; 44 and @numFmtId &lt; 48)">
          <number:time-style style:name="{concat('N',@numFmtId)}">
            <xsl:call-template name="InsertFixedTimeFormat">
              <xsl:with-param name="ID">
                <xsl:value-of select="@numFmtId"/>
              </xsl:with-param>
            </xsl:call-template>
          </number:time-style>
        </xsl:when>
        
        <!-- date style -->
        <xsl:when test="(@numFmtId &gt; 13 and @numFmtId &lt; 18) or @numFmtId = 22">
          <number:date-style style:name="{concat('N',@numFmtId)}">
            <xsl:call-template name="InsertFixedDateFormat">
              <xsl:with-param name="ID">
                <xsl:value-of select="@numFmtId"/>
              </xsl:with-param>
            </xsl:call-template>
          </number:date-style>
        </xsl:when>

        <!-- percentage style -->
        <xsl:when test="@numFmtId = 9 or @numFmtId = 10">
          <number:percentage-style style:name="{concat('N',@numFmtId)}">
            <xsl:call-template name="InsertFixedNumFormat">
              <xsl:with-param name="ID">
                <xsl:value-of select="@numFmtId"/>
              </xsl:with-param>
            </xsl:call-template>
          </number:percentage-style>
        </xsl:when>

        <!-- number style -->
        <xsl:otherwise>
          <number:number-style style:name="{concat('N',@numFmtId)}">
            <xsl:call-template name="InsertFixedNumFormat">
              <xsl:with-param name="ID">
                <xsl:value-of select="@numFmtId"/>
              </xsl:with-param>
            </xsl:call-template>
          </number:number-style>
        </xsl:otherwise>

      </xsl:choose>
    </xsl:if>
  </xsl:template>
 
   <xsl:template name="InsertCurrencySymbol">
    
    <!-- @Descripition: inserts currency symbol element -->
    <!-- @Context: None -->
    <xsl:param name="value"/><!--(string) converted currency symbol -->
    <xsl:choose>
      <xsl:when test="$value = '$$-C09' ">
        <number:currency-symbol number:language="en" number:country="AU">$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$$-1009' ">
        <number:currency-symbol number:language="en" number:country="CA">$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$$-1409' ">
        <number:currency-symbol number:language="en" number:country="NZ">$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$$-409' or $value = '$' ">
        <number:currency-symbol number:language="en" number:country="US">$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$USD' ">
        <number:currency-symbol number:language="en" number:country="US"
        >USD</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$£-452' ">
        <number:currency-symbol number:language="cy" number:country="GB">£</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$£-809' or $value = '£' ">
        <number:currency-symbol number:language="en" number:country="GB">£</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$GBP' ">
        <number:currency-symbol number:language="en" number:country="GB"
        >GBP</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-1809' ">
        <number:currency-symbol number:language="ga" number:country="IE">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-816' ">
        <number:currency-symbol number:language="pt" number:country="PT">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-413' ">
        <number:currency-symbol number:language="nl" number:country="NL">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-813' ">
        <number:currency-symbol number:language="nl" number:country="BE">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-40B' ">
        <number:currency-symbol number:language="fi" number:country="FI">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-408' ">
        <number:currency-symbol number:language="el" number:country="GR">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-81D' ">
        <number:currency-symbol number:language="sv" number:country="FI">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-410' ">
        <number:currency-symbol number:language="it" number:country="IT">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-180C' ">
        <number:currency-symbol number:language="fr" number:country="MC">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-140C' ">
        <number:currency-symbol number:language="fr" number:country="LU">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-80C' ">
        <number:currency-symbol number:language="fr" number:country="BE">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-40C' ">
        <number:currency-symbol number:language="fr" number:country="FR">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-1007' ">
        <number:currency-symbol number:language="de" number:country="LU">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-C07' ">
        <number:currency-symbol number:language="de" number:country="AT">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-407' ">
        <number:currency-symbol number:language="de" number:country="DE">€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-1' or $value = '$€-2' or $value = '€' ">
        <number:currency-symbol>€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$EUR'">
        <number:currency-symbol>EUR</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr-41D' ">
        <number:currency-symbol number:language="sv" number:country="SE">kr</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr-406' ">
        <number:currency-symbol number:language="da" number:country="DK">kr</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr-414' ">
        <number:currency-symbol number:language="no" number:country="NO">kr</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr-814' ">
        <number:currency-symbol number:language="nn" number:country="NO">kr</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr-425' ">
        <number:currency-symbol number:language="et" number:country="EE">kr</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$kr.-40F' ">
        <number:currency-symbol number:language="is" number:country="IS"
        >kr.</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$SFr.-807' ">
        <number:currency-symbol number:language="de" number:country="CH"
        >SFr.</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$SFr.-810' ">
        <number:currency-symbol number:language="it" number:country="CH"
        >SFr.</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$SIT-424' ">
        <number:currency-symbol number:language="sl" number:country="SI"
        >SIT</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Kč-405' ">
        <number:currency-symbol number:language="cs" number:country="CZ">Kč</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Sk-41B' ">
        <number:currency-symbol number:language="sk" number:country="SK">Sk</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Lt-427' ">
        <number:currency-symbol number:language="lt" number:country="LT">Lt</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Ls-426' ">
        <number:currency-symbol number:language="lv" number:country="LV">Ls</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$lei-418' ">
        <number:currency-symbol number:language="ro" number:country="RO"
        >lei</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Din.-81A' ">
        <number:currency-symbol number:language="sh" number:country="YU"
        >Din</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$лв-402' ">
        <number:currency-symbol number:language="bg" number:country="BG">лв</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$KM-141A' ">
        <number:currency-symbol number:language="bs" number:country="BA">KM</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$Ft-40E' ">
        <number:currency-symbol number:language="hu" number:country="HU">Ft</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$HK$-C04' ">
        <number:currency-symbol number:language="zh" number:country="HK"
        >HK$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$NT$-404' ">
        <number:currency-symbol number:language="zh" number:country="TW"
        >NT$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$￥-804' ">
        <number:currency-symbol number:language="zh" number:country="CN">￥</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$¥-411' ">
        <number:currency-symbol number:language="ja" number:country="JP">￥</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$₩-412' ">
        <number:currency-symbol number:language="ko" number:country="KR">￦</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = 'zł'">
        <number:currency-symbol number:language="pl" number:country="PL">zł</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$PLN'">
        <number:currency-symbol number:language="pl" number:country="PL"
        >PLN</number:currency-symbol>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertFixedNumFormat">
    
    <!-- @Descripition: inserts fixed number format -->
    <!-- @Context: None -->
    
    <xsl:param name="ID"/><!-- (int) number format ID -->
    
    <xsl:choose>
      <xsl:when test="$ID = 12 or $ID = 13">
        
        <!--fraction format -->
        <number:fraction number:min-integer-digits="0">
          <xsl:attribute name="number:min-numerator-digits">
            <xsl:choose>
              <xsl:when test="$ID = 12">1</xsl:when>
              <xsl:when test="$ID = 13">2</xsl:when>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="number:min-denominator-digits">
            <xsl:choose>
              <xsl:when test="$ID = 12">1</xsl:when>
              <xsl:when test="$ID = 13">2</xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </number:fraction>
      </xsl:when>
      <xsl:when test="$ID = 11">
        
      <!-- scientific format -->
        <number:scientific-number number:decimal-places="2" number:min-integer-digits="1" number:min-exponent-digits="2"/>
         
      </xsl:when>
      <xsl:otherwise>
    <number:number>
      <xsl:attribute name="number:decimal-places">
        <xsl:choose>
          <xsl:when test="$ID = 1 or $ID = 3 or $ID = 9">0</xsl:when>
          <xsl:when test="$ID = 2 or $ID = 4 or $ID = 10">2</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="number:min-integer-digits">
        <xsl:choose>
          <xsl:when test="$ID = 1 or $ID = 2 or $ID = 3 or $ID = 4 or $ID = 9 or $ID = 10">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="$ID = 3 or $ID = 4">
        <xsl:attribute name="number:grouping">true</xsl:attribute>
      </xsl:if>
    </number:number>
    <xsl:if test="$ID = 9 or $ID = 10">
      <number:text>%</number:text>
    </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="ProcessFormat">
    
    <!-- @Descripition: processes date or time format -->
    <!-- @Context: None -->
    
    <xsl:param name="format"/><!-- (string) whole format code -->
    <xsl:param name="processedFormat"/><!-- (string) part of format code which is being processed -->
    <xsl:choose>

      <!-- year -->
      <xsl:when test="starts-with($processedFormat,'y')">
        <xsl:choose>
          <xsl:when test="starts-with(substring-after($processedFormat,'y'),'yyy')">
            <number:year number:style="long"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'yyyy')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <number:year/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'yy')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="starts-with($processedFormat,'m')">
        <xsl:choose>

          <!-- minutes -->
          <xsl:when test="contains(substring-before($format,'m'),'h')">
            <xsl:choose>
              <xsl:when test="starts-with(substring-after($processedFormat,'m'),'m')">
                <number:minutes number:style="long"/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'mm')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <number:minutes/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'m')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <!-- month -->
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="starts-with(substring-after($processedFormat,'m'),'mmm')">
                <number:month number:style="long" number:textual="true"/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'mmmm')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="starts-with(substring-after($processedFormat,'m'),'mm')">
                <number:month number:textual="true"/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'mmm')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="starts-with(substring-after($processedFormat,'m'),'m')">
                <number:month number:style="long"/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'mm')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <number:month/>
                <xsl:call-template name="ProcessFormat">
                  <xsl:with-param name="format" select="$format"/>
                  <xsl:with-param name="processedFormat">
                    <xsl:value-of select="substring-after($processedFormat,'m')"/>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- day -->
      <xsl:when test="starts-with($processedFormat,'d')">
        <xsl:choose>
          <xsl:when test="starts-with(substring-after($processedFormat,'d'),'ddd')">
            <number:day-of-week number:style="long"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'dddd')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="starts-with(substring-after($processedFormat,'d'),'dd')">
            <number:day-of-week/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'ddd')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="starts-with(substring-after($processedFormat,'d'),'d')">
            <number:day number:style="long"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'dd')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <number:day/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'d')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- hours -->
      <xsl:when test="starts-with($processedFormat,'h')">
        <xsl:choose>
          <xsl:when test="starts-with(substring-after($processedFormat,'h'),'h')">
            <number:hours number:style="long"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'hh')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <number:hours/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'h')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- seconds -->
      <xsl:when test="starts-with($processedFormat,'s')">
        <xsl:choose>
          <xsl:when test="starts-with(substring-after($processedFormat,'s'),'s.')">
            <xsl:variable name="decimalPlaces">
              <xsl:call-template name="InsertDecimalPlaces">
                <xsl:with-param name="code">
                  <xsl:value-of select="substring-after($processedFormat,'s.')"/>
                </xsl:with-param>
                <xsl:with-param name="value">0</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
            <number:seconds number:style="long" number:decimal-places="{$decimalPlaces}"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring(substring-after($processedFormat,'ss.'),$decimalPlaces+1)"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="starts-with(substring-after($processedFormat,'s'),'.')">
            <xsl:variable name="decimalPlaces">
              <xsl:call-template name="InsertDecimalPlaces">
                <xsl:with-param name="code">
                  <xsl:value-of select="substring-after($processedFormat,'s.')"/>
                </xsl:with-param>
                <xsl:with-param name="value">0</xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
            <number:seconds number:style="long" number:decimal-places="{$decimalPlaces}"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring(substring-after($processedFormat,'s.'),$decimalPlaces+1)"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="starts-with(substring-after($processedFormat,'s'),'s')">
            <number:seconds number:style="long"/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'ss')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <number:seconds/>
            <xsl:call-template name="ProcessFormat">
              <xsl:with-param name="format" select="$format"/>
              <xsl:with-param name="processedFormat">
                <xsl:value-of select="substring-after($processedFormat,'s')"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="starts-with($processedFormat,'AM/PM')">
        <number:am-pm/>
        <xsl:call-template name="ProcessFormat">
          <xsl:with-param name="format" select="$format"/>
          <xsl:with-param name="processedFormat">
            <xsl:value-of select="substring-after($processedFormat,'AM/PM')"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when
        test="starts-with($processedFormat,'\') or starts-with($processedFormat,'@') or starts-with($processedFormat,';') or starts-with($processedFormat,'&quot;')">
        <xsl:call-template name="ProcessFormat">
          <xsl:with-param name="format" select="$format"/>
          <xsl:with-param name="processedFormat">
            <xsl:value-of select="substring($processedFormat,2)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string-length($processedFormat) = 0"/>
      <xsl:otherwise>
        <number:text>
          <xsl:value-of xml:space="preserve" select="substring($processedFormat,0,2)"/>
        </number:text>
        <xsl:call-template name="ProcessFormat">
          <xsl:with-param name="format" select="$format"/>
          <xsl:with-param name="processedFormat">
            <xsl:value-of select="substring($processedFormat,2)"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="InsertFixedDateFormat">
    
    <!-- @Descripition: inserts fixed date format -->
    <!-- @Context: None -->
    
    <xsl:param name="ID"/><!-- (int) number format ID -->
    <xsl:choose>
      <xsl:when test="$ID = 14">
        <number:month number:style="long"/>
        <number:text>-</number:text>
        <number:day number:style="long"/>
        <number:text>-</number:text>
        <number:year/>
      </xsl:when>
      <xsl:when test="$ID = 15">
        <number:day/>
        <number:text>-</number:text>
        <number:month number:textual="true"/>
        <number:text>-</number:text>
        <number:year/>
      </xsl:when>
      <xsl:when test="$ID = 16">
        <number:day/>
        <number:text>-</number:text>
        <number:month number:textual="true"/>
      </xsl:when>
      <xsl:when test="$ID = 17">
        <number:month number:textual="true"/>
        <number:text>-</number:text>
        <number:year/>
      </xsl:when>
      <xsl:when test="$ID = 22">
        <number:month/>
        <number:text>/</number:text>
        <number:day/>
        <number:text>/</number:text>
        <number:year/>
        <number:text>
          <xsl:value-of xml:space="preserve" select="' '"/>
        </number:text>
        <number:hours/>
        <number:text>:</number:text>
        <number:minutes number:style="long"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="InsertFixedTimeFormat">
    
    <!-- @Descripition: inserts fixed date format -->
    <!-- @Context: None -->
    
    <xsl:param name="ID"/><!-- (int) number format ID -->
      <xsl:choose>
        <xsl:when test="$ID = 18">
          <number:hours/>
         <number:text>:</number:text>
          <number:minutes number:style="long"/>
          <number:text>
            <xsl:value-of xml:space="preserve" select="' '"/>
          </number:text>
          <number:am-pm/>
        </xsl:when>
        <xsl:when test="$ID = 19">
          <number:hours/>
          <number:text>:</number:text>
          <number:minutes number:style="long"/>
          <number:text>:</number:text>
          <number:seconds number:style="long"/>
          <number:text>
            <xsl:value-of xml:space="preserve" select="' '"/>
          </number:text>
          <number:am-pm/>
        </xsl:when>
        <xsl:when test="$ID = 20">
          <number:hours/>
          <number:text>:</number:text>
          <number:minutes number:style="long"/>
        </xsl:when>
        <xsl:when test="$ID = 21">
          <number:hours/>
          <number:text>:</number:text>
          <number:minutes number:style="long"/>
          <number:text>:</number:text>
          <number:seconds number:style="long"/>
        </xsl:when>
      </xsl:choose>
  </xsl:template>
  
  <xsl:template name="FindTextNumberFormat">
    
    <!-- @Descripition: adds embedded text in number format -->
    <!-- @Context: None -->
    
    <xsl:param name="format"/><!-- (string) format code -->
    <xsl:param name="embeddedText"/><!-- (string) text to be embedded -->
    <xsl:choose>
      <xsl:when test="string-length($format) &gt; 0">
        <xsl:choose>
          <xsl:when test="starts-with($format,$embeddedText)">
            <number:embedded-text
              number:position="{string-length(translate(substring($format,1+string-length($embeddedText)),$embeddedText,''))}">
              <xsl:value-of xml:space="preserve" select="translate($embeddedText,'\ ',' ')"/>
            </number:embedded-text>
            <xsl:call-template name="FindTextNumberFormat">
              <xsl:with-param name="format">
                <xsl:value-of select="substring($format,1+string-length($embeddedText))"/>
              </xsl:with-param>
              <xsl:with-param xml:space="preserve" name="embeddedText" select="$embeddedText"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="FindTextNumberFormat">
              <xsl:with-param name="format">
                <xsl:value-of select="substring($format,2)"/>
              </xsl:with-param>
              <xsl:with-param xml:space="preserve" name="embeddedText" select="$embeddedText"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="StripText">
    <xsl:param name="formatCode"/>

    <xsl:choose>
      <xsl:when test="contains($formatCode,'&quot;')">
        <xsl:variable name="beforeText">
          <xsl:value-of select="substring-before($formatCode,'&quot;')"/>
        </xsl:variable>

        <xsl:variable name="afterText">
          <xsl:value-of
            select="substring-after(substring-after($formatCode,'&quot;'),'&quot;')"/>
        </xsl:variable>

        <xsl:call-template name="StripText">
          <xsl:with-param name="formatCode" select="concat($beforeText,$afterText)"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:value-of select="$formatCode"/>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>
  
  <xsl:template name="AddMinExponentDigits">
    
    <!--@Description: Adds min-exponent-digits argument -->
    <!--@Context: none -->
    
    <xsl:param name="format"/><!-- (string) input number format -->
    <xsl:param name="number"/><!-- (int) output min-exponent-digits value --> 
    <xsl:choose>
      <xsl:when test="starts-with($format,'0')">
        <xsl:call-template name="AddMinExponentDigits">
          <xsl:with-param name="format">
            <xsl:value-of select="substring($format,2)"/>
          </xsl:with-param>
          <xsl:with-param name="number">
            <xsl:value-of select="$number+1"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$number"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="HandleFixedFractionFormat">
    
    <!-- @Description: handles a fixed fraction format by converting it to normal format -->
    <!-- @Context: none -->
    
    <xsl:param name="formatCode"/>
    <xsl:value-of select="translate(translate(translate(translate(translate(translate(translate(translate(translate(translate(substring-after($formatCode,'&quot; &quot;'),'0','?'),'1','?'),'2','?'),'3','?'),'4','?'),'5','?'),'6','?'),'7','?'),'8','?'),'9','?')"/>
  </xsl:template>
</xsl:stylesheet>
