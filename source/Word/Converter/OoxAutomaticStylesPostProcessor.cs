/* 
 * Copyright (c) 2006-2008 Clever Age
 * Copyright (c) 2006-2009 DIaLOGIKa
 *
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
 *     * Neither the names of copyright holders, nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software 
 *       without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

using System;
using System.Xml;
using System.Collections;
using System.Collections.Generic;
using CleverAge.OdfConverter.OdfConverterLib;
using System.IO;

namespace OdfConverter.Wordprocessing
{
        
    /// <summary>
    /// An <c>XmlWriter</c> implementation for automatic styles post processings
    public class OoxAutomaticStylesPostProcessor : AbstractPostProcessor
    {

        private const string NAMESPACE = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
        private const string PSECT_NAMESPACE = "urn:cleverage:xmlns:post-processings:sections";


        private string[] TOGGLE_PROPERTIES = 
            { "b", "bCs", "caps", "emboss", "i", "iCs", "imprint", "outline", "shadow", "smallCaps", "strike", "vanish" };

        private string[] RUN_PROPERTIES = { "ins", "del", "moveFrom", "moveTo", "rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps", "smallCaps", "strike", "dstrike", "outline", "shadow", "emboss", "imprint", "noProof", "snapToGrid", "vanish", "webHidden", "color", "spacing", "w", "kern", "position", "sz", "szCs", "highlight", "u", "effect", "bdr", "shd", "fitText", "vertAlign", "rtl", "cs", "em", "lang", "eastAsianLayout", "specVanish", "oMath", "rPrChange" };
        private string[] PARAGRAPH_PROPERTIES = { "pStyle", "keepNext", "keepLines", "pageBreakBefore", "framePr", "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd", "tabs", "suppressAutoHyphens", "kinsoku", "wordWrap", "overflowPunct", "topLinePunct", "autoSpaceDE", "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing", "ind", "contextualSpacing", "mirrorIndents", "textboxTightWrap", "suppressOverlap", "jc", "textDirection", "textAlignment", "outlineLvl", "divId", "cnfStyle", "rPr", "sectPr", "pPrChange"};

        private Stack _currentNode;
        private Stack _context;
        private Stack _currentParagraphStyleName;
        
        private Dictionary<string, Element> _cStyles;
        private Dictionary<string, Element> _pStyles;
        private Dictionary<string, Element> _cStylesAdded = new Dictionary<string, Element>();
        private Dictionary<string, Element> _pStylesAdded = new Dictionary<string, Element>();
        // keep track of lower case styles to avoid conflicts
        // NOTE: This should be HashSet which is only available in .NET 3.5
        //       The value of the dictionary is not used.
        private Dictionary<string, string> _cStylesLowerCaseList;
        private Dictionary<string, string> _pStylesLowerCaseList;

        /// <summary>
        /// Constructor
        /// </summary>
        public OoxAutomaticStylesPostProcessor(XmlWriter nextWriter)
            : base(nextWriter)
        {
            this._currentNode = new Stack();
            this._context = new Stack();
            this._context.Push("root");
            this._currentParagraphStyleName = new Stack();
            this._cStyles = new Dictionary<string, Element>();
            this._pStyles = new Dictionary<string, Element>();
            this._cStylesLowerCaseList = new Dictionary<string, string>();
            this._pStylesLowerCaseList = new Dictionary<string, string>();
        }

        public override void WriteStartElement(string prefix, string localName, string ns)
        {

            if (ns == PSECT_NAMESPACE)
            {
                this.nextWriter.WriteStartElement(prefix, localName, ns);
            }
          
            this._currentNode.Push(new Element(prefix, localName, ns));

            if (IsStyle(localName, ns))
            {
                StartStyle();
            }
            else if ((IsInRun() || IsInRPrChange()) && IsRunProperties(localName, ns))
            {
                StartRunProperties();
            }
            else if (IsRPrChange(localName, ns))
            {
                StartRPrChange();
            }
            else if ((IsInParagraph() || IsInPPrChange()) && IsParagraphProperties(localName, ns))
            {
                StartParagraphProperties();
            }
            else if (IsPPrChange(localName, ns))
            {
                StartPPrChange();
            }
            else if (IsInRunProperties() || IsInParagraphProperties() || IsInStyle())
            {
                // do nothing
            }
            else
            {
                if (IsInRun())
                {
                    StartElementInRun(localName, ns);
                }
                else if (IsRun(localName, ns))
                {
                    StartRun();
                }
                if (IsParagraph(localName, ns))
                {
                    StartParagraph();
                }
                this.nextWriter.WriteStartElement(prefix, localName, ns);
            }
        }

        public override void WriteEndElement()
        {
            if (IsInStyle())
            {
                EndElementInStyle();
            }
            else if (IsInRunProperties())
            {
                EndElementInRunProperties();
            }
            else if (IsInRPrChange())
            {
                EndElementInRPrChange();
            }
            else if (IsInParagraphProperties())
            {
                EndElementInParagraphProperties();
            }
            else if (IsInPPrChange())
            {
                EndElementInPPrChange();
            }
            else
            {
                if (IsInRun())
                {
                    EndElementInRun();
                }
                else if (IsInParagraph())
                {
                    EndElementInParagraph();
                }
                this.nextWriter.WriteEndElement();
            }

            this._currentNode.Pop();
        }

        public override void WriteStartAttribute(string prefix, string localName, string ns)
        {
            this._currentNode.Push(new Attribute(prefix, localName, ns));

            if (IsInRunProperties() || IsInRPrChange() || IsInParagraphProperties() || IsInPPrChange() || IsInStyle())
            {
                // do nothing
            }
            else
            {
                this.nextWriter.WriteStartAttribute(prefix, localName, ns);
            }
        }

        public override void WriteEndAttribute()
        {
            if (IsInStyle() || IsInRunProperties() || IsInRPrChange() || IsInParagraphProperties() || IsInPPrChange())
            {
                Attribute attribute = (Attribute)this._currentNode.Pop();
                Element element = (Element)this._currentNode.Peek();
                element.AddAttribute(attribute);
                this._currentNode.Push(attribute);
            }
            else
            {
                this.nextWriter.WriteEndAttribute();
            }

            this._currentNode.Pop();
        }

        public override void WriteString(string text)
        {
            if (IsInStyle())
            {
                StringInStyle(text);
            }
            else if (IsInRunProperties() || IsInRPrChange())
            {
                StringInRunProperties(text);
            }
            else if (IsInParagraphProperties() || IsInPPrChange())
            {
                StringInParagraphProperties(text);
            }
            else
            {
                this.nextWriter.WriteString(text);
            }
        }


        /*
         * Styles declaration
         */

        private bool IsStyle(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "style".Equals(localName);
        }

        private bool IsInStyle()
        {
            return "style".Equals(this._context.Peek());
        }

        private void StartStyle()
        {
            this._context.Push("style");
        }

        private void EndElementInStyle()
        {
            Element element = (Element)this._currentNode.Pop();
            if (IsStyle(element.Name, element.Ns))
            {
                // style element : write it if not hidden or not paragraph or character style.
                if (IsCharacterStyle(element))
                {
                    string key = element.GetAttributeValue("styleId", NAMESPACE);
                    if (!_cStyles.ContainsKey(key))
                    {
                        // if a style exists having same lower-case name, replace with new name.
                        string name = element.GetChild("name", NAMESPACE).GetAttributeValue("val", NAMESPACE);
                        if (this._cStylesLowerCaseList.ContainsKey(name.ToLower()))
                        {
                            string newStyleName = this.GetUniqueLowerCaseStyleName(name, _cStylesLowerCaseList);
                            Element newName = new Element("w", "name", NAMESPACE);
                            newName.AddAttribute(new Attribute("w", "val", newStyleName, NAMESPACE));
                            element.Replace(element.GetChild("name", NAMESPACE), newName);
                            this._cStylesLowerCaseList.Add(newStyleName, string.Empty);
                        }
                        else
                        {
                            this._cStylesLowerCaseList.Add(name.ToLower(), string.Empty);
                        }
                        this._cStyles.Add(key, element);
                    }
                }
                else if (IsParagraphStyle(element))
                {
                    string key = element.GetAttributeValue("styleId", NAMESPACE);
                    if (!_pStyles.ContainsKey(key))
                    {
                        // if a style exists having same lower-case name, replace with new name.
                        string name = element.GetChild("name", NAMESPACE).GetAttributeValue("val", NAMESPACE);
                        if (this._pStylesLowerCaseList.ContainsKey(name.ToLower()))
                        {
                            string newStyleName = this.GetUniqueLowerCaseStyleName(name, _pStylesLowerCaseList);
                            Element newName = new Element("w", "name", NAMESPACE);
                            newName.AddAttribute(new Attribute("w", "val", newStyleName, NAMESPACE));
                            element.Replace(element.GetChild("name", NAMESPACE), newName);
                            this._pStylesLowerCaseList.Add(newStyleName, string.Empty);
                        }
                        else
                        {
                            this._pStylesLowerCaseList.Add(name.ToLower(), string.Empty);
                        }
                        this._pStyles.Add(key, element);
                    }
                }
                if (!IsParagraphStyle(element) && !IsCharacterStyle(element) || !IsAutomaticStyle(element))
                {
                    element.Write(this.nextWriter);
                }
                this._context.Pop();
            }
            else
            {
                // child element : add it to its parent
                Element parent = (Element)this._currentNode.Peek();
                parent.AddChild(element);
            }
            this._currentNode.Push(element);
        }

        private void StringInStyle(string text)
        {
            Node node = (Node)this._currentNode.Peek();
            if (node is Attribute)
            {
                Attribute attribute = (Attribute)node;
                attribute.Value += text;
            }
            else if (node is Element)
            {
                Element element = (Element)node;
                element.AddChild(text);
            }
        }

        private bool IsAutomaticStyle(Element style)
        {
            if (style != null)
            {
                return style.GetChild("hidden", NAMESPACE) != null;
            }
            return false;
        }

        private bool IsCharacterStyle(Element style)
        {
            return "character".Equals(style.GetAttributeValue("type", NAMESPACE));
        }

        private bool IsParagraphStyle(Element style)
        {
            return "paragraph".Equals(style.GetAttributeValue("type", NAMESPACE));
        }

        /*
         * Paragraphs
         */

        private bool IsParagraph(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "p".Equals(localName);
        }

        private bool IsInParagraph()
        {
            return "p".Equals(this._context.Peek());
        }

        private void StartParagraph()
        {
            this._context.Push("p");
            // no style name yet
            this._currentParagraphStyleName.Push("");
        }

        private void EndElementInParagraph()
        {
            Element element = (Element)this._currentNode.Peek();
            if (IsParagraph(element.Name, element.Ns))
            {
                this._currentParagraphStyleName.Pop();
                this._context.Pop();
            }
        }

        /*
         * Paragraph properties
         */

        private bool IsParagraphProperties(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "pPr".Equals(localName);
        }

        private bool IsInParagraphProperties()
        {
            return "pPr".Equals(this._context.Peek());
        }

        private void StartParagraphProperties()
        {
            this._context.Push("pPr");
        }

        private void EndElementInParagraphProperties()
        {
            Element element = (Element)this._currentNode.Pop();
            if (IsParagraphProperties(element.Name, element.Ns))
            {
                this._context.Pop();
                CompleteParagraphProperties(element);
                Element pPr = GetOrderedParagraphProperties(element);
                if (IsInPPrChange())
                {
                    // attach properties to parent
                    Element pPrChange = (Element)this._currentNode.Peek();
                    pPrChange.AddChild(pPr);
                }
                else
                {
                    // write properties
                    pPr.Write(this.nextWriter);
                }

            }
            else
            {
                Element parent = (Element)this._currentNode.Peek();
                parent.AddChild(element);
            }
            this._currentNode.Push(element);
        }

        private void StringInParagraphProperties(string text)
        {
            Node node = (Node)this._currentNode.Peek();
            if (node is Attribute)
            {
                Attribute attribute = (Attribute)node;
                attribute.Value += text;
            }
            else if (node is Element)
            {
                Element element = (Element)node;
                element.AddChild(text);
            }
        }

        private void CompleteParagraphProperties(Element pPr)
        {
            Element rPr = pPr.GetChild("rPr", NAMESPACE);
            if (rPr == null)
            {
                rPr = new Element("w", "rPr", NAMESPACE);
            }
            else
            {
                pPr.RemoveChild(rPr);
            }
            Element pStyle = pPr.GetChild("pStyle", NAMESPACE);
            if (pStyle != null)
            {
                // remove style declaration (will be added later back)
                pPr.RemoveChild(pStyle);
                // add paragraph style properties
                string pStyleName = pStyle.GetAttributeValue("val", NAMESPACE);
                if (pStyleName.Length > 0)
                {
                    AddParagraphStyleProperties(pPr, pStyleName);
                    if (!IsInPPrChange())
                    {
                        AddRunStyleProperties(rPr, pStyleName, false);
                        // update current paragraph style name
                        this._currentParagraphStyleName.Pop();
                        this._currentParagraphStyleName.Push(pStyleName);
                    }
                    // add style declaration
                    AddStyleDeclaration(pPr, pStyleName, "pStyle");
                }
            }
            // add run properties
            if (rPr.HasChild())
            {
                pPr.AddChild(rPr);
            }
        }

        private void AddParagraphStyleProperties(Element pPr, string styleName)
        {
            if (_pStyles.ContainsKey(styleName) && IsAutomaticStyle(_pStyles[styleName]))
            {
                // add run properties
                AddParagraphProperties(pPr, _pStyles[styleName]);

                // add parent style properties
                Element basedOn = _pStyles[styleName].GetChild("basedOn", NAMESPACE);
                if (basedOn != null)
                {
                    string baseStyleName = basedOn.GetAttributeValue("val", NAMESPACE);
                    if (baseStyleName.Length > 0 && !baseStyleName.Equals(styleName))
                    {
                        AddParagraphStyleProperties(pPr, baseStyleName);
                    }
                }
            }
        }

        private void AddParagraphProperties(Element pPr, Element style)
        {
            Element stylePPr = (Element)style.GetChild("pPr", NAMESPACE);
            bool hasNumbering = false;
            if (stylePPr != null)
            {
                foreach (Element prop in stylePPr.Children)
                {
                    if ("numPr".Equals(prop.Name))
                    {
                        hasNumbering = true;
                    }
                    // special case for not overriding indentation in lists
                    if (hasNumbering && "ind".Equals(prop.Name))
                    {
                        // do nothing
                    }
                    else if (!IsInPPrChange() || !"rPr".Equals(prop.Name))
                    {
                        pPr.AddChildIfNotExist(prop);
                    }
                }
            }
        }

        private Element GetOrderedParagraphProperties(Element pPr)
        {
            Element newPPr = new Element(pPr);
            foreach (string propName in PARAGRAPH_PROPERTIES)
            {
                Element prop = pPr.GetChild(propName, NAMESPACE);
                if (prop != null)
                {
                    if ("rPr".Equals(propName))
                    {
                        newPPr.AddChild(GetOrderedRunProperties(prop));
                    }
                    else
                    {
                        newPPr.AddChild(prop);
                    }
                }
            }
            return newPPr;
        }

        /*
         * Paragraph changes
         */

        private bool IsPPrChange(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "pPrChange".Equals(localName);
        }

        private bool IsInPPrChange()
        {
            return "pPrChange".Equals(this._context.Peek());
        }

        private void StartPPrChange()
        {
            this._context.Push("pPrChange");
        }

        private void EndElementInPPrChange()
        {
            this._context.Pop();
            EndElementInParagraphProperties();
        }

        /*
         * Runs
         */

        private bool IsRun(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "r".Equals(localName);
        }

        private bool IsInRun()
        {
            return "r".Equals(this._context.Peek()) || "r-with-properties".Equals(this._context.Peek());
        }

        private void StartRun()
        {
            this._context.Push("r");
        }

        private void StartElementInRun(string localName, string ns)
        {
            if (!IsInRunProperties() && "r".Equals(this._context.Peek()))
            {
                string styleName = (string)this._currentParagraphStyleName.Peek();
                if (!string.IsNullOrEmpty(styleName) && _pStyles.ContainsKey(styleName) && IsAutomaticStyle(_pStyles[styleName]))
                {
                    Element rPr = new Element("w", "rPr", NAMESPACE);
                    AddRunStyleProperties(rPr, styleName, false);
                    WriteRunProperties(rPr);
                    this._context.Pop();
                    this._context.Push("r-with-properties");
                }
            }
        }

        private void EndElementInRun()
        {
            Element element = (Element)this._currentNode.Peek();
            if (IsRun(element.Name, element.Ns))
            {
                this._context.Pop();
            }
        }

        /*
         * Run properties
         */

        private bool IsRunProperties(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "rPr".Equals(localName);
        }

        private bool IsInRunProperties()
        {
            return "rPr".Equals(this._context.Peek());
        }

        private void StartRunProperties()
        {
            this._context.Push("rPr");
        }

        private void EndElementInRunProperties()
        {
            Element element = (Element)this._currentNode.Pop();
            if (IsRunProperties(element.Name, element.Ns))
            {
                CompleteRunProperties(element);
                this._context.Pop();
                if (!IsInRPrChange())
                {
                    WriteRunProperties(element);
                    this._context.Pop();
                    this._context.Push("r-with-properties");
                }
                else
                {
                    // attach rPr to rPrChange
                    Element parent = (Element)this._currentNode.Peek();
                    parent.AddChild(GetOrderedRunProperties(element));
                }
            }
            else
            {
                Element parent = (Element)this._currentNode.Peek();
                parent.AddChild(element);
            }
            this._currentNode.Push(element);
        }

        private void StringInRunProperties(string text)
        {
            Node node = (Node)this._currentNode.Peek();
            if (node is Attribute)
            {
                Attribute attribute = (Attribute)node;
                attribute.Value += text;
            }
            else if (node is Element)
            {
                Element element = (Element)node;
                element.AddChild(text);
            }
        }

        private void CompleteRunProperties(Element rPr)
        {
            Element rStyle = rPr.GetChild("rStyle", NAMESPACE);
            if (rStyle != null)
            {
                // remove style declaration (will add it later back)
                rPr.RemoveChild(rStyle);
                // add run style properties
                string rStyleName = rStyle.GetAttributeValue("val", NAMESPACE);
                if (rStyleName.Length > 0)
                {
                    AddRunStyleProperties(rPr, rStyleName, true);
                }
            }
            // add paragraph run properties (if automatic)
            string styleName = (string)this._currentParagraphStyleName.Peek();
            if (!"".Equals(styleName) && _pStyles.ContainsKey(styleName) && IsAutomaticStyle(_pStyles[styleName]))
            {
                AddRunProperties(rPr, _pStyles[styleName]);
            }
            // add style name
            if (rStyle != null)
            {
                string rStyleName = rStyle.GetAttributeValue("val", NAMESPACE);
                if (rStyleName.Length > 0)
                {
                    AddStyleDeclaration(rPr, rStyleName, "rStyle");
                }
            }
        }

        private void AddRunStyleProperties(Element rPr, string styleName, bool isCharacterStyle)
        {
            _cStylesAdded.Clear();
            _pStylesAdded.Clear();
            AddRunStylePropertiesRecursive(rPr, styleName, isCharacterStyle);
        }

        private void AddRunStylePropertiesRecursive(Element rPr, string styleName, bool isCharacterStyle)
        {
            if (isCharacterStyle && _cStylesAdded.ContainsKey(styleName) || _pStylesAdded.ContainsKey(styleName))
            {
                // check for cycles in style hierarchy
                return;
            } 
                
            Element style = null;
            if (isCharacterStyle && _cStyles.ContainsKey(styleName))
            {
                style = _cStyles[styleName];
                _cStylesAdded.Add(styleName, style);
            }
            else if (_pStyles.ContainsKey(styleName))
            {
                style = _pStyles[styleName];
                _pStylesAdded.Add(styleName, style);
            }
            else
            {
                // to avoid crash when wrong styles applied
                return;
            }

            // add all run properties
            AddRunProperties(rPr, style);

            // add parent style properties
            Element basedOn = (Element)style.GetChild("basedOn", NAMESPACE);
            if (basedOn != null)
            {
                string parentStyleName = basedOn.GetAttributeValue("val", NAMESPACE);
                if (parentStyleName.Length > 0)
                {
                    AddRunStylePropertiesRecursive(rPr, parentStyleName, isCharacterStyle);
                }
            }
        }

        private void AddRunProperties(Element rPr, Element style)
        {
            Element styleRPr = (Element)style.GetChild("rPr", NAMESPACE);
            if (styleRPr != null)
            {
                foreach (Element prop in styleRPr.Children)
                {
                    if (IsAutomaticStyle(style) || isToggle(prop))
                    {
                        rPr.AddChildIfNotExist(prop);
                    }
                }
            }
        }

        private Element GetOrderedRunProperties(Element rPr)
        {
            Element ordered = new Element(rPr);
            foreach (string propName in RUN_PROPERTIES)
            {
                Element prop = rPr.GetChild(propName, NAMESPACE);
                if (prop != null)
                {
                    ordered.AddChild(prop);
                }
            }
            return ordered;
        }

        private void WriteRunProperties(Element rPr)
        {
            GetOrderedRunProperties(rPr).Write(this.nextWriter);
        }

        private bool isToggle(Element prop)
        {
            for (int i = 0; i < TOGGLE_PROPERTIES.Length; ++i)
            {
                if (TOGGLE_PROPERTIES[i].Equals(prop.Name))
                {
                    return true;
                }
            }
            return false;
        }


        // Adds a style declaration by looking for the first non automatic style among the parents
        private void AddStyleDeclaration(Element element, string styleName, string styleType)
        {
            Element style = null;
            if ("rStyle".Equals(styleType) && _cStyles.ContainsKey(styleName))
            {
                style =  _cStyles[styleName];
            }
            else if (_pStyles.ContainsKey(styleName))
            {
                style = _pStyles[styleName];
            }
            else
            {
                // to avoid crash when wrong styles applied
                return;
            }

            
            if (IsAutomaticStyle(style))
            {
                Element basedOn = (Element)style.GetChild("basedOn", NAMESPACE);
                if (basedOn != null)
                {
                    string val = basedOn.GetAttributeValue("val", NAMESPACE);
                    if (val.Length > 0 && !val.Equals(styleName))
                    {
                        AddStyleDeclaration(element, val, styleType);
                    }
                }
            }
            else
            {
                Element decl = new Element("w", styleType, NAMESPACE);
                Attribute val = new Attribute("w", "val", NAMESPACE);
                val.Value = styleName;
                decl.AddAttribute(val);
                element.AddFirstChild(decl);
            }
        }
        
        /*
         * Run changes
         */

        private bool IsRPrChange(string localName, string ns)
        {
            return NAMESPACE.Equals(ns) && "rPrChange".Equals(localName);
        }

        private bool IsInRPrChange()
        {
            return "rPrChange".Equals(this._context.Peek());
        }

        private void StartRPrChange()
        {
            this._context.Push("rPrChange");
        }

        private void EndElementInRPrChange()
        {
            this._context.Pop();
            EndElementInRunProperties();
        }

        /*
         *  Get a unique lower case name for a style in a list of lowered-case names.
         */

        private string GetUniqueLowerCaseStyleName(string key, Dictionary<string, string> styleList)
        {
            string baseName = key.ToLower();
            int num = 0;
            while (styleList.ContainsKey(key.ToLower()))
            {
                key = baseName + "_" + ++num ;
            }
            return key.ToLower();
        }

    }
}
