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
  xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"
  exclude-result-prefixes="e">
  
  <!-- insert  number format style -->
  
  <xsl:template match="e:numFmt" mode="automaticstyles">
    
    <xsl:choose>
      
      <!-- when there are different formats for positive and negative numbers -->
      <xsl:when test="contains(@formatCode,';')">
        <xsl:choose>
          
          <!-- currency style -->
          <xsl:when test="contains(substring-before(@formatCode,';'),'[$') or contains(substring-before(@formatCode,';'),'zł')">
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
              <style:map style:condition="value()&gt;=0" style:apply-style-name="{concat(generate-id(.),'P0')}"/>
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
              <style:map style:condition="value()&gt;=0" style:apply-style-name="{concat(generate-id(.),'P0')}"/>
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
              <style:map style:condition="value()&gt;=0" style:apply-style-name="{concat(generate-id(.),'P0')}"/>
            </number:number-style>
          </xsl:otherwise>
          
        </xsl:choose>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:choose>
          
          <!-- currency style -->
          <xsl:when test="contains(@formatCode,'[$') or contains(@formatCode,'zł')">
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
  
  <!-- template to create number format -->
  
  <xsl:template name="InsertNumberFormatting">
    <xsl:param name="formatCode"/>
    
    <!-- handle red negative numbers -->
    <xsl:if test="contains($formatCode,'Red')">
      <style:text-properties fo:color="#ff0000"/>
    </xsl:if>
    
    <xsl:variable name="currencyFormat">
      <xsl:choose>
        <xsl:when test="contains($formatCode,'zł')">zł</xsl:when>
        <xsl:when test="contains($formatCode,'Red')">
          <xsl:value-of select="substring-after(substring-before(substring-after($formatCode,'Red]'),']'),'[')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-after(substring-before($formatCode,']'),'[')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- add '-' at the beginning -->
    <xsl:if test="contains($formatCode,'-') and not($currencyFormat and $currencyFormat!='')">
      <number:text>-</number:text>
    </xsl:if>
    
    <!-- add currency symbol at the beginning -->
    <xsl:if test="$currencyFormat and $currencyFormat!='' and not(contains(substring-before($formatCode,$currencyFormat),'0') or contains(substring-before($formatCode,$currencyFormat),'#'))">
      
      <!-- add '-' at the beginning -->
      <xsl:if test="contains(substring-after($formatCode,$currencyFormat),'-')">
        <number:text>-</number:text>
      </xsl:if>
      <xsl:call-template name="InsertCurrencySymbol">
        <xsl:with-param name="value" select="$currencyFormat"/>
      </xsl:call-template>
    </xsl:if>
    
    <!-- add '-' at the beginning -->
    <xsl:if test="$currencyFormat and $currencyFormat!='' and (contains(substring-before($formatCode,$currencyFormat),'0') or contains(substring-before($formatCode,$currencyFormat),'#')) and contains(substring-before($formatCode,$currencyFormat),'-')">
      <number:text>-</number:text>
    </xsl:if>
    
    <number:number>
      
      <xsl:variable name="formatCodeWithoutComma">
        <xsl:choose>
          <xsl:when test="contains($formatCode,'.')">
            <xsl:value-of select="substring-before($formatCode,'.')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$formatCode"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- decimal places -->
      <xsl:attribute name="number:decimal-places">
        <xsl:choose>
          <xsl:when test="contains($formatCode,'.')">
            <xsl:call-template name="InsertDecimalPlaces">
              <xsl:with-param name="code">
                <xsl:value-of select="substring-after($formatCode,'.')"/>
              </xsl:with-param>
              <xsl:with-param name="value">0</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      
      <!-- min integer digits -->
      
      <xsl:attribute name="number:min-integer-digits">
        <xsl:choose>
          <xsl:when test="contains($formatCodeWithoutComma,'0')">
            <xsl:call-template name="InsertMinIntegerDigits">
              <xsl:with-param name="code">
                <xsl:value-of select="substring-after($formatCodeWithoutComma,'0')"/>
              </xsl:with-param>
              <xsl:with-param name="value">1</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      
      <!-- grouping -->
      <xsl:if test="contains($formatCode,',')">
        <xsl:choose>
          <xsl:when test="contains(substring-after($formatCode,','),'0') or contains(substring-after($formatCode,','),'#')">
            <xsl:attribute name="number:grouping">true</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="number:display-factor">
              <xsl:call-template name="UseDisplayFactor">
                <xsl:with-param name="formatBeforeSeparator">
                  <xsl:value-of select="substring-before($formatCode,',')"/>
                </xsl:with-param>
                <xsl:with-param name="formatAfterSeparator">
                  <xsl:value-of select="substring-after($formatCode,',')"/>
                </xsl:with-param>
                <xsl:with-param name="value">1000</xsl:with-param>
              </xsl:call-template>
            </xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      
    </number:number>
    
    <!-- add currency symbol at the end -->
    <xsl:if test="$currencyFormat and $currencyFormat!='' and (contains(substring-before($formatCode,$currencyFormat),'0') or contains(substring-before($formatCode,$currencyFormat),'#'))">
      <xsl:call-template name="InsertCurrencySymbol">
        <xsl:with-param name="value" select="$currencyFormat"/>
      </xsl:call-template>
    </xsl:if>
    
  </xsl:template>
  
  <!-- template which inserts display factor -->
  
  <xsl:template name="UseDisplayFactor">
    <xsl:param name="formatBeforeSeparator"/>
    <xsl:param name="formatAfterSeparator"/>
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="$formatAfterSeparator and $formatAfterSeparator!=''">
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
  
  <!-- template which inserts min integer digits -->
  
  <xsl:template name="InsertMinIntegerDigits">
    <xsl:param name="code"/>
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="contains($code,'0')">
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
  
  <!-- template which inserts decimal places -->
  
  <xsl:template name="InsertDecimalPlaces">
    <xsl:param name="code"/>
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="contains($code,'0') or contains($code,'#')">
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
  
  <!-- adding number style with fixed number format -->
  
  <xsl:template match="e:xf" mode="fixedNumFormat">
    <xsl:if test="@numFmtId and @numFmtId &gt; 0 and not(key('numFmtId',@numFmtId))">
      <xsl:choose>
        
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
  
  <!-- insert currency symbol element -->
  <xsl:template name="InsertCurrencySymbol">
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="$value = '$$-409'">
        <number:currency-symbol number:language="en" number:country="US">$</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$USD'">
        <number:currency-symbol number:language="en" number:country="US">USD</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$£-809'">
        <number:currency-symbol number:language="en" number:country="GB">£</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$GBP'">
        <number:currency-symbol number:language="en" number:country="GB">GBP</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$€-1' or $value = '$€-2'">
        <number:currency-symbol>€</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$EUR'">
        <number:currency-symbol>EUR</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = 'zł'">
        <number:currency-symbol number:language="pl" number:country="PL">zł</number:currency-symbol>
      </xsl:when>
      <xsl:when test="$value = '$PLN'">
        <number:currency-symbol number:language="pl" number:country="PL">PLN</number:currency-symbol>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <!-- template which inserts fixed number format -->
  
  <xsl:template name="InsertFixedNumFormat">
    <xsl:param name="ID"/>
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
  </xsl:template>
  
</xsl:stylesheet>
