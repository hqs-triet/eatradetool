#include <ChartObjects\ChartObjectsLines.mqh>
#include <ChartObjects\ChartObjectsTxtControls.mqh>

class CLineH: public CObject
{
    private:
        bool m_isInit;
        string m_lineId, m_lineTitleId, m_lineTitle;
        double m_price;
        datetime m_time;
        color m_color;
        CChartObjectHLine *m_lineObject;
        CChartObjectText *m_lineTextObject;
        int CONST_MARGIN;
    protected:
        
        void DrawLineH(double price, CChartObjectHLine *&line, string id, color clr)
        {
            if(ObjectFind(0, id) >= 0)
                return;
            line = new CChartObjectHLine();
            line.Create(0, id, 0, price);
        
            line.Color(clr);
            line.Width(2);
            
            line.Selectable(true);
            line.Selected(true);
            line.Background(true);
            line.Z_Order(0);
            line.Timeframes(OBJ_ALL_PERIODS);
            ChartRedraw();
        }
        void DrawText(datetime time, double price, CChartObjectText *&text, string id, string title, color clr = clrYellow)
        {
            if(ObjectFind(0, id) >= 0)
                return;
                
            text = new CChartObjectText();
            text.Create(0, id, 0, time, price);
            
            text.Selectable(false);
            text.Selected(true);
            text.Color(clr);
            text.SetString(OBJPROP_TEXT, title);
            text.Background(true);
            text.Z_Order(0);
            text.Timeframes(OBJ_ALL_PERIODS);
            ChartRedraw();
        }
    public:
        CLineH()
        {
            CONST_MARGIN = 120;
        }
        string Id()
        {
            return m_lineId;
        }
        
        bool Init(string id, string title, double price, datetime time, color clr = clrYellow)
        {
            m_lineId = id;
            m_lineTitleId = id + "_title";
            m_lineTitle = title;
            m_price = price;
            m_color = clr;
            if(ObjectFind(0, id) >= 0)
                return false;
            
            DrawLineH(m_price, m_lineObject, m_lineId, m_color);
            int x,y;
            ChartTimePriceToXY(0, 0, m_time, m_price, x, y);
            datetime textTime;
            double textPrice;
            int subWin;
            ChartXYToTimePrice(0, ChartGetInteger(0, CHART_WIDTH_IN_PIXELS)-CONST_MARGIN, y, subWin, textTime, textPrice);
            DrawText(textTime, textPrice, m_lineTextObject, m_lineTitleId, m_lineTitle + "(" + textPrice + ")", clr);
            
            m_isInit = true;
            return true;
        }
        void Probe(string id)
        {
            if(ObjectFind(0, id) >= 0)
            {
                m_lineId = id;
                m_lineTitleId = id + "_title";
                //m_price = ObjectGetDouble(0, m_lineId,OBJPROP_PRICE);
                //int x,y, subWin;
                //y = ObjectGetInteger(0, m_lineId, OBJPROP_YSIZE);
                //x = ObjectGetInteger(0, m_lineId, OBJPROP_XSIZE);
                //ChartXYToTimePrice(0, x, y, subWin, m_time, m_price);
            }
        }
        void Remove()
        {
            if(m_lineObject != NULL)
                m_lineObject.Delete();
            if(ObjectFind(0, m_lineId) >= 0)
                ObjectDelete(0, m_lineId);
                
            if(m_lineTextObject != NULL)
                m_lineTextObject.Delete();
            if(ObjectFind(0, m_lineTitleId) >= 0)
                ObjectDelete(0, m_lineTitleId);
                
        }
        double Price()
        {
            if(ObjectFind(0, m_lineId) >= 0)
            {
                m_price = ObjectGetDouble(0, m_lineId, OBJPROP_PRICE);
            }
            return m_price;
        }
        bool ExistObject()
        {
            return (ObjectFind(0, m_lineId) >= 0);
        }
        bool ProcessEvent(const int id,         // event id:
                                                 // if id-CHARTEVENT_CUSTOM=0-"initialization" event
                            const long&   lparam, // chart period
                            const double& dparam, // price
                            const string& sparam  // symbol)
                          )
        {
            if(!m_isInit)
            {
                //Print("Object is not initialized!");
                return false;
            }
            
            datetime time;
            double price;
            int subwindow;
            if(ObjectFind(0, m_lineTitleId) >= 0)
            {
                // Update back value
                m_price = ObjectGetDouble(0, m_lineId, OBJPROP_PRICE);
                
                if(ObjectFind(0, m_lineId) >= 0)
                {
                    ChartXYToTimePrice(0, ChartGetInteger(0, CHART_WIDTH_IN_PIXELS)-CONST_MARGIN,dparam,subwindow,time,price);
                    ObjectMove(0, m_lineTitleId, 0, time, m_price);
                    ObjectSetString(0, m_lineTitleId, OBJPROP_TEXT, m_lineTitle + "(" 
                                    + DoubleToString(m_price, SymbolInfoInteger(NULL, SYMBOL_DIGITS)) + ")");
                    
                    ChartRedraw();
                }
                else
                {
                    ObjectDelete(0, m_lineTitleId);
                    ChartRedraw();
                }
            }
            
            return true;
        }
};