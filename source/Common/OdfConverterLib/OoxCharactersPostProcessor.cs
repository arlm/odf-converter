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

using System.Xml;
using System.Collections;
using System;
using System.IO;

namespace CleverAge.OdfConverter.OdfConverterLib
{

    /// <summary>
    /// An <c>XmlWriter</c> implementation for characters post processings
    public class OoxCharactersPostProcessor : AbstractPostProcessor
    {

        private const string NAMESPACE = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";
        private string[] RUN_PROPERTIES = { "ins", "del", "moveFrom", "moveTo", "rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps", "smallCaps", "strike", "dstrike", "outline", "shadow", "emboss", "imprint", "noProof", "snapToGrid", "vanish", "webHidden", "color", "spacing", "w", "kern", "position", "sz", "szCs", "highlight", "u", "effect", "bdr", "shd", "fitText", "vertAlign", "rtl", "cs", "em", "lang", "eastAsianLayout", "specVanish", "oMath", "rPrChange" };

        // series of symbol that do not use reverse direction
        private static char[] HEBREW_DIRECT_SYMBOLS = 
            { '\u05B0', '\u05B1', '\u05B2', '\u05B3', '\u05B4', '\u05B5', '\u05B6', '\u05B7', '\u05B8' };

        private static char[] HEBREW_SYMBOLS = 
            { '\u05B9', '\u05BA', '\u05BB', '\u05BC', '\u05BD', '\u05BE', '\u05BF',
			'\u05C0', '\u05C1', '\u05C2', '\u05C3',
			'\u05D0', '\u05D1', '\u05D2', '\u05D3', '\u05D4', '\u05D5', '\u05D6', '\u05D7', '\u05D8', '\u05D9', '\u05DA', '\u05DB', '\u05DC', '\u05DD', '\u05DE', '\u05DF',
			'\u05E0', '\u05E1', '\u05E2', '\u05E3', '\u05E4', '\u05E5', '\u05E6', '\u05E7', '\u05E8', '\u05E9', '\u05EA',
			'\u05F0', '\u05F1', '\u05F2', '\u05F3', '\u05F4' };

        private static char[] ARABIC_BASIC_SYMBOLS = 
            { '\u060C', '\u061B', '\u061F',
			'\u0621', '\u0622', '\u0623', '\u0624', '\u0625', '\u0626', '\u0627', '\u0628', '\u0629', '\u062A', '\u062B', '\u062C', '\u062D', '\u062E', '\u062F',
			'\u0630', '\u0631', '\u0632', '\u0633', '\u0634', '\u0635', '\u0636', '\u0637', '\u0638', '\u0639', '\u063A',
			'\u0640', '\u0641', '\u0642', '\u0643', '\u0644', '\u0645', '\u0646', '\u0647', '\u0648', '\u0649', '\u064A', '\u064B', '\u064C', '\u064D', '\u064E', '\u064F',
			'\u0650', '\u0651', '\u0652', '\u0653', '\u0654', '\u0655' };

        private static char[] ARABIC_EXTENDED_SYMBOLS = 
            { '\u0660', '\u0661', '\u0662', '\u0663', '\u0664', '\u0625', '\u0666', '\u0667', '\u0668', '\u0669', '\u066A', '\u066B', '\u066C', '\u066D', '\u066E', '\u066F',
			'\u0670', '\u0641', '\u0672', '\u0673', '\u0674', '\u0675', '\u0676', '\u0677', '\u0678', '\u0679', '\u067A', '\u067B', '\u067C', '\u067D', '\u067E', '\u067F',
			'\u0680', '\u0681', '\u0682', '\u0683', '\u0684', '\u0685', '\u0686', '\u0687', '\u0688', '\u0689', '\u068A', '\u068B', '\u068C', '\u068D', '\u068E', '\u068F',
			'\u0690', '\u0691', '\u0692', '\u0693', '\u0694', '\u0695', '\u0696', '\u0697', '\u0698', '\u0699', '\u069A', '\u069B', '\u069C', '\u069D', '\u069E', '\u069F',
			'\u06A0', '\u06A1', '\u06A2', '\u06A3', '\u06A4', '\u06A5', '\u06A6', '\u06A7', '\u06A8', '\u06A9', '\u06AA', '\u06AB', '\u06AC', '\u06AD', '\u06AE', '\u06AF',
			'\u06B0', '\u06B1', '\u06B2', '\u06B3', '\u06B4', '\u06B5', '\u06B6', '\u06B7', '\u06B8', '\u06B9', '\u06BA', '\u06BB', '\u06BC', '\u06BD', '\u06BE', '\u06BF',
			'\u06C0', '\u06C1', '\u06C2', '\u06C3', '\u06C4', '\u06C5', '\u06C6', '\u06C7', '\u06C8', '\u06C9', '\u06CA', '\u06CB', '\u06CC', '\u06CD', '\u06CE', '\u06CF',
			'\u06D0', '\u06D1', '\u06D2', '\u06D3', '\u06D4', '\u06D5', '\u06D6', '\u06D7', '\u06D8', '\u06D9', '\u06DA', '\u06DB', '\u06DC', '\u06DD', '\u06DE', '\u06DF',
			'\u06E0', '\u06E1', '\u06E2', '\u06E3', '\u06E4', '\u06E5', '\u06E6', '\u06E7', '\u06E8', '\u06E9', '\u06EA', '\u06EB', '\u06EC', '\u06ED',
			'\u06F0', '\u06F1', '\u06F2', '\u06F3', '\u06F4', '\u06F5', '\u06F6', '\u06F7', '\u06F8', '\u06F9', '\u06FA', '\u06FB', '\u06FC', '\u06FD', '\u06FE' };

        private Stack currentNode;
        private Stack store;

        public OoxCharactersPostProcessor(XmlWriter nextWriter)
            : base(nextWriter)
        {
            this.currentNode = new Stack();
            this.store = new Stack();
        }

        public override void WriteStartElement(string prefix, string localName, string ns)
        {
            Element e = null;
            if (NAMESPACE.Equals(ns) && "r".Equals(localName))
            {
                e = new Run(prefix, localName, ns);
            }
            else
            {
                e = new Element(prefix, localName, ns);
            }

            this.currentNode.Push(e);

            if (InRun())
            {
                StartStoreElement();
            }
            else
            {
                this.nextWriter.WriteStartElement(prefix, localName, ns);
            }
        }


        public override void WriteEndElement()
        {

            if (IsRun())
            {
                WriteStoredRun();
            }
            if (InRun())
            {
                EndStoreElement();
            }
            else
            {
                this.nextWriter.WriteEndElement();
            }
            this.currentNode.Pop();
        }


        public override void WriteStartAttribute(string prefix, string localName, string ns)
        {
            this.currentNode.Push(new Attribute(prefix, localName, ns));

            if (InRun())
            {
                StartStoreAttribute();
            }
            else
            {
                this.nextWriter.WriteStartAttribute(prefix, localName, ns);
            }
        }


        public override void WriteEndAttribute()
        {
            if (InRun())
            {
                EndStoreAttribute();
            }
            else
            {
                this.nextWriter.WriteEndAttribute();
            }
            this.currentNode.Pop();
        }


        public override void WriteString(string text)
        {
            if (InRun())
            {
                StoreString(text);
            }
            else if (text.Contains("cxnSp"))
            {
               this.nextWriter.WriteString(EvalExpression(text));
            }
            // added by vipul for Shape Rotation
            //Start
            else if (text.Contains("draw-transform"))
            {
                this.nextWriter.WriteString(EvalRotationExpression(text));
            }
            else if (text.Contains("group-svgXYWidthHeight"))
            {
                this.nextWriter.WriteString(EvalGroupExpression(text));
            }
            //End 
            //Shadow calculation
            else if (text.Contains("a-outerShdw-dist") || text.Contains("a-outerShdw-dir"))
            {

                this.nextWriter.WriteString(EvalShadowExpression(text));
            }
            // This condition is to check for hyperlink relative path 
            else if (text.Contains("hyperlink-path"))
            {
                this.nextWriter.WriteString(EvalHyperlinkPath(text));
            }
            else
            {
                this.nextWriter.WriteString(text);
            }
        }


        /*
         * General methods
         * Private method to evaluate an expression with trignametric functions.
         */
        private string EvalExpression(string text)
        {
            string[] arrVal = new string[6];
            arrVal = text.Split(':');
            string attVal = "";
            if (arrVal.Length == 6)
            {
                double x1 = double.Parse(arrVal[2], System.Globalization.CultureInfo.InvariantCulture);
                double x2 = double.Parse(arrVal[3], System.Globalization.CultureInfo.InvariantCulture);
                double y1 = double.Parse(arrVal[4], System.Globalization.CultureInfo.InvariantCulture);
                double y2 = double.Parse(arrVal[5], System.Globalization.CultureInfo.InvariantCulture);

                double xCenter = (x1 + x2) * 360000 / 2;
                double yCenter = (y1 + y2) * 360000 / 2;

                double angle, x, y;
                int flipH = 0;
                int flipV = 0;

                angle = Math.Atan2((y2 - y1), (x2 - x1));

                double angleRd = angle / Math.PI * 180;

                if (angleRd < 0)
                {
                    angleRd += 360;
                }

                int sector = (int)(angleRd / 45) + 1;

                if ((sector == 1) || (sector == 8))
                {
                    angle = 0;
                }
                else if ((sector == 2) || (sector == 6))
                {
                    angle = 270;
                }
                else if ((sector == 3) || (sector == 7))
                {
                    angle = 90;
                }
                else if ((sector == 4) || (sector == 5))
                {
                    angle = 180;
                }

                if (arrVal[1] == "rot")
                {

                    attVal = (angle * 60000).ToString();
                }

                if ((sector == 2) || (sector == 7))
                {
                    flipH = 1;
                }

                if ((sector == 4) || (sector == 6) || (sector == 7) || (sector == 8))
                {
                    flipV = 1;
                }

                if (arrVal[1] == "flipH")
                {
                    attVal = flipH.ToString();
                }
                if (arrVal[1] == "flipV")
                {
                    attVal = flipV.ToString();
                }

                angleRd = angle / 180 * Math.PI;

                double cxby2 = (Math.Cos(angleRd) * (x2 - x1) + Math.Sin(angleRd) * (y2 - y1)) / 2 * 360000;
                double cyby2 = (Math.Sin(angleRd) * (x1 - x2) + Math.Cos(angleRd) * (y2 - y1)) / 2 * 360000;
                double cx = 2 * Math.Round(cxby2);
                double cy = 2 * Math.Round(cyby2);
                if (flipH == 1)
                {
                    cx = -1 * cx;
                }
                if (flipV == 1)
                {
                    cy = -1 * cy;
                }
                if (arrVal[1] == "cx")
                {
                    attVal = cx.ToString();
                }
                if (arrVal[1] == "cy")
                {
                    attVal = cy.ToString();
                }
                if (arrVal[1] == "x")
                {
                    x = Math.Round(xCenter - cx / 2);
                    attVal = x.ToString();
                }
                if (arrVal[1] == "y")
                {
                    y = Math.Round(yCenter - cy / 2);
                    attVal = y.ToString();

                }
            }
            return attVal;
        }
        // added by vipul for Shape Rotation
        //Start
        private string EvalRotationExpression(string text)
        {
            string[] arrVal = new string[7];
           
            string strReturn="";
            arrVal = text.Split(':');
            string strXY = arrVal[1];
            Double dblRadius = 0.0;
            Double dblXc = 0.0;
            Double dblYc = 0.0;
            Double dblalpha = 0.0;
            Double dblbeta = 0.0;
            Double dblgammaDegree = 0.0;
            Double dblgammaR = 0.0;
            Double dblX2 = 0.0;
            Double dblY2 = 0.0;
            Double centreX = 0.0;
            Double centreY = 0.0;
            Double dblRotation = 0.0;
           

            if (arrVal.Length == 7)
            {
                double arrValueWidth = Double.Parse(arrVal[2], System.Globalization.CultureInfo.InvariantCulture);
                double arrValueHeight = Double.Parse(arrVal[3], System.Globalization.CultureInfo.InvariantCulture);
                double arrValueX2 = Double.Parse(arrVal[4], System.Globalization.CultureInfo.InvariantCulture);
                double arrValueY2 = Double.Parse(arrVal[5], System.Globalization.CultureInfo.InvariantCulture);
                double arrValueAngle = Double.Parse(arrVal[6], System.Globalization.CultureInfo.InvariantCulture);

                if (arrVal[0].Contains("draw-transform"))
                {
                    
                    centreX = 360000.00 * arrValueWidth;
                    centreY = 360000.00 * arrValueHeight;

                    dblRadius = Math.Sqrt(centreX * centreX + centreY * centreY) / 2.0;

                    if (Math.Abs(centreY / 2) > 0)
                    {
                    dblbeta =  Math.Atan( Math.Abs(centreX/2) / Math.Abs(centreY/2) )* 180.00 / Math.PI;
                     }
                    dblalpha = -180.00 * arrValueAngle / Math.PI;

                    if (Math.Abs(dblbeta - dblalpha) > 0)
                    {
                    dblgammaDegree = (dblbeta - dblalpha) % ((int)((dblbeta - dblalpha) / Math.Abs(dblbeta - dblalpha)) * 360) + 90;
                    }
                    dblgammaR = (360.00 - dblgammaDegree) / 180.00 * Math.PI;
                    dblXc = (arrValueX2 * 360036.00) - (dblRadius * Math.Cos(dblgammaR));
                    dblYc = (arrValueY2 * 360036.00) - (dblRadius * Math.Sin(dblgammaR));

                    dblX2 = dblXc - centreX / 2.0;
                    dblY2 = dblYc - centreY / 2.0;
                    dblRotation =(int) Math.Round ( -1 * (arrValueAngle * 180.00 / Math.PI ) * 60000.00 ) ;
                  
                        }

            }
            if (strXY.Contains("X"))
            {
                strReturn=( (int) Math.Round(dblX2)).ToString();

            }
            if (strXY.Contains("Y"))
            {
                strReturn = ((int)Math.Round(dblY2)).ToString();

            }
            if (strXY.Contains("ROT"))
            {
                strReturn = dblRotation.ToString();

            }
            return strReturn;
        }
        private string EvalGroupExpression(string text)
        {
            string[] arrVal = new string[2];

            string strReturn = "";
            arrVal = text.Split('@');
            if (arrVal[1] == "" || arrVal[0] == "" || arrVal[0] == "$")
                return "0";
            string strXY = arrVal[0];

            //string[] arrLst; //  = arrVal[1].Split(':');
            //string[] arrLstCXCY;
            //string[] arrLstXY;
          
            //ArrayList arrLst =new ArrayList();
            //arrLst =(ArrayList) arrVal[1].Split(':');
           
            double maxVal = 0; // Location of largest item seen so far.
            double minVal = 0; // Location of largest item seen so far.

             if (strXY.Contains("onlyX") || strXY.Contains("onlyY"))
             {
               string[] arrLst = arrVal[1].Split(':');

                minVal = Double.Parse(arrLst[0], System.Globalization.CultureInfo.InvariantCulture);

               for (int intNextCnt = 1; intNextCnt <= arrLst.Length - 2; intNextCnt++)
               {
                   double arrValueNext = Double.Parse(arrLst[intNextCnt], System.Globalization.CultureInfo.InvariantCulture);

                   if (arrValueNext <= minVal)
                   {
                       minVal = arrValueNext;
                   }

               }
           
                strReturn =((int)Math.Round(minVal * 360000)).ToString();

            }
            //if (strXY.Contains("onlyY"))
            //{
            //    for (int intNextCnt = 1; intNextCnt <= arrLst.Length - 2; intNextCnt++)
            //    {

            //        double arrValueNext = Double.Parse(arrLst[intNextCnt], System.Globalization.CultureInfo.InvariantCulture);

            //        if (arrValueNext <= minVal)
            //        {
            //            minVal = arrValueNext;
            //        }

            //    }
            //    strReturn = ((int)Math.Round(minVal * 360000)).ToString();

            //}
            if (strXY.Contains("CX") || strXY.Contains("CY"))
            {
                string[] arrLst = arrVal[1].Split('$');
              
                if (arrLst[0] == "")
                    return "0";
                string[] arrLstCXCY = arrLst[0].Split(':');
                string[] arrLstXY = arrLst[1].Split(':');
                double arrValueNext;
                maxVal = Double.Parse(arrLstCXCY[0], System.Globalization.CultureInfo.InvariantCulture);
                minVal = Double.Parse(arrLstXY[0], System.Globalization.CultureInfo.InvariantCulture);

                for (int intNextCnt = 1; intNextCnt <= arrLstCXCY.Length - 2; intNextCnt++)
                {

                    arrValueNext = Double.Parse(arrLstCXCY[intNextCnt], System.Globalization.CultureInfo.InvariantCulture);

                    if (arrValueNext >= maxVal)
                    {
                        maxVal = arrValueNext;
                    }

                }

                for (int intNextCnt = 1; intNextCnt <= arrLstXY.Length - 2; intNextCnt++)
                {

                    arrValueNext = Double.Parse(arrLstXY[intNextCnt], System.Globalization.CultureInfo.InvariantCulture);

                    if (arrValueNext <= minVal)
                    {
                        minVal = arrValueNext;
                    }

                }
                strReturn = ((int)Math.Round(Math.Abs(maxVal - minVal) * 360000)).ToString();
            }
           
            //     if (strXY.Contains("CY"))
            //{
            //    strReturn = ((int)Math.Round(maxVal * 360000)).ToString();

            //}
            return strReturn;
        }
            
        //End 

        // added for Shadow calculation
        private string EvalShadowExpression(string text)
        {
            string[] arrVal = new string[2];
            arrVal = text.Split(':');
            Double x = 0;
            if (arrVal.Length == 3)
            {
                double arrValue1 = Double.Parse(arrVal[1], System.Globalization.CultureInfo.InvariantCulture);
                double arrValue2 = Double.Parse(arrVal[2], System.Globalization.CultureInfo.InvariantCulture);

                if (arrVal[0].Contains("a-outerShdw-dist"))
                {
                    x = Math.Sqrt(arrValue1 * arrValue1 + arrValue2 * arrValue2);
                    x = Math.Round(x * 360000);
                }
                if (arrVal[0].Contains("a-outerShdw-dir"))
                {
                    x = Math.Atan(arrValue2 / arrValue1);
                    x = x * (180.0 / Math.PI);
                    x = Math.Abs(Math.Round(x * 60000));
                    //0 - 90 degrees
                    //if (arrValue1 > 0 && arrValue2 > 0)
                    //{
                    //    x = Math.Atan(arrValue2 / arrValue1);
                    //    x = x * (180.0 / Math.PI);
                    //    x = Math.Abs(Math.Round(x * 60000));
                    //}
                    //181 - 270 degrees
                    if (arrValue1 < 0 && arrValue2 < 0)
                    {
                        x = Math.Abs(10800000 + x);
                    }
                    //271 - 359 degrees
                    if (arrValue1 > 0 && arrValue2 < 0)
                    {
                        x = Math.Abs(21600000 - x);
                    }
                    //91 - 180 degrees
                    if (arrValue1 < 0 && arrValue2 > 0)
                    {
                        x = Math.Abs(10800000 - x);
                    }
                }

            }

            return x.ToString();

        }

        //Resolve relative path to absolute path
        private string EvalHyperlinkPath(string text)
        {
            string[] arrVal = new string[1];
            arrVal = text.Split(':');
            string source = arrVal[1].ToString();
            string address=null;
           
           
            if (arrVal.Length == 2)
            {
                string returnInputFilePath = "";

                // for Commandline tool
                for (int i = 0; i < Environment.GetCommandLineArgs().Length; i++)
                {
                    if (Environment.GetCommandLineArgs()[i].ToString().ToUpper() == "/I")
                        returnInputFilePath = Path.GetDirectoryName(Environment.GetCommandLineArgs()[i + 1]);
                }

                //for addins
                if (returnInputFilePath == "")
                {
                    returnInputFilePath = Environment.CurrentDirectory;
                }

                string linkPathLocation = Path.GetFullPath(Path.Combine(returnInputFilePath, source.Remove(0, 3))).Replace("/", "//").Replace(" ","%20");
                address = "file:///" + linkPathLocation;
            }
            return address.ToString();
        }
        //end
        public void WriteStoredRun()
        {
            Element e = (Element)this.store.Peek();

            if (e is Run)
            {
                Run r = (Run)e;

                if (r.HasReversedText)
                {
                    SplitRun(r);
                }
                else
                {
                    if (this.store.Count < 2)
                    {
                        if (r.HasText)
                        {
                            if (r.GetChild("t", NAMESPACE) != null)
                                r.ReplaceFirstTextChild(this.ReplaceSoftHyphens(r.GetChild("t", NAMESPACE).GetTextChild(), r));
                        }
                        r.Write(nextWriter);
                    }
                }
            }
            else
            {
                if (this.store.Count < 2)
                {
                    e.Write(nextWriter);
                }
            }
        }

        private void StartStoreElement()
        {
            Element element = (Element)this.currentNode.Peek();

            if (this.store.Count > 0)
            {
                Element parent = (Element)this.store.Peek();
                parent.AddChild(element);
            }

            this.store.Push(element);
        }


        private void EndStoreElement()
        {
            Element e = (Element)this.store.Pop();
        }


        private void StartStoreAttribute()
        {
            Element parent = (Element)store.Peek();
            Attribute attr = (Attribute)this.currentNode.Peek();
            parent.AddAttribute(attr);
            this.store.Push(attr);
        }


        private void StoreString(string text)
        {
            Node node = (Node)this.currentNode.Peek();

            if (node is Element)
            {
                Element element = (Element)this.store.Peek();
                element.AddChild(text);
            }
            else
            {
                Attribute attr = (Attribute)store.Peek();
                attr.Value += text;
            }
        }


        private void EndStoreAttribute()
        {
            this.store.Pop();
        }


        private void SplitRun(Run r)
        {
            Run extractedRun = new Run("w", "r", NAMESPACE);
            Element rPr = r.GetChild("rPr", NAMESPACE);
            Element rPr0 = null;

            if (rPr != null)
            {
                rPr0 = rPr.Clone();
            }
            else
            {
                rPr0 = new Element("w", "rPr", NAMESPACE);
            }

            // get first substring of run of a unique type, and retrieve it from run
            TextProperties extractedText = ExtractText(r);
            if (extractedText.IsReverse)
            {
                rPr0.AddChild(new Element("w", "rtl", NAMESPACE));
                if (rPr0.GetChild("b", NAMESPACE) != null && rPr0.GetChild("b", NAMESPACE).GetAttribute("val", NAMESPACE).Value.Equals("on"))
                {
                    Element elt = new Element("w", "bCs", NAMESPACE);
                    elt.AddAttribute(new Attribute("w", "val", "on", NAMESPACE));
                    rPr0.AddChild(elt);
                }
                if (rPr0.GetChild("i", NAMESPACE) != null && rPr0.GetChild("i", NAMESPACE).GetAttribute("val", NAMESPACE).Value.Equals("on"))
                {
                    Element elt = new Element("w", "iCs", NAMESPACE);
                    elt.AddAttribute(new Attribute("w", "val", "on", NAMESPACE));
                    rPr0.AddChild(elt);
                }
                string fontSize = null;
                if (rPr0.GetChild("sz", NAMESPACE) != null)
                    fontSize = rPr0.GetChild("sz", NAMESPACE).GetAttribute("val", NAMESPACE).Value;
                if (fontSize != null)
                {
                    Element elt = new Element("w", "szCs", NAMESPACE);
                    elt.AddAttribute(new Attribute("w", "val", fontSize, NAMESPACE));
                    rPr0.AddChild(elt);
                }
                rPr0 = this.GetOrderedRunProperties(rPr0);
            }

            extractedRun.AddChild(rPr0);
            Element t = new Element("w", "t", NAMESPACE);
            t.AddAttribute(new Attribute("xml", "space", "preserve", null));
            t.AddChild(extractedText.Content);
            extractedRun.AddChild(t);

            if (this.store.Count < 2)
            {
                extractedRun.Write(nextWriter);
            }
            else
            {
                Element parent = GetParent(r, this.store);
                if (parent != null)
                {
                    parent.AddChild(extractedRun);
                }
            }

            if (r.HasReversedText)
            {
                SplitRun(r);
            }
            else
            {
                if (this.store.Count < 2)
                {
                    if (r.HasNotEmptyText)
                    {
                        r.Write(nextWriter);
                    }
                    else
                    {
                        bool hasRelevantChild = false;
                        //try to avoid empty runs
                        foreach (Element runChild in r.GetChildElements())
                        {
                            if ("t".Equals(runChild.Name) && NAMESPACE.Equals(runChild.Ns)) { }
                            else if ("rPr".Equals(runChild.Name) && NAMESPACE.Equals(runChild.Ns)) { }
                            else
                            {
                                hasRelevantChild = true;
                                break;
                            }
                        }
                        if (hasRelevantChild)
                            //do not write run, just pop it.
                            this.currentNode.Pop();
                    }
                }
            }

        }

        // Extract the first part of run text that is of one particular type
        private TextProperties ExtractText(Run r)
        {
            TextProperties extractedText = new TextProperties();
            // teake the very first string of run.
            string text = r.GetChild("t", NAMESPACE).GetTextChild();
            int startChar = -1;
            int endChar = -1;
            int startHebrew = -1;
            int startArabic = -1;
            int startExtendedArabic = -1;
            char[] charTable = null;

            // get start of special symbol substring
            if ((startHebrew = text.IndexOfAny(HEBREW_SYMBOLS)) >= 0)
            {
                startChar = startHebrew;
                charTable = HEBREW_SYMBOLS;
            }
            if ((startArabic = text.IndexOfAny(ARABIC_BASIC_SYMBOLS)) >= 0)
            {
                if (startChar >= 0)
                    startChar = System.Math.Min(startChar, startArabic);
                else startChar = startArabic;
                if (startChar.Equals(startArabic))
                    charTable = ARABIC_BASIC_SYMBOLS;
            }
            if ((startExtendedArabic = text.IndexOfAny(ARABIC_EXTENDED_SYMBOLS)) >= 0)
            {
                if (startChar >= 0)
                    startChar = System.Math.Min(startChar, startExtendedArabic);
                else startChar = startExtendedArabic;
                if (startChar.Equals(startExtendedArabic))
                    charTable = ARABIC_EXTENDED_SYMBOLS;
            }

            if (startChar.Equals(0))
            {
                // get end of special symbol substring
                endChar = this.GetLastIndexOfCharSetInString(text, startChar, charTable);
                // retrieve substring from run
                r.ReplaceFirstTextChild(text.Substring(endChar + 1, text.Length - endChar - 1));
                // return substring. Do not apply character processing to special characters.
                extractedText.Content = text.Substring(0, endChar + 1);
                extractedText.IsReverse = true;
            }
            else if (startChar > 0)
            {
                // retrieve substring from run
                r.ReplaceFirstTextChild(text.Substring(startChar, text.Length - startChar));
                // return first substring
                extractedText.Content = this.ReplaceSoftHyphens(text.Substring(0, startChar), r);
                extractedText.IsReverse = false;
            }
            else
            {
                extractedText.Content = this.ReplaceSoftHyphens(text, r);
                extractedText.IsReverse = false;
            }
            return extractedText;
        }


        // Find the last character of a certain char-set in a string.
        private int GetLastIndexOfCharSetInString(string text, int startIndex, char[] charTable)
        {
            int i = startIndex;
            while (i < text.Length && this.IsContainedInCharTable((text.Substring(i, 1)), charTable))
            {
                i++;
            }
            return i-1;
        }


        // Check if a character is contained in a char-set table
        private bool IsContainedInCharTable(string character, char[] charTable)
        {
            return character.IndexOfAny(charTable) >= 0;
        }


        private string ReplaceSoftHyphens(string text, Run r)
        {
            string substring = "";
            int i = 0;
            if ((i = text.IndexOf('\u00AD')) >= 0)
            {
                substring = this.ReplaceNonBreakingHyphens(text.Substring(0, i), r);
                r.AddChild(new Element("w", "softHyphen", NAMESPACE));
                if (i < text.Length - 1)
                {
                    Element newT = new Element("w", "t", NAMESPACE);
                    newT.AddChild(this.ReplaceSoftHyphens(text.Substring(i + 1, text.Length - i - 1), r));
                    r.AddChild(newT);
                }
            }
            else
            {
                substring = this.ReplaceNonBreakingHyphens(text, r);
            }
            return substring;
        }


        private string ReplaceNonBreakingHyphens(string text, Run r)
        {
            string substring = "";
            int i = 0;
            if ((i = text.IndexOf('\u2011')) >= 0)
            {
                substring = text.Substring(0, i);
                r.AddChild(new Element("w", "noBreakHyphen", NAMESPACE));
                if (i < text.Length - 1)
                {
                    Element newT = new Element("w", "t", NAMESPACE);
                    newT.AddChild(this.ReplaceNonBreakingHyphens(text.Substring(i + 1, text.Length - i - 1), r));
                    r.AddChild(newT);
                }
            }
            else
            {
                substring = text;
            }
            return substring;
        }


        private bool IsRun()
        {
            Node node = (Node)this.currentNode.Peek();
            if (node is Element)
            {
                Element element = (Element)node;
                if ("r".Equals(element.Name) && NAMESPACE.Equals(element.Ns))
                {
                    return true;
                }
            }
            return false;
        }


        private bool InRun()
        {
            return IsRun() || this.store.Count > 0;
        }

        private Element GetParent(Element e, Stack stack)
        {
            IEnumerator objEnum = stack.GetEnumerator();
            while (objEnum.MoveNext())
            {
                Node node = (Node)objEnum.Current;
                if (node is Element)
                {
                    Element parent = (Element)node;
                    foreach (object child in parent.Children)
                    {
                        if (child == e) // object identity
                        {
                            return parent;
                        }
                    }
                }
            }
            return null;
        }

        protected class Run : Element
        {
            private TextProperties TextProperties;

            public TextProperties TextPr
            {
                get { return TextProperties; }
                set { TextProperties = value; }
            }

            public Run(Element e)
                :
                base(e.Prefix, e.Name, e.Ns) { }

            public Run(string prefix, string localName, string ns)
                :
                base(prefix, localName, ns) { }

            public bool HasReversedText
            {
                get
                {
                    return HasReversedTextNode(this);
                }
            }

            private bool HasReversedTextNode(Element e)
            {
                bool b = false;
                foreach (object node in e.Children)
                {
                    if (node is Element)
                    {
                        Element element = (Element)node;
                        if (element.GetTextChild() != null)
                        {
                            b = b || isReversed(element.GetTextChild());
                        }
                    }
                }
                return b;
            }

            private bool isReversed(string text)
            {
                if (text.IndexOfAny(HEBREW_SYMBOLS) >= 0)
                    return true;
                else if (text.IndexOfAny(ARABIC_BASIC_SYMBOLS) >= 0)
                    return true;
                else if (text.IndexOfAny(ARABIC_EXTENDED_SYMBOLS) >= 0)
                    return true;
                else return false;
            }

            public void ReplaceFirstTextChild(string newText)
            {
                if (this.GetChild("t", NAMESPACE) != null)
                {
                    string oldText = this.GetChild("t", NAMESPACE).GetTextChild();
                    if (!oldText.Equals(newText))
                    {
                        this.GetChild("t", NAMESPACE).Replace(oldText, newText);
                    }
                }
            }

            public bool HasNotEmptyText
            {
                get
                {
                    return HasNotEmptyTextNode(this);
                }
            }


            private static bool HasNotEmptyTextNode(Element e)
            {
                bool b = false;
                foreach (object node in e.Children)
                {
                    if (node is Element)
                    {
                        Element element = (Element)node;
                        if (element.GetTextChild() != null && element.GetTextChild().Length > 0)
                        {
                            b = true;
                        }
                    }
                }
                return b;
            }

            public bool HasText
            {
                get
                {
                    return HasTextNode(this);
                }
            }


            private static bool HasTextNode(Element e)
            {
                bool b = false;
                if ("t".Equals(e.Name) && NAMESPACE.Equals(e.Ns))
                {
                    b = true;
                }
                else
                {

                    foreach (object node in e.Children)
                    {
                        if (node is Element)
                        {
                            b = b || HasTextNode((Element)node);
                        }
                        else
                        {
                            b = true;
                        }
                    }
                }
                return b;
            }

        }

        protected class TextProperties
        {
            private bool isReverse;
            private string content;

            public bool IsReverse
            {
                get { return isReverse; }
                set { isReverse = value; }
            }

            public string Content
            {
                get { return content; }
                set { content = value; }
            }
        }

        private Element GetOrderedRunProperties(Element rPr)
        {
            Element newRPr = new Element(rPr);
            foreach (string propName in RUN_PROPERTIES)
            {
                Element prop = rPr.GetChild(propName, NAMESPACE);
                if (prop != null)
                {
                    newRPr.AddChild(prop);
                }
            }
            return newRPr;
        }


    }
}