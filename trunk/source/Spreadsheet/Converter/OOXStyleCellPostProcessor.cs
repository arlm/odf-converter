/*
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
 */

using System;
using System.Xml;
using System.Collections;
using CleverAge.OdfConverter.OdfConverterLib;

namespace CleverAge.OdfConverter.Spreadsheet
{
    /// <summary>
    /// Postprocessor which insert groups.
    /// </summary>
    public class OOXStyleCellPostProcessor : AbstractPostProcessor
    {
        private Stack sharedStringContext;
        private const string PXSI_NAMESPACE = "urn:cleverage:xmlns:post-processings:shared-strings";
        private bool isInSharedString;
        private bool isString;
        private string stringNumber;
        private Element sharedStringElement;
        private bool isPxsi;
        private bool style;
        private bool cellXfs;
        private bool tableCellNumber;
        private bool changeCellName;
        private int numberCell;
        private Hashtable styleCellNumber;

        public OOXStyleCellPostProcessor(XmlWriter nextWriter)
            : base(nextWriter)
        {
            this.sharedStringContext = new Stack();
            this.isInSharedString = false;
            this.isString = false;
            this.stringNumber = "0";
            this.isPxsi = false;
            this.style = false;
            this.tableCellNumber = false;
            this.changeCellName = false;
            this.numberCell = 0;
            styleCellNumber = new Hashtable();
            
        }

        public override void WriteStartElement(string prefix, string localName, string ns)
        {
           
            
                this.nextWriter.WriteStartElement(prefix, localName, ns);
           

        }

        public override void WriteStartAttribute(string prefix, string localName, string ns)
        {
            if ("post-style-name".Equals(localName))
            {
                this.numberCell = this.numberCell + 1;
                this.tableCellNumber = true;
            }
            else if ("style-number-change-post".Equals(localName))
            {
                this.nextWriter.WriteStartAttribute(prefix, "s", ns);
                this.changeCellName = true;
            }
            else
            {
                this.nextWriter.WriteStartAttribute(prefix, localName, ns);
            }
           


        }

        public override void WriteString(string text)
        {
            if (this.tableCellNumber)
            {
                if (!styleCellNumber.ContainsKey(text))
                {
                    styleCellNumber.Add(text, this.numberCell);
                }
            }
            else if (this.changeCellName)
            {
                this.nextWriter.WriteString(styleCellNumber[text].ToString());
            }
            else
            {
                this.nextWriter.WriteString(text);
            }
           

        }

        public override void WriteEndAttribute()
        {
            if (this.tableCellNumber)
            {
                this.tableCellNumber = false;
            }
            else if (this.changeCellName)
            {
                this.changeCellName = false;
            }
            else
            {
                this.nextWriter.WriteEndAttribute();
            }
           

        }

        public override void WriteEndElement()
        {

          
                this.nextWriter.WriteEndElement();
           

        }
    }
}